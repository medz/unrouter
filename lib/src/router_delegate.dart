import 'dart:async';

import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter/widgets.dart' as flutter show Router;
import 'package:unstory/unstory.dart';

import 'inlet.dart';
import 'outlet.dart';
import 'route_params.dart';
import 'route_scope.dart';
import 'router.dart';
import 'url_search_params.dart';

/// Builds a Flutter [RouterConfig] from an [Unrouter] instance.
///
/// The returned config wires route parsing, route restoration, platform back
/// handling, and route information reporting to the underlying history.
///
/// This is the recommended integration entry point for `MaterialApp.router`
/// and `CupertinoApp.router`.
///
/// Example:
/// ```dart
/// final router = createRouter(routes: routes, guards: []);
/// final routerConfig = createRouterConfig(router);
///
/// MaterialApp.router(
///   routeInformationParser: routerConfig.routeInformationParser,
///   routerDelegate: routerConfig.routerDelegate,
///   routeInformationProvider: routerConfig.routeInformationProvider,
/// );
/// ```
///
/// See also:
///
///  * `createRouter`, which creates the [Unrouter] instance.
///  * `useRouter`, which reads the configured router from a [BuildContext].
RouterConfig<HistoryLocation> createRouterConfig(Unrouter router) {
  final location = router.history.location;
  final info = RouteInformation(uri: location.uri, state: location.state);

  return RouterConfig(
    routerDelegate: _RouterDelegate(router),
    routeInformationParser: const _RouteInformationParser(),
    routeInformationProvider: _HistoryRouteInformationProvider(
      router: router,
      initialRouteInformation: info,
    ),
    backButtonDispatcher: _BackButtonDispatcher(),
  );
}

/// Returns the nearest [Unrouter] instance from a Flutter [BuildContext].
///
/// Throws a [FlutterError] when the active `RouterDelegate` is not backed by
/// Unrouter.
///
/// This method is intended for widgets that need imperative navigation, such
/// as custom buttons or gestures.
///
/// Example:
/// ```dart
/// final router = useRouter(context);
/// await router.push('/settings');
/// ```
Unrouter useRouter(BuildContext context) {
  final flutter.Router(:routerDelegate) = .of(context);
  if (routerDelegate case _RouterDelegate(:final router)) {
    return router;
  }

  throw FlutterError('Router is not an instance of Unrouter');
}

class _BackButtonDispatcher extends RootBackButtonDispatcher {
  Future<bool>? _inFlightPop;

  @override
  Future<bool> didPopRoute() {
    if (_inFlightPop case final inFlight?) {
      return inFlight;
    }

    final task = invokeCallback(Future<bool>.value(false));
    _inFlightPop = task.whenComplete(() {
      _inFlightPop = null;
    });
    return _inFlightPop!;
  }
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

  @override
  RouteInformation? restoreRouteInformation(HistoryLocation configuration) {
    return RouteInformation(uri: configuration.uri, state: configuration.state);
  }
}

final class _HistoryRouteInformationProvider extends RouteInformationProvider
    with WidgetsBindingObserver, ChangeNotifier {
  _HistoryRouteInformationProvider({
    required this.router,
    required RouteInformation initialRouteInformation,
  }) : _value = initialRouteInformation {
    _routerListenable?.addListener(_didLocationChange);
  }

  final Unrouter router;
  RouteInformation _value;
  late final Listenable? _routerListenable = router is Listenable
      ? router as Listenable
      : null;

  @override
  RouteInformation get value {
    final location = router.history.location;
    final latest = RouteInformation(uri: location.uri, state: location.state);
    if (!_isSameRouteInformation(_value, latest)) {
      _value = latest;
    }
    return _value;
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _value = routeInformation;
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (_isSameRouteInformation(_value, routeInformation)) {
      return true;
    }

    _value = routeInformation;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> didPushRoute(String route) async {
    return didPushRouteInformation(RouteInformation(uri: Uri.parse(route)));
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      WidgetsBinding.instance.addObserver(this);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void dispose() {
    _routerListenable?.removeListener(_didLocationChange);
    if (hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  bool _isSameRouteInformation(RouteInformation a, RouteInformation b) {
    return a.uri == b.uri && a.state == b.state;
  }

  void _didLocationChange() {
    final location = router.history.location;
    final latest = RouteInformation(uri: location.uri, state: location.state);
    if (_isSameRouteInformation(_value, latest)) return;

    _value = latest;
    notifyListeners();
  }
}

class _RouterDelegate extends RouterDelegate<HistoryLocation>
    with ChangeNotifier {
  _RouterDelegate(this.router) : currentLocation = router.history.location {
    if (routerListenable case final listenable?) {
      listenable.addListener(_didLocationChange);
    } else {
      removeHistoryListener = router.history.listen(
        (_) => _didLocationChange(),
      );
    }
  }

  final Unrouter router;
  late final Listenable? routerListenable = router is Listenable
      ? router as Listenable
      : null;
  void Function()? removeHistoryListener;
  HistoryLocation currentLocation;
  HistoryLocation? fromLocation;

  @override
  HistoryLocation get currentConfiguration => router.history.location;

  @override
  Widget build(BuildContext context) {
    final location = router.history.location;
    final match = router.matcher.match(location.path);
    if (match == null) {
      throw FlutterError('No route matched path "${location.path}".');
    }

    final route = match.data;
    final views = route.views;
    final iterator = views.iterator;
    if (!iterator.moveNext()) {
      throw FlutterError('No views found for matched path "${location.path}".');
    }
    final firstView = iterator.current;

    return RouteScopeProvider(
      route: route,
      params: RouteParams(match.params ?? const <String, String>{}),
      location: location,
      query: URLSearchParams(location.query),
      fromLocation: fromLocation,
      child: OutletScope(
        views: views,
        depth: 1,
        child: _ViewHost(builder: firstView),
      ),
    );
  }

  @override
  Future<bool> popRoute() async {
    return router.pop();
  }

  @override
  Future<void> setNewRoutePath(HistoryLocation configuration) async {
    final current = router.history.location;
    if (current.uri == configuration.uri &&
        current.state == configuration.state) {
      return;
    }

    await router.replace(
      configuration.uri.toString(),
      state: configuration.state,
    );
  }

  @override
  void dispose() {
    routerListenable?.removeListener(_didLocationChange);
    removeHistoryListener?.call();
    super.dispose();
  }

  void _didLocationChange() {
    final current = router.history.location;
    if (currentLocation.uri == current.uri &&
        currentLocation.state == current.state) {
      return;
    }

    fromLocation = currentLocation;
    currentLocation = current;
    notifyListeners();
  }
}

class _ViewHost extends StatefulWidget {
  const _ViewHost({required this.builder});

  final ViewBuilder builder;

  @override
  State<_ViewHost> createState() => _ViewHostState();
}

class _ViewHostState extends State<_ViewHost> {
  late Widget child = widget.builder.call();

  @override
  void didUpdateWidget(covariant _ViewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) {
      child = widget.builder.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
