import 'guard.dart';

/// Builds one platform-specific view for a matched route segment.
typedef ViewBuilder<V> = V Function();

/// Platform-agnostic route declaration.
///
/// Each node contributes one path segment, one view builder, optional children,
/// guards, and metadata.
class RouteNode<V> {
  /// Creates a route declaration.
  const RouteNode({
    required this.view,
    this.name,
    this.meta,
    this.path = '/',
    this.children = const [],
    this.guards = const [],
  });

  /// Route-name alias used by navigation APIs.
  final String? name;

  /// Route segment pattern for this node.
  final String path;

  /// Route metadata merged from parent to child.
  final Map<String, Object?>? meta;

  /// View builder rendered when this route segment matches.
  final ViewBuilder<V> view;

  /// Child routes nested under this route segment.
  final Iterable<RouteNode<V>> children;

  /// Guards evaluated after global guards for this route.
  final Iterable<Guard> guards;
}
