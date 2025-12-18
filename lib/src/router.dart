import 'package:flutter/widgets.dart';

import '_internal/route_information_parser.dart';
import '_internal/route_information_provider.dart';
import 'history/history.dart';
import 'inlet.dart';
import 'router_delegate.dart';
import 'url_strategy.dart';

import '_internal/create_history.memory.dart'
    if (dart.library.js_interop) '_internal/create_history.browser.dart';

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
      UnrouterInformationProvider(history);

  @override
  late final UnrouterDelegate routerDelegate = UnrouterDelegate(
    routes: routes,
    history: history,
  );

  @override
  RouteInformationParser<RouteInformation> get routeInformationParser =>
      const UnrouterInformationParser();

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
