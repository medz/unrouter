import 'package:flutter/foundation.dart';
import 'package:roux/roux.dart'
    show RouterContext, addRoute, createRouter, findRoute;

import '_internal/path_matcher.dart';
import 'inlet.dart';
import 'route_matcher.dart';

/// Precompiled route index for full-path matching.
class RouteIndex {
  RouteIndex._(this._routes, this._router);

  final List<Inlet> _routes;
  final RouterContext<_RouteEntry> _router;

  Iterable<Inlet> get routes => _routes;

  factory RouteIndex.fromRoutes(List<Inlet> routes) {
    final seen = <String>{};
    final router = createRouter<_RouteEntry>();

    void visit(
      Inlet route,
      String basePattern,
      List<Inlet> stack,
    ) {
      _validateRoute(route);

      final normalized = normalizePath(route.path);
      if (route.children.isNotEmpty && _hasDoubleWildcard(normalized)) {
        throw FlutterError(
          'Routes with "**" wildcards cannot have children.\n'
          'Found in route path "${route.path}".',
        );
      }

      final pattern = _joinPattern(basePattern, normalized);
      final nextStack = [...stack, route];

      if (route.children.isEmpty) {
        final normalizedPattern = normalizePattern(pattern);
        final key = _patternKey(normalizedPattern);
        if (seen.contains(key)) {
          throw FlutterError('Duplicate route path "$key".');
        }
        final entry = _RouteEntry(stack: nextStack);
        seen.add(key);
        addRoute(router, null, key, entry);
        return;
      }

      for (final child in route.children) {
        visit(child, pattern, nextStack);
      }
    }

    for (final route in routes) {
      visit(route, '', const []);
    }

    return RouteIndex._(List<Inlet>.unmodifiable(routes), router);
  }

  RouteMatchResult match(String location) {
    final normalizedPath = normalizePath(location);
    final path = normalizedPath.isEmpty ? '/' : '/$normalizedPath';
    final match = findRoute(_router, null, path);
    if (match == null) {
      return const RouteMatchResult([], false);
    }

    final entry = match.data;
    var remaining =
        normalizedPath.isEmpty ? <String>[] : normalizedPath.split('/');

    final matches = <MatchedRoute>[];
    for (final route in entry.stack) {
      if (route.path.isEmpty) {
        if (route.children.isEmpty && remaining.isNotEmpty) {
          return const RouteMatchResult([], false);
        }
        matches.add(MatchedRoute(route, const {}));
        continue;
      }

      final result = matchPath(route.path, remaining);
      if (!result.matched) {
        return const RouteMatchResult([], false);
      }
      matches.add(MatchedRoute(route, result.params));
      remaining = result.remaining;
    }

    return RouteMatchResult(matches, true);
  }
}

class _RouteEntry {
  const _RouteEntry({required this.stack});

  final List<Inlet> stack;
}

String _patternKey(String pattern) {
  if (pattern.isEmpty) return '/';
  return pattern.startsWith('/') ? pattern : '/$pattern';
}

String _joinPattern(String base, String segment) {
  if (segment.isEmpty) return base;
  if (base.isEmpty) return segment;
  return '$base/$segment';
}

bool _hasDoubleWildcard(String pattern) {
  final segments = splitPath(pattern);
  for (final segment in segments) {
    if (segment.startsWith('**')) {
      return true;
    }
  }
  return false;
}

void _validateRoute(Inlet route) {
  if (route.path.contains('?')) {
    throw FlutterError(
      'Optional segments are not supported.\n'
      'Found in route path "${route.path}".',
    );
  }
}
