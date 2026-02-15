import 'package:flutter/widgets.dart';

import 'guard.dart';

/// Builds a widget for a matched route view.
///
/// The builder is expected to be side-effect free and to return the root widget
/// for one segment in a nested view chain.
typedef ViewBuilder = ValueGetter<Widget>;

/// Declares a route node in the route tree.
///
/// Each inlet contributes one [path] segment and one [view]. Parent and child
/// nodes compose into a full matched route chain.
class Inlet {
  /// Creates a route declaration.
  ///
  /// Use [name] when this route should be addressable by route-name navigation.
  /// Use [meta] to attach static metadata that is merged from parent to child.
  const Inlet({
    required this.view,
    this.name,
    this.meta,
    this.path = '/',
    this.children = const [],
    this.guards = const [],
  });

  /// Route-name alias used by navigation APIs.
  ///
  /// When set, this route can be targeted by route-name `push`/`replace`
  /// instead of an absolute path.
  final String? name;

  /// Route segment pattern for this node.
  ///
  /// The final path is composed from parent segments and this segment.
  final String path;

  /// Route metadata merged from parent to child.
  final Map<String, Object?>? meta;

  /// View builder rendered when this route segment matches.
  final ViewBuilder view;

  /// Child routes nested under this route segment.
  final Iterable<Inlet> children;

  /// Guards evaluated after global guards for this route.
  final Iterable<Guard> guards;
}
