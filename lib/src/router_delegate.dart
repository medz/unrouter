import 'package:flutter/widgets.dart';

import 'history/history.dart';
import 'inlet.dart';
import 'router_state.dart';
import 'route_matcher.dart';
import '_internal/stacked_route_view.dart';

/// The router delegate that manages navigation state and builds the widget tree.
class UnrouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
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

  void requestNavigation(Uri uri, {Object? state, bool replace = false}) {
    currentConfiguration = RouteInformation(uri: resolveUri(uri), state: state);
    _historyAction = replace ? HistoryAction.replace : HistoryAction.push;
    if (!replace) _historyIndex++;

    _updateMatchedRoutes();
    notifyListeners();
  }

  /// Resolves a URI, handling relative paths.
  ///
  /// If [uri.path] starts with '/', it's treated as an absolute path.
  /// Otherwise, it's a relative path appended to the current location.
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
}
