import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

import '../core/route_definition.dart' as adapter;
import '../platform/route_information_provider.dart';
import 'navigation.dart';
import 'unrouter.dart' as runtime;

class UnrouterDelegate<R extends RouteData>
    extends RouterDelegate<HistoryLocation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<HistoryLocation> {
  UnrouterDelegate(this.config)
    : _routeInformationProvider = config.routeInformationProvider {
    final initial = _routeInformationProvider.value;
    _controller = createUnrouterController<R>(
      router: config,
      routeInformationProvider: _routeInformationProvider,
      resolveInitialRoute: config.resolveInitialRoute,
    );
    _scopeController = _controller.cast<RouteData>();
    _resolution = _controller.resolution;
    _controller.setShellBranchResolvers(
      resolveTarget: _resolveShellBranchTarget,
      popTarget: _popShellBranchTarget,
    );
    _stateListener = () {
      _resolution = syncControllerResolution(_controller);
      _pageRevision += 1;
      notifyListeners();
    };
    _controller.stateListenable.addListener(_stateListener);

    unawaited(
      _controller.dispatchRouteRequest(initial.uri, state: initial.state),
    );
  }

  final runtime.Unrouter<R> config;
  final UnrouterRouteInformationProvider _routeInformationProvider;

  late RouteResolution<R> _resolution;
  late final UnrouterController<R> _controller;
  late final UnrouterController<RouteData> _scopeController;
  late final VoidCallback _stateListener;

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
    if (_controller.popBranch()) {
      return true;
    }

    return _controller.back();
  }

  @override
  Future<void> setNewRoutePath(HistoryLocation configuration) {
    return _controller.dispatchRouteRequest(
      configuration.uri,
      state: configuration.state,
    );
  }

  @override
  void dispose() {
    _controller.stateListenable.removeListener(_stateListener);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPageChild(BuildContext context) {
    return resolveRouteResolution<R, Widget>(
      resolution: _resolution,
      onPending: (resolution) {
        final loadingBuilder = config.loading;
        if (loadingBuilder != null) {
          return Builder(
            builder: (innerContext) =>
                loadingBuilder(innerContext, resolution.uri),
          );
        }
        return const SizedBox.shrink();
      },
      onError: (resolution) {
        if (config.onError != null) {
          return Builder(
            builder: (innerContext) => config.onError!(
              innerContext,
              resolution.error!,
              resolution.stackTrace ?? StackTrace.current,
            ),
          );
        }

        Error.throwWithStackTrace(
          resolution.error!,
          resolution.stackTrace ?? StackTrace.current,
        );
      },
      onBlocked: (resolution) {
        final blocked = config.blocked;
        if (blocked != null) {
          return Builder(
            builder: (innerContext) => blocked(innerContext, resolution.uri),
          );
        }

        final unknown = config.unknown;
        if (unknown != null) {
          return Builder(
            builder: (innerContext) => unknown(innerContext, resolution.uri),
          );
        }

        return _DefaultUnknownRoutePage(uri: resolution.uri);
      },
      onMatched: (resolution) {
        final routeRecord = _requireRouteRecord(resolution);
        return Builder(
          builder: (innerContext) => routeRecord.build(
            innerContext,
            resolution.route!,
            resolution.loaderData,
          ),
        );
      },
      onUnmatched: (resolution) {
        final unknown = config.unknown;
        if (unknown != null) {
          return Builder(
            builder: (innerContext) => unknown(innerContext, resolution.uri),
          );
        }
        return _DefaultUnknownRoutePage(uri: resolution.uri);
      },
    );
  }

  Page<void> _buildNavigatorPage(Widget pageChild) {
    final pageKey = ValueKey<String>('${_resolution.uri}::$_pageRevision');
    final pageName = _resolution.uri.toString();
    final scopedChild = UnrouterScope(
      controller: _scopeController,
      child: pageChild,
    );

    if (_resolution.isMatched) {
      final routeRecord = _requireRouteRecord(_resolution);
      return routeRecord.createPage(
        key: pageKey,
        name: pageName,
        child: scopedChild,
      );
    }

    return _UnrouterPage(key: pageKey, name: pageName, child: scopedChild);
  }

  void _onDidRemovePage(Page<Object?> page) {
    if (_routeInformationProvider.canGoBack) {
      _routeInformationProvider.back();
    }
  }

  Uri? _resolveShellBranchTarget(int index, {required bool initialLocation}) {
    final shellHost = castShellRouteRecordHost(_activeRouteRecord);
    return shellHost?.resolveBranchTarget(
      index,
      initialLocation: initialLocation,
    );
  }

  Uri? _popShellBranchTarget() {
    final shellHost = castShellRouteRecordHost(_activeRouteRecord);
    return shellHost?.popBranch();
  }

  adapter.RouteRecord<R>? _asAdapterRouteRecord(RouteRecord<R>? record) {
    return castRouteRecord<R, adapter.RouteRecord<R>>(record);
  }

  adapter.RouteRecord<R>? get _activeRouteRecord {
    return _asAdapterRouteRecord(_resolution.record);
  }

  adapter.RouteRecord<R> _requireRouteRecord(RouteResolution<R> resolution) {
    final routeRecord = _asAdapterRouteRecord(resolution.record);
    if (routeRecord != null) {
      return routeRecord;
    }
    throw StateError(
      'Matched route record is missing from flutter adapter registry.',
    );
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
