import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

import 'route_params.dart';
import 'route_record.dart';
import 'url_search_params.dart';

/// Aspects used by [RouteScopeProvider] for selective rebuilds.
enum RouteScope {
  /// Route metadata.
  meta,

  /// Route params.
  params,

  /// Query params.
  query,

  /// URI only.
  uri,

  /// Navigation state only.
  state,

  /// Full location (`uri + state`).
  location,

  /// Previous location.
  from,
}

/// Returns merged route metadata from the nearest route scope.
Map<String, Object?> useRouteMeta(BuildContext context) {
  final route = RouteScopeProvider.of(context, RouteScope.meta).route;
  return route.meta ?? const {};
}

/// Returns matched route params from the nearest route scope.
RouteParams useRouteParams(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.params).params;
}

/// Returns the current location (`uri + state`) from the nearest route scope.
HistoryLocation useLocation(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.location).location;
}

/// Returns typed navigation state from the nearest route scope.
///
/// Throws a [FlutterError] when state is absent or not assignable to [T].
T useRouteState<T>(BuildContext context) {
  final RouteScopeProvider(:location) = .of(context, RouteScope.state);
  return switch (location.state) {
    T state => state,
    _ => throw FlutterError(
      'Unrouter state is unavailable in this BuildContext.',
    ),
  };
}

/// Returns the current URI from the nearest route scope.
Uri useRouteURI(BuildContext context) {
  final RouteScopeProvider(:location) = .of(context, RouteScope.uri);
  return location.uri;
}

/// Returns query params from the nearest route scope.
URLSearchParams useQuery(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.query).query;
}

/// Returns the previous accepted location, if any.
HistoryLocation? useFromLocation(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.from).fromLocation;
}

/// Inherited route scope used by route hooks and [Outlet].
class RouteScopeProvider extends InheritedModel<RouteScope> {
  /// Creates a route scope provider.
  const RouteScopeProvider({
    super.key,
    required super.child,
    required this.route,
    required this.params,
    required this.location,
    required this.query,
    this.fromLocation,
  });

  /// Compiled route record for the current path.
  final RouteRecord route;

  /// Matched params for the current route.
  final RouteParams params;

  /// Query params for the current route.
  final URLSearchParams query;

  /// Current location (`uri + state`).
  final HistoryLocation location;

  /// Previous accepted location.
  final HistoryLocation? fromLocation;

  /// Looks up the nearest [RouteScopeProvider] for a specific [scope] aspect.
  ///
  /// Throws a [FlutterError] when no provider exists above [context].
  static RouteScopeProvider of(BuildContext context, RouteScope scope) {
    final model = InheritedModel.inheritFrom<RouteScopeProvider>(
      context,
      aspect: scope,
    );
    if (model != null) return model;
    throw FlutterError(
      'Unrouter ${scope.name} is unavailable in this BuildContext.',
    );
  }

  @override
  bool updateShouldNotify(covariant RouteScopeProvider oldWidget) {
    return route != oldWidget.route ||
        location.uri != oldWidget.location.uri ||
        location.state != oldWidget.location.state ||
        fromLocation != oldWidget.fromLocation ||
        params != oldWidget.params ||
        query != oldWidget.query;
  }

  @override
  bool updateShouldNotifyDependent(
    covariant RouteScopeProvider oldWidget,
    Set<RouteScope> dependencies,
  ) {
    return (dependencies.contains(RouteScope.meta) &&
            !mapEquals(oldWidget.route.meta, route.meta)) ||
        (dependencies.contains(RouteScope.params) &&
            oldWidget.params != params) ||
        (dependencies.contains(RouteScope.query) &&
            oldWidget.query.toString() != query.toString()) ||
        (dependencies.contains(RouteScope.uri) &&
            oldWidget.location.uri != location.uri) ||
        (dependencies.contains(RouteScope.state) &&
            oldWidget.location.state != location.state) ||
        (dependencies.contains(RouteScope.location) &&
            (oldWidget.location.uri != location.uri ||
                oldWidget.location.state != location.state)) ||
        (dependencies.contains(RouteScope.from) &&
            oldWidget.fromLocation != fromLocation);
  }
}
