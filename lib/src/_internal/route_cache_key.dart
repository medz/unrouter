import '../inlet.dart';

/// Cache key for route widgets that should be reused across navigation.
///
/// This is primarily used for routes that have children (layout/nested routes),
/// so switching between their child routes does not recreate the layout widget.
class RouteCacheKey {
  const RouteCacheKey(this.route, this.params);

  final Inlet route;
  final Map<String, String> params;

  @override
  bool operator ==(Object other) {
    return other is RouteCacheKey &&
        identical(other.route, route) &&
        _mapEquals(other.params, params);
  }

  @override
  int get hashCode {
    var hash = route.hashCode;
    if (params.isEmpty) return hash;
    final keys = params.keys.toList()..sort();
    for (final key in keys) {
      hash = Object.hash(hash, key, params[key]);
    }
    return hash;
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
