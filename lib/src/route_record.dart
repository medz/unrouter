import 'guard.dart';
import 'inlet.dart';

/// Compiled data for a fully resolved route path.
final class RouteRecord {
  /// Creates an immutable route record.
  const RouteRecord({required this.views, required this.guards, this.meta});

  /// Ordered view builders from parent to child for the matched path.
  final Iterable<ViewBuilder> views;

  /// Flattened guard chain in evaluation order.
  final Iterable<Guard> guards;

  /// Merged metadata inherited from parent to child.
  final Map<String, Object?>? meta;
}
