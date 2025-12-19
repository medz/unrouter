import 'package:flutter/widgets.dart';

import 'history/history.dart';
import 'inlet.dart';
import 'router_state.dart';
import 'route_matcher.dart';
import '_internal/stacked_route_view.dart';

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
  static Navigate of(BuildContext context) =>
      Router.of(context).routerDelegate as Navigate;
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
  UnrouterDelegate({this.routes, this.child, required this.history})
    : assert(
        routes != null || child != null,
        'Either routes or child must be provided',
      ),
      currentConfiguration = history.location {
    // Listen to history changes (only back/forward/go - popstate events)
    _unlistenHistory = history.listen((event) {
      currentConfiguration = event.location;
      _historyAction = event.action;
      _updateMatchedRoutes();
      notifyListeners();
    });

    // Initialize matched routes
    _updateMatchedRoutes();
  }

  /// Declarative routes configuration for centralized route matching.
  final List<Inlet>? routes;

  /// Widget-scoped child to render when declarative routes don't match or when no routes are provided.
  final Widget? child;

  /// The underlying history implementation.
  final History history;

  /// Currently matched routes.
  List<MatchedRoute> _matchedRoutes = const [];

  /// Unlisten callback from history.
  void Function()? _unlistenHistory;

  /// Current history action.
  HistoryAction _historyAction = HistoryAction.push;

  @override
  RouteInformation currentConfiguration;

  /// Resolves a URI, handling relative paths.
  ///
  /// If `uri.path` starts with `/`, it's treated as an absolute path.
  /// Otherwise, it's appended to the current path by segment.
  ///
  /// Notes:
  /// - This does not support `.` / `..` normalization.
  /// - The returned URI uses [uri]'s query/fragment (it does not inherit the
  ///   current location's query/fragment).
  Uri resolveUri(Uri uri) {
    // Absolute path - starts with '/'
    if (uri.path.startsWith('/')) {
      return uri;
    }

    // Relative path - append to current location
    final segments =
        currentConfiguration.uri.path
            .split('/')
            .where((s) => s.isNotEmpty)
            .toList()
          ..addAll(uri.path.split('/').where((s) => s.isNotEmpty));

    final resolvedPath = '/${segments.join('/')}';
    return Uri(
      path: resolvedPath,
      query: uri.query.isEmpty ? null : uri.query,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
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
    // If we have matched routes, render them
    if (_matchedRoutes.isNotEmpty) {
      final state = RouterState(
        location: currentConfiguration,
        matchedRoutes: _matchedRoutes,
        level: 0,
        historyIndex: history.index,
        action: _historyAction,
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
        action: _historyAction,
      );
      return RouterStateProvider(state: state, child: child!);
    }

    // No routes and no child - render empty
    return const SizedBox.shrink();
  }

  @override
  Future<bool> popRoute() async {
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
    _historyAction = replace ? HistoryAction.replace : HistoryAction.push;

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
