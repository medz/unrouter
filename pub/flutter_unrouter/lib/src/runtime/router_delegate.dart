import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

import '../core/route_records.dart' as adapter;
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
      publishPendingState: config.publishPendingState,
    );
    _scopeController = _controller.cast<RouteData>();
    _resolution = _controller.resolution;
    _stateListener = () {
      final previous = _resolution;
      final next = _controller.resolution;
      _resolution = next;
      if (_isSameVisibleResolution(previous, next)) {
        return;
      }
      if (previous.uri == next.uri) {
        _pageRevision += 1;
      }
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
    final resolution = _resolution;

    if (resolution.isPending) {
      final loadingBuilder = config.loading;
      if (loadingBuilder != null) {
        return Builder(
          builder: (innerContext) =>
              loadingBuilder(innerContext, resolution.uri),
        );
      }
      return const SizedBox.shrink();
    }

    if (resolution.hasError) {
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
    }

    if (resolution.isBlocked) {
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
    }

    if (resolution.isMatched) {
      final routeRecord = _requireRouteRecord(resolution);
      return Builder(
        builder: (innerContext) => routeRecord.build(
          innerContext,
          resolution.route!,
          resolution.loaderData,
        ),
      );
    }

    final unknown = config.unknown;
    if (unknown != null) {
      return Builder(
        builder: (innerContext) => unknown(innerContext, resolution.uri),
      );
    }
    return _DefaultUnknownRoutePage(uri: resolution.uri);
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

  bool _isSameVisibleResolution(RouteResolution<R> a, RouteResolution<R> b) {
    return a.type == b.type &&
        a.uri == b.uri &&
        a.record?.path == b.record?.path &&
        a.record?.name == b.record?.name &&
        _isSameRoute(a.route, b.route) &&
        a.loaderData == b.loaderData &&
        a.error == b.error &&
        a.stackTrace == b.stackTrace;
  }

  bool _isSameRoute(RouteData? a, RouteData? b) {
    if (identical(a, b) || a == b) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    return a.toUri() == b.toUri();
  }

  adapter.RouteRecord<R>? _asAdapterRouteRecord(RouteRecord<R>? record) {
    if (record case adapter.RouteRecord<R> adapterRecord) {
      return adapterRecord;
    }
    return null;
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
  PageRoute<void> createRoute(BuildContext context) {
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
