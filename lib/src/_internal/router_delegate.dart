import 'package:flutter/widgets.dart';

import '../history/types.dart';
import '../inlet.dart';
import '../router_state.dart';
import 'route_matcher.dart';
import 'stacked_route_view.dart';

/// The router delegate that manages navigation state and builds the widget tree.
class UnrouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  UnrouterDelegate({required this.routes});

  /// The root routes configuration.
  final List<Inlet> routes;

  /// The underlying history implementation.
  RouterHistory? _history;

  /// Current route information.
  RouteInformation _currentConfiguration = RouteInformation(
    uri: Uri.parse('/'),
  );

  /// Currently matched routes.
  List<MatchedRoute> _matchedRoutes = const [];

  /// Unlisten callback from history.
  VoidCallback? _unlistenHistory;

  /// Current history index.
  int _historyIndex = 0;

  /// Current navigation type (push or pop).
  NavigationType _navigationType = NavigationType.push;

  /// Attaches the history implementation.
  void attachHistory(RouterHistory history) {
    _history = history;

    // Listen to history changes (only back/forward/go - popstate events)
    _unlistenHistory = history.listen((to, from, info) {
      _currentConfiguration = RouteInformation(
        uri: Uri.parse(to),
        state: history.state,
      );
      _navigationType = info.type;
      // Adjust history index based on navigation delta
      _historyIndex += info.delta;
      if (_historyIndex < 0) _historyIndex = 0;
      _updateMatchedRoutes();
      notifyListeners();
    });

    // Initialize with current location
    _currentConfiguration = RouteInformation(
      uri: Uri.parse(history.location),
      state: history.state,
    );
    _updateMatchedRoutes();
  }

  /// Manually navigate to a location (for push/replace).
  ///
  /// This is called directly by Unrouter.push/replace because
  /// following browser semantics, pushState/replaceState do NOT
  /// trigger listeners. Only user navigation (popstate) does.
  void pushTo(String location, [Object? state]) {
    _currentConfiguration = RouteInformation(
      uri: Uri.parse(location),
      state: state,
    );
    _navigationType = NavigationType.push;
    _historyIndex++;
    _updateMatchedRoutes();
    notifyListeners();
  }

  /// Replace the current location (does not create a new history entry).
  void replaceTo(String location, [Object? state]) {
    _currentConfiguration = RouteInformation(
      uri: Uri.parse(location),
      state: state,
    );
    _navigationType = NavigationType.push;
    // Note: do NOT change _historyIndex for replace.
    _updateMatchedRoutes();
    notifyListeners();
  }

  /// Update matched routes based on current location.
  void _updateMatchedRoutes() {
    final location = _currentConfiguration.uri.path;
    final result = matchRoutes(routes, location);
    _matchedRoutes = result.matched ? result.matches : const [];
  }

  @override
  RouteInformation? get currentConfiguration => _currentConfiguration;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {
    _currentConfiguration = configuration;

    // Update history if needed
    final location = configuration.uri.path;
    if (_history != null && _history!.location != location) {
      _history!.push(location, configuration.state);
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
      location: _currentConfiguration.uri.path,
      matchedRoutes: _matchedRoutes,
      level: 0,
      historyIndex: _historyIndex,
      navigationType: _navigationType,
    );
    return StackedRouteView(state: state, levelOffset: 0);
  }

  @override
  Future<bool> popRoute() async {
    // Handle back button press
    if (_history != null) {
      _history!.back();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _unlistenHistory?.call();
    super.dispose();
  }
}
