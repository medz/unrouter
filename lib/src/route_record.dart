import 'guard.dart';
import 'inlet.dart';

/// Compiled route data for a matched absolute path.
///
/// Route records are produced when route declarations are flattened. They hold
/// the final view chain, guard chain, and merged metadata used at runtime.
final class RouteRecord {
  /// Creates an immutable route record.
  const RouteRecord({required this.views, required this.guards, this.meta});

  /// Ordered view builders from parent to child for the matched path.
  final Iterable<ViewBuilder> views;

  /// Flattened guard chain in runtime evaluation order.
  final Iterable<Guard> guards;

  /// Merged metadata inherited from parent to child.
  final Map<String, Object?>? meta;
}
