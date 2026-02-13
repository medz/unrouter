import 'inlet.dart';
import 'middleware.dart';

final class RouteRecord {
  const RouteRecord({required this.views, required this.middleware, this.meta});

  final Iterable<ViewBuilder> views;
  final Iterable<Middleware> middleware;
  final Map<String, Object?>? meta;
}
