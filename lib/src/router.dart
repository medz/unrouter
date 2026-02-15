import 'package:flutter/foundation.dart';
import 'package:ht/ht.dart';
import 'package:roux/roux.dart' as roux;
import 'package:unstory/unstory.dart';

import 'inlet.dart';
import 'middleware.dart';
import 'route_record.dart';
import 'utils.dart';

abstract interface class Router implements Listenable {
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

  void dispose();
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

class _RouterImpl extends ChangeNotifier implements Router {
  _RouterImpl({
    required this.history,
    required this.aliases,
    required this.matcher,
  }) : _lastLocation = history.location {
    _unlistenHistory = history.listen(_handleHistoryChange);
  }

  @override
  final History history;

  @override
  final roux.Router<String> aliases;

  @override
  final roux.Router<RouteRecord> matcher;

  HistoryLocation _lastLocation;
  late final VoidCallback _unlistenHistory;

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
  }) async {
    final uri = _resolveNavigationTarget(
      pathOrName,
      params: params,
      query: query,
    );
    final previous = _lastLocation;
    history.push(uri, state: state);
    _reportLocationChange(previous);
  }

  @override
  Future<void> replace<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  }) async {
    final uri = _resolveNavigationTarget(
      pathOrName,
      params: params,
      query: query,
    );
    final previous = _lastLocation;
    history.replace(uri, state: state);
    _reportLocationChange(previous);
  }

  Uri _resolveNavigationTarget(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
  }) {
    if (_isAbsolutePath(pathOrName)) {
      if (params case final incoming? when incoming.isNotEmpty) {
        throw ArgumentError.value(
          params,
          'params',
          'Path navigation does not accept route params.',
        );
      }

      final parsed = Uri.parse(pathOrName);
      final path = normalizePath([parsed.path]);
      final match = matcher.match(path);
      if (match == null) {
        throw StateError('Route path "$pathOrName" not found.');
      }

      final resolvedQuery = query?.toString() ?? parsed.query;
      return parsed.replace(path: path, query: resolvedQuery);
    }

    final alias = aliases.match(normalizePath([pathOrName]));
    if (alias == null) {
      throw StateError('Route name "$pathOrName" not found.');
    }

    final path = _fillRoutePattern(alias.data, params ?? const {});
    final match = matcher.match(path);
    if (match == null) {
      throw StateError('Resolved route "$path" not found.');
    }

    return Uri(path: path, query: query?.toString());
  }

  bool _isAbsolutePath(String location) => location.startsWith('/');

  String _fillRoutePattern(String pattern, Map<String, String> params) {
    if (pattern == '/') {
      if (params.isNotEmpty) {
        throw ArgumentError.value(
          params,
          'params',
          'Route "/" does not accept params.',
        );
      }
      return '/';
    }

    final consumed = <String>{};
    final segments = <String>[];
    for (final segment in pattern.split('/')) {
      if (segment.isEmpty) {
        continue;
      }

      if (segment.startsWith(':')) {
        final name = segment.substring(1);
        if (name.isEmpty) {
          throw StateError('Invalid route pattern "$pattern".');
        }
        final value = params[name];
        if (value == null || value.isEmpty) {
          throw ArgumentError.value(
            params,
            'params',
            'Missing required param "$name".',
          );
        }
        if (value.contains('/')) {
          throw ArgumentError.value(
            params,
            'params',
            'Param "$name" must not contain "/".',
          );
        }
        consumed.add(name);
        segments.add(value);
        continue;
      }

      if (segment == '*') {
        final value = params['wildcard'];
        if (value == null) {
          throw ArgumentError.value(
            params,
            'params',
            'Missing required param "wildcard".',
          );
        }
        consumed.add('wildcard');
        segments.addAll(value.split('/').where((entry) => entry.isNotEmpty));
        continue;
      }

      segments.add(segment);
    }

    final extras = params.keys.where((entry) => !consumed.contains(entry));
    if (extras.isNotEmpty) {
      throw ArgumentError.value(
        params,
        'params',
        'Unexpected params: ${extras.join(', ')}.',
      );
    }

    return normalizePath(segments);
  }

  void _handleHistoryChange(HistoryEvent event) {
    _reportLocationChange(_lastLocation, next: event.location);
  }

  void _reportLocationChange(
    HistoryLocation previous, {
    HistoryLocation? next,
  }) {
    final current = next ?? history.location;
    if (_isSameLocation(previous, current)) {
      return;
    }

    _lastLocation = current;
    notifyListeners();
  }

  bool _isSameLocation(HistoryLocation a, HistoryLocation b) {
    return a.uri == b.uri && a.state == b.state;
  }

  @override
  void dispose() {
    _unlistenHistory();
    super.dispose();
  }
}
