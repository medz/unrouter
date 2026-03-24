import 'package:nocterm/nocterm.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter_core/unrouter_core.dart'
    show RouteParams, RouteRecord, URLSearchParams;

import 'router.dart';

/// Returns the active [Unrouter] instance from the nearest route scope.
Unrouter useRouter(BuildContext context) {
  final scope = context
      .dependOnInheritedComponentOfExactType<RouteScopeProvider>();
  if (scope != null) return scope.router;

  throw StateError('Unrouter router is unavailable in this context.');
}

/// Returns merged route metadata from the nearest route scope.
Map<String, Object?> useRouteMeta(BuildContext context) {
  final route = RouteScopeProvider.of(context).route;
  return route.meta;
}

/// Returns matched route params from the nearest route scope.
RouteParams useRouteParams(BuildContext context) {
  return RouteScopeProvider.of(context).params;
}

/// Returns the current location from the nearest route scope.
HistoryLocation useLocation(BuildContext context) {
  return RouteScopeProvider.of(context).location;
}

/// Returns typed navigation state from the nearest route scope.
T? useRouteState<T>(BuildContext context) {
  final location = RouteScopeProvider.of(context).location;
  return switch (location.state) {
    T state => state,
    null => null,
    final other => throw StateError(
      'Unrouter state is of unexpected type: '
      'expected $T but got ${other.runtimeType}.',
    ),
  };
}

/// Returns the current URI from the nearest route scope.
Uri useRouteURI(BuildContext context) {
  return RouteScopeProvider.of(context).location.uri;
}

/// Returns query params from the nearest route scope.
URLSearchParams useQuery(BuildContext context) {
  return RouteScopeProvider.of(context).query;
}

/// Returns the previous accepted location, if any.
HistoryLocation? useFromLocation(BuildContext context) {
  return RouteScopeProvider.of(context).fromLocation;
}

/// Inherited route scope used by route hooks and [Outlet].
class RouteScopeProvider extends InheritedComponent {
  /// Creates a route scope provider.
  const RouteScopeProvider({
    super.key,
    required super.child,
    required this.router,
    required this.route,
    required this.params,
    required this.location,
    required this.query,
    this.fromLocation,
  });

  /// Active router instance for the current routed subtree.
  final Unrouter router;

  /// Compiled route record for the current path.
  final RouteRecord<Component> route;

  /// Matched params for the current route.
  final RouteParams params;

  /// Query params for the current route.
  final URLSearchParams query;

  /// Current location.
  final HistoryLocation location;

  /// Previous accepted location.
  final HistoryLocation? fromLocation;

  /// Looks up the nearest [RouteScopeProvider] from [context].
  static RouteScopeProvider of(BuildContext context) {
    final scope = context
        .dependOnInheritedComponentOfExactType<RouteScopeProvider>();
    if (scope != null) return scope;

    throw StateError('Unrouter route scope is unavailable in this context.');
  }

  @override
  bool updateShouldNotify(covariant RouteScopeProvider oldComponent) {
    return router != oldComponent.router ||
        route != oldComponent.route ||
        location.uri != oldComponent.location.uri ||
        location.state != oldComponent.location.state ||
        fromLocation != oldComponent.fromLocation ||
        params.toString() != oldComponent.params.toString() ||
        query.toString() != oldComponent.query.toString();
  }
}
