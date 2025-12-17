import 'package:flutter/widgets.dart' hide Route;

import '../history/types.dart';
import 'route_cache_key.dart';
import '../route.dart';
import '../router_state.dart';
import 'route_matcher.dart';

/// The router delegate that manages navigation state and builds the widget tree.
class UnrouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  UnrouterDelegate({required this.routes});

  /// The root routes configuration.
  final List<Route> routes;

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

  /// Root page stack.
  ///
  /// - Leaf routes are keyed by history index (so they can be stacked).
  /// - Layout/nested routes are keyed by [RouteCacheKey] (so they can be reused).
  final Map<Object, _PageEntry> _pageStack = {};

  /// Stack key order, for IndexedStack rendering.
  final List<Object> _indexOrder = [];

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

    final firstMatched = _matchedRoutes[0];
    final pageKey = firstMatched.route.children.isNotEmpty
        ? RouteCacheKey(firstMatched.route, firstMatched.params)
        : _historyIndex;

    // On push/replace, remove any leaf indices that are no longer reachable.
    if (_navigationType == NavigationType.push) {
      _indexOrder.removeWhere((key) => key is int && key > _historyIndex);
    }

    // Create router state
    final state = RouterState(
      location: _currentConfiguration.uri.path,
      matchedRoutes: _matchedRoutes,
      level: 0,
      historyIndex: _historyIndex,
      navigationType: _navigationType,
    );

    // Get or create page for this key.
    _PageEntry? pageEntry = _pageStack[pageKey];
    final shouldRecreate =
        _navigationType == NavigationType.push && pageKey is int;

    if (pageEntry == null || shouldRecreate) {
      // Create new page for push/replace navigation
      final widget = RouterStateProvider(
        state: state,
        child: KeyedSubtree(
          key: UniqueKey(),
          child: firstMatched.route.factory(),
        ),
      );
      pageEntry = _PageEntry(route: firstMatched.route, widget: widget, state: state);
      _pageStack[pageKey] = pageEntry;

      if (!_indexOrder.contains(pageKey)) {
        _indexOrder.add(pageKey);
      }
    } else {
      // Update state but keep widget tree
      final existingPage = pageEntry;
      pageEntry = _PageEntry(
        route: existingPage.route,
        widget: RouterStateProvider(
          state: state,
          child: (existingPage.widget as RouterStateProvider).child,
        ),
        state: state,
      );
      _pageStack[pageKey] = pageEntry;
      if (!_indexOrder.contains(pageKey)) {
        _indexOrder.add(pageKey);
      }
    }

    // Find current index in stack
    final stackIndex = _indexOrder.indexOf(pageKey);

    // Build all pages in stack
    final children = _indexOrder.map((key) {
      return _pageStack[key]?.widget ?? const SizedBox.shrink();
    }).toList();

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use IndexedStack to preserve all pages
    return IndexedStack(
      index: stackIndex >= 0 ? stackIndex : children.length - 1,
      children: children,
    );
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

class _PageEntry {
  const _PageEntry({
    required this.route,
    required this.widget,
    required this.state,
  });

  final Route route;
  final Widget widget;
  final RouterState state;
}
