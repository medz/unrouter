import 'package:flutter/widgets.dart';
import 'package:ht/ht.dart';
import 'package:unstory/unstory.dart';
import 'package:roux/roux.dart' as roux;

import 'inlet.dart';
import 'middleware.dart';

abstract interface class Router {
  Iterable<Inlet> get routes;
  Iterable<Middleware> get middleware;
  History get history;
  String get base;

  void go(int delta);
  void forward();
  void back();

  Future<void> push<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  });

  Future<void> replace<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  });
}

Router createRouter({
  required Iterable<Inlet> routes,
  Iterable<Middleware>? middleware,
  String base = '/',
  History? history,
  HistoryStrategy strategy = HistoryStrategy.browser,
}) {
  final aliasesMatcher = roux.Router();
  final viewsMatcher = roux.Router();
  final middlewareMatcher = roux.Router();
  for (final route in routes) {
    aliasesMatcher.addAll(route.makeAliasRoutes());
    viewsMatcher.addAll(route.makeViewRoutes());
    middlewareMatcher.addAll(route.makeMiddlewareRoutes(middleware));
  }

  history ??= createHistory(base: base, strategy: strategy);

  throw UnimplementedError();
}

extension on Inlet {
  Map<String, Iterable<ValueGetter<Widget>>> makeViewRoutes() {
    return {};
  }

  Map<String, String> makeAliasRoutes() {
    final routes = <String, String>{};
    void collect(Inlet route, String parentPath) {
      final fullPath = _normalizePath([parentPath, route.path]);
      final name = route.name;
      if (name case final alias? when alias.isNotEmpty) {
        final key = _normalizePath([alias]);
        final previous = routes[key];
        if (previous != null && previous != fullPath) {
          throw StateError('Duplicate route alias "$alias".');
        }
        routes[key] = fullPath;
      }

      for (final child in route.children) {
        collect(child, fullPath);
      }
    }

    collect(this, '/');
    return routes;
  }

  Map<String, Iterable<Middleware>> makeMiddlewareRoutes([
    Iterable<Middleware>? global,
  ]) {
    throw UnimplementedError();
  }
}

String _normalizePath(Iterable<String> paths) {
  final segments = <String>[];
  for (final path in paths) {
    if (path.isEmpty) {
      continue;
    }

    for (final segment in path.split('/')) {
      if (segment.isEmpty) {
        continue;
      }
      segments.add(segment);
    }
  }

  if (segments.isEmpty) {
    return '/';
  }
  return '/${segments.join('/')}';
}
