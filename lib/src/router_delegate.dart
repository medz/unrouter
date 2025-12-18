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
  /// [RouteInformation.state] (see [RouterState.info]).
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
/// - Matches the current path against a tree of [Inlet] routes.
/// - Provides [RouterState] to descendants via [RouterStateProvider].
class UnrouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier
    implements Navigate {
  /// Creates a delegate with a fixed route tree and a backing [History].
  ///
  /// You typically don't create this directly; use `Unrouter`, which wires it
  /// into Flutter's `Router` and sets up a matching [RouteInformationProvider].
  UnrouterDelegate({required this.routes, required this.history})
    : currentConfiguration = history.location {
    // Listen to history changes (only back/forward/go - popstate events)
    _unlistenHistory = history.listen((event) {
      currentConfiguration = event.location;
      _historyAction = event.action;
      // Adjust history index based on navigation delta
      if (event.delta != null) {
        _historyIndex += event.delta!;
        if (_historyIndex < 0) _historyIndex = 0;
      }
      _updateMatchedRoutes();
      notifyListeners();
    });

    // Initialize matched routes
    _updateMatchedRoutes();
  }

  /// The root routes configuration.
  final List<Inlet> routes;

  /// The underlying history implementation.
  final History history;

  /// Currently matched routes.
  List<MatchedRoute> _matchedRoutes = const [];

  /// Unlisten callback from history.
  void Function()? _unlistenHistory;

  /// Current history index.
  int _historyIndex = 0;

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
    final location = currentConfiguration.uri.path;
    final result = matchRoutes(routes, location);
    _matchedRoutes = result.matched ? result.matches : const [];
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
    // If no match, render empty
    if (_matchedRoutes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create router state
    final state = RouterState(
      info: currentConfiguration,
      matchedRoutes: _matchedRoutes,
      level: 0,
      historyIndex: _historyIndex,
      historyAction: _historyAction,
    );
    return StackedRouteView(state: state, levelOffset: 0);
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
    if (!replace) _historyIndex++;

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
