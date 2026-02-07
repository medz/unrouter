part of 'route_definition.dart';

/// A branch in a shell route tree.
class ShellBranch<R extends RouteData> {
  ShellBranch({
    required List<RouteRecord<R>> routes,
    required Uri initialLocation,
    this.name,
  }) : assert(
         routes.isNotEmpty,
         'A shell branch must define at least one route.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       initialLocation = _normalizeShellLocation(initialLocation);

  final List<RouteRecord<R>> routes;
  final Uri initialLocation;
  final String? name;
}

/// Creates a [ShellBranch].
ShellBranch<R> branch<R extends RouteData>({
  required List<RouteRecord<R>> routes,
  required Uri initialLocation,
  String? name,
}) {
  return ShellBranch<R>(
    routes: routes,
    initialLocation: initialLocation,
    name: name,
  );
}

/// Flattens branch routes into a single route list for shell-aware adapters.
List<RouteRecord<R>> shell<R extends RouteData>({
  required List<ShellBranch<R>> branches,
  String? name,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  final wrapped = <RouteRecord<R>>[];
  for (final branch in branches) {
    wrapped.addAll(branch.routes);
  }
  return wrapped;
}

Uri _normalizeShellLocation(Uri uri) {
  if (uri.path.isEmpty) {
    return uri.replace(path: '/');
  }
  if (uri.path.startsWith('/')) {
    return uri;
  }
  return uri.replace(path: '/${uri.path}');
}
