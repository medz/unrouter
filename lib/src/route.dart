import 'package:flutter/widgets.dart' show Widget;

/// Route definition.
class Route<T extends Widget> {
  const Route(this.path, this.factory, {this.name, this.children = const []});

  /// Path pattern (e.g. `/`, `about`, `:id`, `**`).
  final String path;

  /// Component factory (constructor tear-off).
  final WidgetFactory<T> factory;

  /// Nested routes (rendered by RouterView).
  final Iterable<Route> children;

  /// Optional name.
  final String? name;
}

/// Factory type for a route component (usually `.new`).
typedef WidgetFactory<T extends Widget> = T Function();

/// Match info for a single route.
class RouteMatch {
  RouteMatch(this.route, this.params);

  final Route route;
  final Map<String, String> params;

  String? get name => route.name;
}

/// Snapshot of current navigation state.
class RouteSnapshot {
  RouteSnapshot({required this.uri, required this.matches});

  final Uri uri;
  final List<RouteMatch> matches;

  RouteMatch? get current => matches.isNotEmpty ? matches.last : null;
  String get path => uri.path;
  Map<String, String> get query => uri.queryParameters;

  Map<String, String> get params {
    final map = <String, String>{};
    for (final match in matches) {
      map.addAll(match.params);
    }
    return map;
  }

  String? get name => current?.name;
}
