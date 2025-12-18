import 'package:flutter/widgets.dart';

import 'route_matcher.dart';
import 'history/history.dart';

/// Router state that flows through the widget tree.
///
/// `unrouter` provides this state to every routed widget via [RouterStateProvider].
/// It contains the current [RouteInformation], the matched route stack, and the
/// current rendering [level] for nested routing.
class RouterState {
  const RouterState({
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
  RouterState withLevel(int newLevel) {
    return RouterState(
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
    return other is RouterState &&
        other.location.uri == location.uri &&
        other.level == level &&
        _listEquals(other.matchedRoutes, matchedRoutes);
  }

  @override
  int get hashCode => Object.hash(location, level, Object.hashAll(matchedRoutes));

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

/// Provides [RouterState] to the widget tree.
///
/// You usually don't create this widget yourself; it is inserted by `unrouter`.
///
/// ```dart
/// final state = RouterStateProvider.of(context);
/// final uri = state.location.uri;
/// final id = state.params['id'];
/// ```
class RouterStateProvider extends InheritedWidget {
  const RouterStateProvider({
    super.key,
    required this.state,
    required super.child,
  });

  /// The current router state.
  final RouterState state;

  /// Returns the nearest [RouterState] and registers this build for updates.
  ///
  /// Asserts if no provider exists in the widget tree.
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

  /// Like [of], but returns `null` when no provider exists.
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
