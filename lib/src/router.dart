import 'package:flutter/widgets.dart';

import '_internal/create_history.memory.dart'
    if (dart.library.js_interop) '_internal/create_history.browser.dart';
import 'history/history.dart';
import 'inlet.dart';
import 'router_delegate.dart';
import 'url_strategy.dart';

/// A declarative router configuration for Flutter.
///
/// `Unrouter` is a [RouterConfig] you can pass directly to
/// `MaterialApp.router(routerConfig: ...)`.
///
/// It matches the current URL against a tree of [Inlet] routes and renders the
/// matched widgets as a stacked tree. Layout and nested routes must include an
/// `Outlet` to render their matched child.
///
/// Navigation is browser-like and backed by a [History] implementation:
/// - push: [navigate] (default)
/// - replace: [navigate] with `replace: true`
/// - pop: [back], [forward], [go]
///
/// On the web, [strategy] controls whether URLs are path-based or hash-based.
/// On non-web platforms, `Unrouter` falls back to an in-memory history by
/// default.
class Unrouter extends StatelessWidget
    implements RouterConfig<RouteInformation> {
  /// Creates a router with a fixed route tree.
  ///
  /// Provide [routes] as a stable list (prefer `const`) so route widget caching
  /// can work effectively.
  ///
  /// If [history] is omitted, a default implementation is selected based on the
  /// platform and [strategy].
  Unrouter({
    super.key,
    required this.routes,
    this.strategy = .hash,
    History? history,
  }) : history = history ?? createHistory(strategy),
       backButtonDispatcher = RootBackButtonDispatcher();

  /// The root route tree.
  final List<Inlet> routes;

  /// URL strategy used on the web when creating a default [History].
  ///
  /// This is ignored when you inject a custom [history], and on non-web
  /// platforms.
  final UrlStrategy strategy;

  /// The history implementation backing this router.
  final History history;

  @override
  /// Handles system back button integration.
  final BackButtonDispatcher backButtonDispatcher;

  @override
  /// Provides route information updates based on [history].
  late final RouteInformationProvider routeInformationProvider =
      _InformationProvider(history);

  @override
  /// The delegate that performs matching and builds the routed widget tree.
  late final UnrouterDelegate routerDelegate = UnrouterDelegate(
    history: history,
    routes: routes,
  );

  @override
  RouteInformationParser<RouteInformation> get routeInformationParser =>
      const _InformationParser();

  @override
  @protected
  Widget build(BuildContext context) {
    return Router.withConfig(config: this, restorationScopeId: 'unrouter');
  }

  /// Navigates to [uri].
  ///
  /// If `uri.path` starts with `/`, navigation is absolute. Otherwise the path
  /// is treated as relative to the current location (e.g. `edit` from
  /// `/users/123` becomes `/users/123/edit`).
  ///
  /// If [replace] is `true`, the current history entry is replaced instead of
  /// pushing a new one.
  void navigate(Uri uri, {Object? state, bool replace = false}) =>
      routerDelegate(uri, state: state, replace: replace);

  /// Moves within the history stack by [delta] entries.
  void go(int delta) => history.go(delta);

  /// Equivalent to calling [go] with `-1`.
  void back() => history.back();

  /// Equivalent to calling [go] with `+1`.
  void forward() => history.forward();
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
