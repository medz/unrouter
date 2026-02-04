import 'package:flutter/widgets.dart';

import '../route_matcher.dart';
import 'path_matcher.dart';

/// Resolves the remaining path that a nested Routes widget should match against.
///
/// This mirrors the logic in Routes.build, but can be applied to any location.
String resolveRoutesPath(
  RouteInformation location,
  List<MatchedRoute> matchedRoutes,
  int level,
) {
  final fullPath = location.uri.path;
  final segments = normalizePath(fullPath);
  final pathSegments = segments.isEmpty ? <String>[] : segments.split('/');

  final end = (level + 1).clamp(0, matchedRoutes.length);
  if (end == 0) {
    return pathSegments.isEmpty ? '/' : '/${pathSegments.join('/')}';
  }

  final routesToMatch = matchedRoutes.sublist(0, end);
  int? consumedSegments;
  for (var offset = 0; offset <= pathSegments.length; offset++) {
    final consumed = _matchRouteSequence(routesToMatch, pathSegments, offset);
    if (consumed != null) {
      consumedSegments = offset + consumed;
      break;
    }
  }
  consumedSegments ??= _consumeFromStart(routesToMatch, pathSegments);

  final remainingSegments = consumedSegments < pathSegments.length
      ? pathSegments.sublist(consumedSegments)
      : <String>[];
  return remainingSegments.isEmpty ? '/' : '/${remainingSegments.join('/')}';
}

int? _matchRouteSequence(
  List<MatchedRoute> routes,
  List<String> pathSegments,
  int offset,
) {
  var cursor = offset;
  for (final matched in routes) {
    final route = matched.route;
    if (route.path.isEmpty && route.children.isNotEmpty) {
      continue;
    }
    if (route.path.isEmpty) {
      if (cursor != pathSegments.length) {
        return null;
      }
      continue;
    }
    if (cursor > pathSegments.length) {
      return null;
    }
    final remaining = pathSegments.sublist(cursor);
    final match = matchPath(route.path, remaining);
    if (!match.matched) {
      return null;
    }
    if (!_paramsMatch(match.params, matched.params)) {
      return null;
    }
    final consumed = remaining.length - match.remaining.length;
    cursor += consumed;
  }
  return cursor - offset;
}

int _consumeFromStart(List<MatchedRoute> routes, List<String> pathSegments) {
  var consumedSegments = 0;
  for (final matched in routes) {
    final route = matched.route;
    if (route.path.isNotEmpty) {
      final match = matchPath(
        route.path,
        pathSegments.sublist(consumedSegments),
      );
      if (match.matched) {
        final consumed =
            pathSegments.sublist(consumedSegments).length -
            match.remaining.length;
        consumedSegments += consumed;
      }
    }
  }
  return consumedSegments;
}

bool _paramsMatch(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
