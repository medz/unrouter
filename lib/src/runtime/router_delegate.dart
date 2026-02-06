import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

import 'navigation.dart';
import '../core/route_data.dart';
import '../core/route_definition.dart';
import '../platform/route_information_provider.dart';
import 'unrouter.dart';

class UnrouterDelegate<R extends RouteData>
    extends RouterDelegate<HistoryLocation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<HistoryLocation> {
  UnrouterDelegate(this.config)
    : _routeInformationProvider = config.routeInformationProvider {
    final initial = _routeInformationProvider.value;
    _resolution = RouteResolution.pending(initial.uri);
    _controller = UnrouterController(
      routeInformationProvider: _routeInformationProvider,
      routeGetter: () => _resolution.route,
      uriGetter: () => _resolution.uri,
      stateTimelineLimit: config.stateTimelineLimit,
      machineTimelineLimit: config.machineTimelineLimit,
      stateGetter: () => UnrouterStateSnapshot<RouteData>(
        uri: _resolution.uri,
        route: _resolution.route,
        resolution: _mapResolutionState(_resolution.type),
        routePath: _resolution.record?.path,
        routeName: _resolution.record?.name,
        error: _resolution.error,
        stackTrace: _resolution.stackTrace,
        lastAction: _routeInformationProvider.lastAction,
        lastDelta: _routeInformationProvider.lastDelta,
        historyIndex: _routeInformationProvider.historyIndex,
      ),
    );
    _controller.configureRouteMachine<RouteResolution<R>, RouteResolutionType>(
      resolver: (uri, {required bool Function() isCancelled}) async {
        final signal = _DelegateRouteExecutionSignal(isCancelled: isCancelled);
        try {
          return await config.resolve(uri, signal: signal);
        } on RouteExecutionCancelledException {
          return null;
        }
      },
      currentResolutionType: () => _resolution.type,
      currentResolutionUri: () => _resolution.uri,
      resolutionTypeOf: (resolution) => resolution.type,
      resolutionUriOf: (resolution) => resolution.uri,
      redirectUriOf: (resolution) => resolution.redirectUri,
      isRedirect: (type) => type == RouteResolutionType.redirect,
      isBlocked: (type) => type == RouteResolutionType.blocked,
      buildUnmatchedResolution: RouteResolution.unmatched,
      buildErrorResolution: (uri, error, stackTrace) =>
          RouteResolution.error(uri: uri, error: error, stackTrace: stackTrace),
      mapResolutionType: _mapResolutionState,
      onCommit: _commit,
      maxRedirectHops: config.maxRedirectHops,
      redirectLoopPolicy: config.redirectLoopPolicy,
      onRedirectDiagnostics: config.onRedirectDiagnostics,
    );
    _controller.setShellBranchResolvers(
      resolveTarget: _resolveShellBranchTarget,
      popTarget: _popShellBranchTarget,
    );

    unawaited(
      _controller.machine.dispatchTyped<Future<void>>(
        UnrouterMachineCommand.routeRequest(initial.uri, state: initial.state),
      ),
    );
  }

  final Unrouter<R> config;
  final UnrouterRouteInformationProvider _routeInformationProvider;

  late RouteResolution<R> _resolution;
  late final UnrouterController<RouteData> _controller;

  int _pageRevision = 0;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  HistoryLocation? get currentConfiguration {
    return HistoryLocation(
      _resolution.uri,
      _routeInformationProvider.value.state,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageChild = _buildPageChild(context);
    final navigatorPage = _buildNavigatorPage(pageChild);

    return Navigator(
      key: navigatorKey,
      pages: <Page<void>>[navigatorPage],
      onDidRemovePage: _onDidRemovePage,
    );
  }

  @override
  Future<bool> popRoute() async {
    if (_controller.machine.dispatchTyped<bool>(
      UnrouterMachineCommand.popBranch(),
    )) {
      return true;
    }

    return _controller.machine.dispatchTyped<bool>(
      UnrouterMachineCommand.back(),
    );
  }

  @override
  Future<void> setNewRoutePath(HistoryLocation configuration) {
    return _controller.machine.dispatchTyped<Future<void>>(
      UnrouterMachineCommand.routeRequest(
        configuration.uri,
        state: configuration.state,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPageChild(BuildContext context) {
    if (_resolution.isPending) {
      final loadingBuilder = config.loading;
      if (loadingBuilder != null) {
        return Builder(builder: loadingBuilder);
      }

      return const SizedBox.shrink();
    }

    if (_resolution.hasError) {
      if (config.onError != null) {
        return Builder(
          builder: (innerContext) => config.onError!(
            innerContext,
            _resolution.error!,
            _resolution.stackTrace ?? StackTrace.current,
          ),
        );
      }

      Error.throwWithStackTrace(
        _resolution.error!,
        _resolution.stackTrace ?? StackTrace.current,
      );
    }

    if (_resolution.isMatched) {
      return Builder(
        builder: (innerContext) => _resolution.record!.build(
          innerContext,
          _resolution.route!,
          _resolution.loaderData,
        ),
      );
    }

    final unknown = config.unknown;
    if (unknown != null) {
      return Builder(
        builder: (innerContext) => unknown(innerContext, _resolution.uri),
      );
    }

    return _DefaultUnknownRoutePage(uri: _resolution.uri);
  }

  Page<void> _buildNavigatorPage(Widget pageChild) {
    final pageKey = ValueKey<String>('${_resolution.uri}::$_pageRevision');
    final pageName = _resolution.uri.toString();
    final scopedChild = UnrouterScope(
      controller: _controller,
      child: pageChild,
    );

    if (_resolution.isMatched) {
      return _resolution.record!.createPage(
        key: pageKey,
        name: pageName,
        child: scopedChild,
      );
    }

    return _UnrouterPage(key: pageKey, name: pageName, child: scopedChild);
  }

  void _commit(RouteResolution<R> resolution) {
    _resolution = resolution;
    if (resolution.record is! ShellRouteRecordHost<R>) {
      _controller.clearHistoryStateComposer();
    }
    _pageRevision += 1;
    _controller.publishState();
    notifyListeners();
  }

  void _onDidRemovePage(Page<Object?> page) {
    if (_routeInformationProvider.canGoBack) {
      _routeInformationProvider.back();
    }
  }

  Uri? _resolveShellBranchTarget(int index, {required bool initialLocation}) {
    final activeRecord = _resolution.record;
    if (activeRecord case ShellRouteRecordHost<R> shellHost) {
      return shellHost.resolveBranchTarget(
        index,
        initialLocation: initialLocation,
      );
    }
    return null;
  }

  Uri? _popShellBranchTarget() {
    final activeRecord = _resolution.record;
    if (activeRecord case ShellRouteRecordHost<R> shellHost) {
      return shellHost.popBranch();
    }
    return null;
  }

  UnrouterResolutionState _mapResolutionState(RouteResolutionType type) {
    switch (type) {
      case RouteResolutionType.pending:
        return UnrouterResolutionState.pending;
      case RouteResolutionType.matched:
        return UnrouterResolutionState.matched;
      case RouteResolutionType.unmatched:
        return UnrouterResolutionState.unmatched;
      case RouteResolutionType.redirect:
        return UnrouterResolutionState.redirect;
      case RouteResolutionType.blocked:
        return UnrouterResolutionState.blocked;
      case RouteResolutionType.error:
        return UnrouterResolutionState.error;
    }
  }
}

class _DelegateRouteExecutionSignal implements RouteExecutionSignal {
  const _DelegateRouteExecutionSignal({required bool Function() isCancelled})
    : _isCancelled = isCancelled;

  final bool Function() _isCancelled;

  @override
  bool get isCancelled => _isCancelled();

  @override
  void throwIfCancelled() {
    if (isCancelled) {
      throw const RouteExecutionCancelledException();
    }
  }
}

class _UnrouterPage extends Page<void> {
  const _UnrouterPage({required this.child, super.key, super.name});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, _, _, child) => child,
    );
  }
}

class _DefaultUnknownRoutePage extends StatelessWidget {
  const _DefaultUnknownRoutePage({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('No route matches ${uri.path}')),
    );
  }
}
