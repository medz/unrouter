import 'package:flutter/widgets.dart';

import 'guard.dart';

/// Builds a widget for a matched route view.
typedef ViewBuilder = ValueGetter<Widget>;

/// Declares a route node in the route tree.
class Inlet {
  /// Creates a route declaration.
  const Inlet({
    /// View builder rendered when this route segment matches.
    required this.view,

    /// Optional route name alias used by navigation APIs.
    this.name,

    /// Optional route metadata merged from parent to child.
    this.meta,

    /// Route segment pattern.
    this.path = '/',

    /// Nested child routes.
    this.children = const [],

    /// Guards evaluated for this route.
    this.guards = const [],
  });

  /// Optional route name alias used by navigation APIs.
  final String? name;

  /// Route segment pattern.
  final String path;

  /// Optional route metadata merged from parent to child.
  final Map<String, Object?>? meta;

  /// View builder rendered when this route segment matches.
  final ViewBuilder view;

  /// Nested child routes.
  final Iterable<Inlet> children;

  /// Guards evaluated for this route.
  final Iterable<Guard> guards;
}
