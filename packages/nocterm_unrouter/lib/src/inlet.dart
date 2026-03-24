import 'package:nocterm/nocterm.dart';
import 'package:unrouter_core/unrouter_core.dart' as core;

/// Builds a Nocterm component for a matched route segment.
typedef ViewBuilder = Component Function();

/// Nocterm route declaration used by [createRouter].
class Inlet extends core.RouteNode<Component> {
  /// Creates a Nocterm route declaration.
  const Inlet({
    required super.view,
    super.name,
    super.meta,
    super.path = '/',
    Iterable<Inlet> children = const [],
    super.guards = const [],
  }) : super(children: children);
}
