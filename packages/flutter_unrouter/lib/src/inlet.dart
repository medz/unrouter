import 'package:flutter/widgets.dart';
import 'package:unrouter_core/unrouter_core.dart' as core;

/// Builds a widget for a matched route view.
typedef ViewBuilder = core.ViewBuilder<Widget>;

/// Flutter route declaration used by [createRouter].
class Inlet extends core.RouteNode<Widget> {
  /// Creates a Flutter route declaration.
  const Inlet({
    required super.view,
    super.name,
    super.meta,
    super.path = '/',
    Iterable<Inlet> children = const [],
    super.guards = const [],
  }) : super(children: children);
}
