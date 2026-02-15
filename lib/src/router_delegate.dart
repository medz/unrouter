import 'dart:async';

import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter/widgets.dart' as flutter show Router;
import 'package:unstory/unstory.dart';

import 'router.dart';

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
  }) : _value = initialRouteInformation;

  final Unrouter router;
  RouteInformation _value;

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
    if (hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  bool _isSameRouteInformation(RouteInformation a, RouteInformation b) {
    return a.uri == b.uri && a.state == b.state;
  }
}

class _RouterDelegate extends RouterDelegate<HistoryLocation>
    with ChangeNotifier {
  _RouterDelegate(this.router);

  final Unrouter router;
  HistoryLocation? from;

  @override
  HistoryLocation get currentConfiguration => router.history.location;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  Future<bool> popRoute() async {
    throw UnimplementedError();
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
}

Unrouter useRouter(BuildContext context) {
  final flutter.Router(:routerDelegate) = .of(context);
  if (routerDelegate case _RouterDelegate(:final router)) {
    return router;
  }

  throw FlutterError('Router is not an instance of Unrouter');
}
