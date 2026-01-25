import 'package:flutter/foundation.dart';

import 'guard.dart';

/// Metadata for file-based routing pages.
///
/// The CLI reads this metadata from page files (without executing them) from a
/// top-level `route` variable or a `@RouteMeta(...)` annotation on the page
/// widget class to populate generated [Inlet] definitions.
@immutable
class RouteMeta {
  const RouteMeta({this.name, this.guards = const []});

  /// Optional name for the generated route.
  final String? name;

  /// Guards to apply to the generated route.
  final List<Guard> guards;
}
