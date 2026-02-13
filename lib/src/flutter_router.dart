import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter/widgets.dart' as flutter show Router;
import 'package:ht/ht.dart';
import 'package:unrouter/src/inlet.dart';
import 'package:unstory/unstory.dart';

import 'route_params.dart';
import 'route_scope.dart';
import 'router.dart';

RouterConfig<HistoryLocation> createRouterConfig(Router router) {
  final location = router.history.location;
  final info = RouteInformation(uri: location.uri, state: location.state);

  return RouterConfig(
    routerDelegate: _RouterDelegate(router),
    routeInformationParser: const _RouteInformationParser(),
    routeInformationProvider: PlatformRouteInformationProvider(
      initialRouteInformation: info,
    ),
    // TODO: backButtonDispatcher
  );
}

final class _RouteInformationParser
    extends RouteInformationParser<HistoryLocation> {
  const _RouteInformationParser();

  @override
  Future<HistoryLocation> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return .new(routeInformation.uri, routeInformation.state);
  }
}

class _RouterDelegate extends RouterDelegate<HistoryLocation> {
  _RouterDelegate(this.router);

  final Router router;
  final cleanups = <VoidCallback, VoidCallback>{};

  @override
  HistoryLocation get currentConfiguration => router.history.location;

  @override
  void addListener(VoidCallback listener) {
    if (cleanups.containsKey(listener)) {
      throw StateError('Listener already added');
    }
    cleanups[listener] = router.history.listen((_) => listener());
  }

  @override
  void removeListener(VoidCallback listener) {
    cleanups[listener]?.call();
  }

  @override
  Widget build(BuildContext context) {
    final result = router.matcher.match(currentConfiguration.path);
    if (result == null) {
      return const SizedBox.shrink();
    }

    return RouteScopeProvider(
      route: result.data,
      params: RouteParams(result.params ?? const {}),
      location: currentConfiguration,
      query: URLSearchParams(currentConfiguration.uri.query),
      child: makeRouterView(result.data.views),
    );
  }

  Widget makeRouterView(Iterable<ViewBuilder> views) {
    return const SizedBox.shrink();
  }

  @override
  Future<bool> popRoute() {
    // TODO: implement popRoute
    throw UnimplementedError();
  }

  @override
  Future<void> setNewRoutePath(HistoryLocation configuration) {
    // TODO: implement setNewRoutePath
    throw UnimplementedError();
  }
}

Router useRouter(BuildContext context) {
  final flutter.Router(:routerDelegate) = .of(context);
  if (routerDelegate case _RouterDelegate(:final router)) {
    return router;
  }

  throw FlutterError('Router is not an instance of Unrouter');
}
