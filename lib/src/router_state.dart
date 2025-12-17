import 'package:flutter/widgets.dart';

import '_internal/route_matcher.dart';
import 'history/types.dart';

/// Router state that flows through the widget tree.
///
/// This contains the current location, matched routes, and the current level
/// for rendering nested routes.
class RouterState {
  const RouterState({
    required this.location,
    required this.matchedRoutes,
    required this.level,
    required this.historyIndex,
    this.navigationType = NavigationType.push,
  });

  /// The full current location (e.g., '/users/123/posts').
  final String location;

  /// Stack of matched routes from root to leaf.
  final List<MatchedRoute> matchedRoutes;

  /// Current rendering level (0 = root, 1 = first child, etc.).
  final int level;

  /// Current position in history stack.
  final int historyIndex;

  /// Type of navigation that led to this state (push or pop/back).
  final NavigationType navigationType;

  /// Get all params from matched routes up to current level.
  Map<String, String> get params {
    final result = <String, String>{};
    for (var i = 0; i <= level && i < matchedRoutes.length; i++) {
      result.addAll(matchedRoutes[i].params);
    }
    return result;
  }

  /// Creates a new state with updated level.
  RouterState withLevel(int newLevel) {
    return RouterState(
      location: location,
      matchedRoutes: matchedRoutes,
      level: newLevel,
      historyIndex: historyIndex,
      navigationType: navigationType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouterState &&
        other.location == location &&
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
      'RouterState(location: $location, level: $level, matched: ${matchedRoutes.length})';
}

/// Provides router state to the widget tree.
class RouterStateProvider extends InheritedWidget {
  const RouterStateProvider({
    super.key,
    required this.state,
    required super.child,
  });

  final RouterState state;

  static RouterState of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<RouterStateProvider>();
    assert(
      provider != null,
      'No RouterStateProvider found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.state;
  }

  static RouterState? maybeOf(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<RouterStateProvider>();
    return provider?.state;
  }

  @override
  bool updateShouldNotify(RouterStateProvider oldWidget) {
    return state != oldWidget.state;
  }
}
