import 'package:flutter/widgets.dart' show RouteInformationParser, RouterDelegate;
import 'package:zenrouter/zenrouter.dart';

import 'location.dart';
import 'page.dart';
import 'route.dart';
import 'router_base.dart';
import '_internal/core.dart';

/// Public router facade built on top of [CoreCoordinator].
class _RouterImpl implements Router {
  _RouterImpl({required Iterable<Route> routes, String initialPath = '/'})
    : _core = CoreCoordinator(routes: routes, initialPath: initialPath) {
    _core.router = this;
  }

  final CoreCoordinator _core;

  @override
  void back() => _core.pop();

  @override
  void forward() {
    // No forward stack support.
  }

  @override
  void go(int delta) {
    if (delta < 0) {
      for (int i = 0; i < delta.abs(); i++) {
        _core.pop();
      }
    } else if (delta > 0) {
      forward();
    }
  }

  @override
  void push(RouteLocation location) =>
      _core.pushPath(_locationToUri(location).toString());

  @override
  void replace(RouteLocation location) =>
      _core.goPath(_locationToUri(location).toString());

  @override
  RouterDelegate<Uri> get delegate => _core.routerDelegate;

  @override
  RouteInformationParser<Uri> get informationParser =>
      _core.routeInformationParser;

  Coordinator<RoutePage> _asCoordinator() => _core;

  Uri _locationToUri(RouteLocation location) {
    if (location.path != null) {
      return Uri(
        path: location.path,
        queryParameters: location.query.isEmpty
            ? null
            : Map<String, String>.from(location.query),
        fragment: location.hash,
      );
    }
    if (location.name != null) {
      final path = _core.pathForName(location.name!, location.params);
      if (path == null) {
        throw StateError('No route found with name ${location.name}');
      }
      return Uri(
        path: path,
        queryParameters: location.query.isEmpty
            ? null
            : Map<String, String>.from(location.query),
        fragment: location.hash,
      );
    }
    throw StateError('RouteLocation must have either path or name');
  }
}

/// Create a router instance.
Router createRouter({
  required Iterable<Route> routes,
  String initialPath = '/',
}) => _RouterImpl(routes: routes, initialPath: initialPath);

/// Access underlying zenrouter coordinator when needed.
Coordinator<RoutePage> toZenRouterCoordinator(Router router) {
  if (router is _RouterImpl) return router._asCoordinator();
  throw StateError('Unknown router implementation');
}
