import 'inlet.dart';
import 'guard.dart';

final class RouteRecord {
  const RouteRecord({required this.views, required this.guards, this.meta});

  final Iterable<ViewBuilder> views;
  final Iterable<Guard> guards;
  final Map<String, Object?>? meta;
}
