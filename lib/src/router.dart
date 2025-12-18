import 'package:flutter/widgets.dart';

import '_internal/create_history.memory.dart'
    if (dart.library.js_interop) '_internal/create_history.browser.dart';
import 'history/history.dart';
import 'inlet.dart';
import 'router_delegate.dart';
import 'url_strategy.dart';

class Unrouter extends StatelessWidget
    implements RouterConfig<RouteInformation> {
  Unrouter({
    super.key,
    required this.routes,
    this.strategy = .hash,
    History? history,
  }) : history = history ?? createHistory(strategy),
       backButtonDispatcher = RootBackButtonDispatcher();

  final List<Inlet> routes;
  final UrlStrategy strategy;
  final History history;

  @override
  final BackButtonDispatcher backButtonDispatcher;

  @override
  late final RouteInformationProvider routeInformationProvider =
      _InformationProvider(history);

  @override
  late final UnrouterDelegate routerDelegate = UnrouterDelegate(
    history: history,
    routes: routes,
  );

  @override
  RouteInformationParser<RouteInformation> get routeInformationParser =>
      const _InformationParser();

  void navigate(Uri uri, {Object? state, bool replace = false}) {
    final resolvedUri = routerDelegate.resolveUri(uri);

    if (replace) {
      history.replace(resolvedUri, state);
    } else {
      history.push(resolvedUri, state);
    }

    routerDelegate.requestNavigation(uri, state: state, replace: replace);
  }

  void go(int delta) => history.go(delta);
  void back() => history.back();
  void forward() => history.forward();

  @override
  @protected
  Widget build(BuildContext context) {
    return Router.withConfig(config: this);
  }
}

class _InformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  _InformationProvider(this.history) : value = history.location {
    unlisten = history.listen((event) {
      value = event.location;
      notifyListeners();
    });
  }

  final History history;
  late final void Function() unlisten;

  @override
  RouteInformation value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final newUri = routeInformation.uri;
    final currentUri = history.location.uri;

    if (newUri != currentUri) {
      switch (type) {
        case RouteInformationReportingType.none:
        case RouteInformationReportingType.neglect:
          // Don't update history
          break;
        case RouteInformationReportingType.navigate:
          history.push(newUri, routeInformation.state);
          break;
      }
    }
  }

  @override
  void dispose() {
    unlisten();
    super.dispose();
  }
}

class _InformationParser extends RouteInformationParser<RouteInformation> {
  const _InformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation;
  }

  @override
  RouteInformation? restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}
