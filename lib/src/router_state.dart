import 'package:flutter/widgets.dart';

/// Router state that flows through the widget tree.
///
/// This contains the current location, extracted parameters,
/// and the remaining path to be matched by nested Routes.
class RouterState {
  const RouterState({
    required this.location,
    required this.params,
    required this.remainingPath,
  });

  /// The full current location (e.g., '/users/123/posts').
  final String location;

  /// Extracted path parameters (e.g., {'id': '123', 'postId': '456'}).
  final Map<String, String> params;

  /// Remaining path segments to be matched by child Routes.
  final List<String> remainingPath;

  /// Creates a new state with updated remaining path.
  RouterState withRemainingPath(
    List<String> remaining,
    Map<String, String> newParams,
  ) {
    return RouterState(
      location: location,
      params: {...params, ...newParams},
      remainingPath: remaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouterState &&
        other.location == location &&
        _mapEquals(other.params, params) &&
        _listEquals(other.remainingPath, remainingPath);
  }

  @override
  int get hashCode => Object.hash(
        location,
        Object.hashAll(params.entries.map((e) => '${e.key}:${e.value}')),
        Object.hashAll(remainingPath),
      );

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
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
    final provider =
        context.dependOnInheritedWidgetOfExactType<RouterStateProvider>();
    assert(
      provider != null,
      'No RouterStateProvider found in context. '
      'Make sure your Routes widget is a descendant of Unrouter.',
    );
    return provider!.state;
  }

  static RouterState? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<RouterStateProvider>();
    return provider?.state;
  }

  @override
  bool updateShouldNotify(RouterStateProvider oldWidget) {
    return state != oldWidget.state;
  }
}
