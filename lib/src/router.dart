import 'package:flutter/widgets.dart';

import '_internal/create_history.memory.dart'
    if (dart.library.js_interop) '_internal/create_history.browser.dart';
import '_internal/stacked_route_view.dart';
import 'history/history.dart';
import 'inlet.dart';
import 'route_matcher.dart';
import 'router_state.dart';
import 'url_strategy.dart';

/// Browser-style navigation operations exposed by `unrouter`.
///
/// `Navigate` is implemented by [UnrouterDelegate]. In a widget tree you can
/// access it via [Navigate.of].
abstract interface class Navigate {
  /// Navigates to [uri].
  ///
  /// - If `uri.path` starts with `/`, navigation is absolute.
  /// - Otherwise, the path is appended to the current location (relative
  ///   navigation).
  ///
  /// The optional [state] is stored on the history entry and can be read via
  /// [RouteInformation.state] (see [RouterState.location]).
  ///
  /// If [replace] is `true`, the current history entry is replaced instead of
  /// pushing a new one.
  void call(Uri uri, {Object? state, bool replace = false});

  /// Moves within the history stack by [delta] entries.
  void go(int delta);

  /// Equivalent to calling [go] with `-1`.
  void back();

  /// Equivalent to calling [go] with `+1`.
  void forward();

  /// Retrieves the current [Navigate] implementation from the nearest [Router].
  ///
  /// This assumes the app is using a router delegate that implements
  /// [Navigate] (such as [UnrouterDelegate]).
  ///
  /// Throws a [FlutterError] if called outside a Router scope or if the
  /// router delegate does not implement [Navigate].
  static Navigate of(BuildContext context) {
    final router = Router.maybeOf(context);
    if (router == null) {
      throw FlutterError(
        'Navigate.of() called with a context that does not contain a Router.\n'
        'No Router ancestor could be found starting from the context that was passed to Navigate.of().\n'
        'The context used was:\n'
        '  $context',
      );
    }
    final delegate = router.routerDelegate;
    if (delegate is! Navigate) {
      throw FlutterError(
        'Navigate.of() called with a Router whose delegate does not implement Navigate.\n'
        'The router delegate type is: ${delegate.runtimeType}\n'
        'Make sure you are using Unrouter or a custom router delegate that implements Navigate.\n'
        'The context used was:\n'
        '  $context',
      );
    }
    return delegate as Navigate;
  }
}

/// A declarative router configuration for Flutter.
///
/// `Unrouter` is a [RouterConfig] you can pass directly to
/// `MaterialApp.router(routerConfig: ...)`, or use as a standalone widget.
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
///
/// You can provide either [routes], [child], or both:
/// - If only [routes] is provided: declarative routing
/// - If only [child] is provided: widget-scoped routing (typically using [Routes] widget)
/// - If both are provided: hybrid routing ([routes] matched first, [child] as fallback)
class Unrouter extends StatelessWidget
    implements RouterConfig<RouteInformation> {
  /// Creates a router with optional declarative routes and/or widget-scoped child.
  ///
  /// At least one of [routes] or [child] must be provided.
  ///
  /// Provide [routes] as a stable list (prefer `const`) so route widget caching
  /// can work effectively.
  ///
  /// If [history] is omitted, a default implementation is selected based on the
  /// platform and [strategy].
  Unrouter({
    super.key,
    this.routes,
    this.child,
    this.strategy = .hash,
    this.enableNavigator1 = true,
    History? history,
  }) : assert(
         routes != null || child != null,
         'Either routes or child must be provided',
       ),
       history = history ?? createHistory(strategy),
       backButtonDispatcher = RootBackButtonDispatcher();

  /// Declarative routes for centralized route configuration.
  ///
  /// If provided, these routes are matched first. If [child] is also provided
  /// and no route matches, [child] is rendered as fallback.
  final List<Inlet>? routes;

  /// Widget-scoped child to render when declarative routes don't match or when no routes are provided.
  ///
  /// Typically contains a [Routes] widget for dynamic route matching.
  final Widget? child;

  /// URL strategy used on the web when creating a default [History].
  ///
  /// This is ignored when you inject a custom [history], and on non-web
  /// platforms.
  final UrlStrategy strategy;

  /// The history implementation backing this router.
  final History history;

  /// Enables an embedded Navigator 1.0 for APIs like `showDialog`.
  ///
  /// When set to `false`, the router renders its content directly, matching
  /// the previous (Navigator 2.0-only) behavior.
  final bool enableNavigator1;

  @override
  /// Handles system back button integration.
  final BackButtonDispatcher backButtonDispatcher;

  @override
  /// Provides route information updates based on [history].
  late final RouteInformationProvider routeInformationProvider =
      _InformationProvider(history);

  @override
  /// The delegate that performs matching and builds the routed widget tree.
  late final UnrouterDelegate routerDelegate = UnrouterDelegate(this);

  /// Provides navigation functionality.
  Navigate get navigate => routerDelegate;

  @override
  RouteInformationParser<RouteInformation> get routeInformationParser =>
      const _InformationParser();

  @override
  @protected
  Widget build(BuildContext context) {
    return Router.withConfig(config: this, restorationScopeId: 'unrouter');
  }

  static Unrouter of(BuildContext context) =>
      (Router.of(context).routerDelegate as UnrouterDelegate).router;
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

/// A [RouterDelegate] that matches URLs and builds the routed widget tree.
///
/// The delegate:
/// - Listens to [History] `pop` events and updates [currentConfiguration].
/// - Matches the current path against declarative [Inlet] routes (if provided).
/// - Provides [RouterState] to descendants via [RouterStateProvider].
/// - Renders widget-scoped [child] if declarative routes don't match or if no routes are provided.
class UnrouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier
    implements Navigate {
  /// Creates a delegate with optional declarative routes and/or a widget-scoped child.
  ///
  /// You typically don't create this directly; use `Unrouter`, which wires it
  /// into Flutter's `Router` and sets up a matching [RouteInformationProvider].
  UnrouterDelegate(this.router)
    : currentConfiguration = router.history.location {
    // Listen to history changes (only back/forward/go - popstate events)
    _unlistenHistory = history.listen((event) {
      currentConfiguration = event.location;
      _updateMatchedRoutes();
      notifyListeners();
    });

    // Initialize matched routes
    _updateMatchedRoutes();
  }

  final Unrouter router;

  /// Declarative routes configuration for centralized route matching.
  Iterable<Inlet>? get routes => router.routes;

  /// Widget-scoped child to render when declarative routes don't match or when no routes are provided.
  Widget? get child => router.child;

  /// The underlying history implementation.
  History get history => router.history;

  /// Currently matched routes.
  List<MatchedRoute> _matchedRoutes = const [];

  /// Unlisten callback from history.
  void Function()? _unlistenHistory;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  RouteInformation currentConfiguration;

  /// Resolves a URI, handling relative paths.
  ///
  /// If `uri.path` starts with `/`, it's treated as an absolute path.
  /// Otherwise, it's appended to the current path by segment.
  ///
  /// Notes:
  /// - Dot segments (`.` / `..`) are normalized and attempts to walk above
  ///   root are clamped.
  /// - The returned URI uses [uri]'s query/fragment (it does not inherit the
  ///   current location's query/fragment).
  Uri resolveUri(Uri uri) {
    final resolvedSegments = switch (uri.path.startsWith('/')) {
      false =>
        currentConfiguration.uri.path
            .split('/')
            .where((s) => s.isNotEmpty)
            .toList(),
      _ => <String>[],
    };
    for (final segment in uri.path.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..') {
        if (resolvedSegments.isNotEmpty) {
          resolvedSegments.removeLast();
        }
        continue;
      }
      resolvedSegments.add(segment);
    }

    final resolvedPath = '/${resolvedSegments.join('/')}';
    return Uri(
      path: resolvedPath,
      query: (uri.hasQuery && uri.query.isNotEmpty) ? uri.query : null,
      fragment: (uri.hasFragment && uri.fragment.isNotEmpty)
          ? uri.fragment
          : null,
    );
  }

  /// Update matched routes based on current location.
  void _updateMatchedRoutes() {
    if (routes == null) {
      // No declarative routes to match
      _matchedRoutes = const [];
      return;
    }

    final location = currentConfiguration.uri.path;
    final result = matchRoutes(routes!, location);
    // Accept both full matches and partial matches (for widget-scoped Routes support)
    _matchedRoutes = result.matches;
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {
    currentConfiguration = configuration;

    // Update history if needed
    final newUri = configuration.uri;
    final currentUri = history.location.uri;
    if (newUri != currentUri) {
      history.push(newUri, configuration.state);
    }

    _updateMatchedRoutes();
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    if (!router.enableNavigator1) {
      return _buildContent();
    }

    return Navigator(
      key: _navigatorKey,
      pages: [const _UnrouterPage(key: ValueKey<String>('unrouter-root'))],
      onDidRemovePage: (_) {
        // Root page is not expected to be removed; keep as a no-op.
      },
    );
  }

  Widget _buildContent() {
    // If we have matched routes, render them
    if (_matchedRoutes.isNotEmpty) {
      final state = RouterState(
        location: currentConfiguration,
        matchedRoutes: _matchedRoutes,
        level: 0,
        historyIndex: history.index,
        action: history.action,
      );
      return StackedRouteView(state: state, levelOffset: 0);
    }

    // If no match but we have a child, render it with router state
    if (child != null) {
      final state = RouterState(
        location: currentConfiguration,
        matchedRoutes: const [],
        level: 0,
        historyIndex: history.index,
        action: history.action,
      );
      return RouterStateProvider(state: state, child: child!);
    }

    // No routes and no child - render empty
    return const SizedBox.shrink();
  }

  @override
  Future<bool> popRoute() async {
    if (router.enableNavigator1) {
      final navigator = _navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        final popped = await navigator.maybePop();
        if (popped) {
          return true;
        }
      }
    }

    history.back();
    return true;
  }

  @override
  void dispose() {
    _unlistenHistory?.call();
    super.dispose();
  }

  @override
  void call(Uri uri, {Object? state, bool replace = false}) {
    final resolvedUri = resolveUri(uri);
    if (replace) {
      history.replace(resolvedUri, state);
    } else {
      history.push(resolvedUri, state);
    }

    currentConfiguration = RouteInformation(uri: resolveUri(uri), state: state);

    _updateMatchedRoutes();
    notifyListeners();
  }

  @override
  void back() => history.back();

  @override
  void forward() => history.forward();

  @override
  void go(int delta) => history.go(delta);
}

class _UnrouterPage extends Page {
  const _UnrouterPage({super.key}) : super(canPop: false);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _UnrouterNavigatorHost(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }
}

class _UnrouterNavigatorHost extends StatelessWidget {
  const _UnrouterNavigatorHost();

  @override
  Widget build(BuildContext context) {
    final router = Router.of(context);
    final delegate = router.routerDelegate;
    assert(
      delegate is UnrouterDelegate,
      'UnrouterNavigatorHost must be used with UnrouterDelegate.',
    );
    if (delegate is! UnrouterDelegate) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: delegate,
      builder: (context, _) => delegate._buildContent(),
    );
  }
}
