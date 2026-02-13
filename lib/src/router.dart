import 'package:ht/ht.dart';
import 'package:unstory/unstory.dart';
import 'package:roux/roux.dart' as roux;

import 'inlet.dart';
import 'middleware.dart';
import 'utils.dart';

abstract interface class Router {
  String get base;
  History get history;
  roux.Router get aliases;
  roux.Router get views;
  roux.Router get middleware;

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
  Map<String, Iterable<ViewBuilder>> makeViewRoutes() {
    final routes = <String, Iterable<ViewBuilder>>{};

    void collect(
      Inlet route,
      String parentPath,
      Iterable<ViewBuilder> parentViews,
    ) {
      final fullPath = normalizePath([parentPath, route.path]);
      final views = <ViewBuilder>[...parentViews, route.view];

      final previous = routes[fullPath];
      if (previous != null && !_isSameOrNonStrictPrefix(previous, views)) {
        throw StateError('Duplicate view route "$fullPath".');
      }
      routes[fullPath] = views;

      for (final child in route.children) {
        collect(child, fullPath, views);
      }
    }

    collect(this, '/', const []);
    return routes;
  }

  Map<String, String> makeAliasRoutes() {
    final routes = <String, String>{};
    void collect(Inlet route, String parentPath) {
      final fullPath = normalizePath([parentPath, route.path]);
      final name = route.name;
      if (name case final alias? when alias.isNotEmpty) {
        final key = normalizePath([alias]);
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
    final routes = <String, Iterable<Middleware>>{};

    void collect(
      Inlet route,
      String parentPath,
      Iterable<Middleware>? parentMiddleware,
    ) {
      final fullPath = normalizePath([parentPath, route.path]);
      final middlewareChain = <Middleware>[
        ...?parentMiddleware,
        ...route.middleware,
      ];

      final previous = routes[fullPath];
      if (previous != null &&
          !_isSameOrNonStrictPrefix(previous, middlewareChain)) {
        throw StateError('Duplicate middleware route "$fullPath".');
      }
      routes[fullPath] = middlewareChain;

      for (final child in route.children) {
        collect(child, fullPath, middlewareChain);
      }
    }

    collect(this, '/', global);
    return routes;
  }

  bool _isSameOrNonStrictPrefix<T>(Iterable<T> parent, Iterable<T> child) {
    if (child.length < parent.length) {
      return false;
    }

    for (var i = 0; i < parent.length; i++) {
      if (parent.elementAtOrNull(i) != child.elementAtOrNull(i)) {
        return false;
      }
    }
    return true;
  }
}
