import 'package:ht/ht.dart';
import 'package:roux/roux.dart' as roux;
import 'package:unstory/unstory.dart';

import 'inlet.dart';
import 'middleware.dart';
import 'route_record.dart';
import 'utils.dart';

abstract interface class Router {
  History get history;
  roux.Router<String> get aliases;
  roux.Router<RouteRecord> get matcher;

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
  final router = _RouterImpl(
    history:
        history ??
        createHistory(base: normalizePath([base]), strategy: strategy),
    aliases: roux.Router<String>(),
    matcher: roux.Router<RouteRecord>(),
  );
  final globalMiddleware = middleware ?? const <Middleware>[];
  for (final route in routes) {
    router.aliases.addAll(route.makeAliasRoutes());
    router.matcher.addAll(route.makeRouteRecords(globalMiddleware));
  }

  return router;
}

extension on Inlet {
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

  Map<String, RouteRecord> makeRouteRecords([Iterable<Middleware>? global]) {
    final routes = <String, RouteRecord>{};

    void collect(
      Inlet route,
      String parent,
      Iterable<ViewBuilder>? parentViews,
      Iterable<Middleware>? parentMiddleware,
      Map<String, Object?>? parentMeta,
    ) {
      final path = normalizePath([parent, route.path]);
      final views = <ViewBuilder>[...?parentViews, route.view];
      final middleware = <Middleware>[
        ...?parentMiddleware,
        ...route.middleware,
      ];

      final previous = routes[path];
      if (previous != null) {
        if (!_isSameOrNonStrictPrefix(previous.views, views)) {
          throw StateError('Duplicate route views "$path".');
        } else if (!_isSameOrNonStrictPrefix(previous.middleware, middleware)) {
          throw StateError('Duplicate route middleware "$path".');
        }
      }

      final meta = Map<String, Object?>.unmodifiable({
        ...?parentMeta,
        ...?route.meta,
      });
      routes[path] = RouteRecord(
        views: views,
        middleware: middleware,
        meta: meta,
      );

      for (final child in route.children) {
        collect(child, path, views, middleware, meta);
      }
    }

    collect(this, '/', null, global, null);
    return routes;
  }
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

class _RouterImpl implements Router {
  const _RouterImpl({
    required this.history,
    required this.aliases,
    required this.matcher,
  });

  @override
  final History history;

  @override
  final roux.Router<String> aliases;

  @override
  final roux.Router<RouteRecord> matcher;

  @override
  void back() => history.back();

  @override
  void forward() => history.forward();

  @override
  void go(int delta) => history.go(delta, triggerListeners: true);

  @override
  Future<void> push<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  }) {
    // TODO: implement push
    throw UnimplementedError();
  }

  @override
  Future<void> replace<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  }) {
    // TODO: implement replace
    throw UnimplementedError();
  }
}
