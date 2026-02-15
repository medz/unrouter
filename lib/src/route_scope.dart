import 'package:flutter/widgets.dart';
import 'package:ht/ht.dart';
import 'package:unstory/unstory.dart';

import 'route_params.dart';
import 'route_record.dart';

enum RouteScope { meta, params, query, uri, state, location, from }

class RouteScopeProvider extends InheritedModel<RouteScope> {
  const RouteScopeProvider({
    super.key,
    required super.child,
    required this.route,
    required this.params,
    required this.location,
    required this.query,
    this.fromLocation,
  });

  final RouteRecord route;
  final RouteParams params;
  final URLSearchParams query;
  final HistoryLocation location;
  final HistoryLocation? fromLocation;

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
            oldWidget.route.meta != route.meta) ||
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

  static RouteScopeProvider of(BuildContext context, RouteScope scope) {
    final model = InheritedModel.inheritFrom<RouteScopeProvider>(
      context,
      aspect: scope,
    );
    if (model != null) return model;
    throw FlutterError('Unrouter ${scope.name} not found in the context');
  }
}

Map<String, Object?> useRouteMeta(BuildContext context) {
  final route = RouteScopeProvider.of(context, RouteScope.meta).route;
  return route.meta ?? const {};
}

RouteParams useRouteParams(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.params).params;
}

HistoryLocation useLocation(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.location).location;
}

T useRouteState<T>(BuildContext context) {
  final RouteScopeProvider(:location) = .of(context, RouteScope.state);
  return switch (location.state) {
    T state => state,
    _ => throw FlutterError('Unrouter state not found in the context'),
  };
}

Uri useRouteURI(BuildContext context) {
  final RouteScopeProvider(:location) = .of(context, RouteScope.uri);
  return location.uri;
}

URLSearchParams useQuery(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.query).query;
}

HistoryLocation? useFromLocation(BuildContext context) {
  return RouteScopeProvider.of(context, RouteScope.from).fromLocation;
}
