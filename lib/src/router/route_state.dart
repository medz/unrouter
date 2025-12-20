import 'package:flutter/widgets.dart';
import 'package:unrouter/history.dart';

import 'route_matcher.dart';

/// Route state that flows through the widget tree.
///
/// It contains the current [RouteInformation], the matched route stack, and the
/// current rendering [level] for nested routing.
class RouteState {
  const RouteState({
    required this.location,
    required this.matchedRoutes,
    required this.level,
    required this.historyIndex,
    this.action = HistoryAction.push,
  });

  /// The current location (path/query/fragment) and the optional per-entry state.
  ///
  /// The state is the value passed to `navigate(..., state: ...)` /
  /// `Navigate.call(..., state: ...)`.
  final RouteInformation location;

  /// Stack of matched routes from root to leaf.
  final List<MatchedRoute> matchedRoutes;

  /// Current rendering level (0 = root, 1 = first child, ...).
  ///
  /// `Outlet` increments this as it renders nested children.
  final int level;

  /// Current position in the history stack.
  ///
  /// This is primarily used internally to keep leaf widgets stacked across
  /// navigation.
  final int historyIndex;

  /// The navigation type that produced this state.
  final HistoryAction action;

  /// Merged params from matched routes up to (and including) [level].
  ///
  /// If the same param name appears multiple times, deeper (more specific)
  /// routes win.
  Map<String, String> get params {
    final result = <String, String>{};
    for (var i = 0; i <= level && i < matchedRoutes.length; i++) {
      result.addAll(matchedRoutes[i].params);
    }
    return result;
  }

  /// Creates a new state with updated level.
  RouteState withLevel(int newLevel) {
    return RouteState(
      location: location,
      matchedRoutes: matchedRoutes,
      level: newLevel,
      historyIndex: historyIndex,
      action: action,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteState &&
        other.location.uri == location.uri &&
        other.level == level &&
        _listEquals(other.matchedRoutes, matchedRoutes);
  }

  @override
  int get hashCode =>
      Object.hash(location, level, Object.hashAll(matchedRoutes));

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'RouteState(location: $location, level: $level, matched: ${matchedRoutes.length})';
}
