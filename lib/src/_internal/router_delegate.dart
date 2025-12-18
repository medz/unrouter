import 'package:flutter/widgets.dart';

import '../history/history.dart';
import '../inlet.dart';
import '../router_state.dart';
import 'route_matcher.dart';
import 'stacked_route_view.dart';

/// The router delegate that manages navigation state and builds the widget tree.
class UnrouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  UnrouterDelegate({required this.routes, required History history})
    : _history = history,
      _currentConfiguration = history.location {
    // Listen to history changes (only back/forward/go - popstate events)
    _unlistenHistory = history.listen((event) {
      _currentConfiguration = event.location;
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
  final History _history;

  /// Current route information.
  RouteInformation _currentConfiguration;

  /// Currently matched routes.
  List<MatchedRoute> _matchedRoutes = const [];

  /// Unlisten callback from history.
  void Function()? _unlistenHistory;

  /// Current history index.
  int _historyIndex = 0;

  /// Current history action.
  HistoryAction _historyAction = HistoryAction.push;

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
    _historyAction = HistoryAction.push;
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
    _historyAction = HistoryAction.replace;
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
    final newUri = configuration.uri;
    final currentUri = _history.location.uri;
    if (newUri != currentUri) {
      _history.push(newUri, configuration.state);
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
      info: _currentConfiguration,
      matchedRoutes: _matchedRoutes,
      level: 0,
      historyIndex: _historyIndex,
      historyAction: _historyAction,
    );
    return StackedRouteView(state: state, levelOffset: 0);
  }

  @override
  Future<bool> popRoute() async {
    // Handle back button press
    _history.back();
    return true;
  }

  @override
  void dispose() {
    _unlistenHistory?.call();
    super.dispose();
  }
}
