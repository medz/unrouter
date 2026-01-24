import 'package:flutter/widgets.dart';

import '../inlet.dart';
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

/// Match routes with greedy matching - allows partial matches for dynamic nesting.
RouteMatchResult matchRoutesGreedy(List<Inlet> routes, String location) {
  final segments = normalizePath(location);
  final pathSegments = segments.isEmpty ? <String>[] : segments.split('/');

  final result = _matchRoutesGreedyInternal(routes, pathSegments);
  return RouteMatchResult(result.matches, result.matched);
}

class _GreedyMatch {
  const _GreedyMatch(
    this.matches,
    this.matched,
    this.consumedSegments,
    this.specificity,
  );

  final List<MatchedRoute> matches;
  final bool matched;
  final int consumedSegments;
  final PathSpecificity specificity;
}

_GreedyMatch _matchRoutesGreedyInternal(
  List<Inlet> routes,
  List<String> pathSegments,
) {
  _GreedyMatch? bestFullMatch;
  _GreedyMatch? bestPartialMatch;

  _GreedyMatch pickBest(_GreedyMatch? current, _GreedyMatch candidate) {
    if (current == null) return candidate;
    final specificCompare = candidate.specificity.compareTo(
      current.specificity,
    );
    if (specificCompare > 0) return candidate;
    if (specificCompare < 0) return current;
    if (candidate.consumedSegments > current.consumedSegments) {
      return candidate;
    }
    return current;
  }

  for (final route in routes) {
    if (route.path.isEmpty && route.children.isEmpty) {
      // Index route - only matches root
      if (pathSegments.isEmpty) {
        final candidate = _GreedyMatch(
          [MatchedRoute(route, const {})],
          true,
          0,
          const PathSpecificity(),
        );
        bestFullMatch = pickBest(bestFullMatch, candidate);
      }
      continue;
    }

    if (route.path.isEmpty && route.children.isNotEmpty) {
      // Layout route - try children
      final childResult = _matchRoutesGreedyInternal(
        route.children,
        pathSegments,
      );
      if (childResult.matches.isNotEmpty) {
        final candidate = _GreedyMatch(
          [MatchedRoute(route, const {}), ...childResult.matches],
          childResult.matched,
          childResult.consumedSegments,
          childResult.specificity,
        );
        if (candidate.matched) {
          bestFullMatch = pickBest(bestFullMatch, candidate);
        } else {
          bestPartialMatch = pickBest(bestPartialMatch, candidate);
        }
      }
      continue;
    }

    // Path route - try to match
    final match = matchPath(route.path, pathSegments);
    if (!match.matched) {
      continue;
    }

    final consumedCount = pathSegments.length - match.remaining.length;

    if (route.children.isNotEmpty && match.remaining.isNotEmpty) {
      // Try to match children with remaining path
      final childResult = _matchRoutesGreedyInternal(
        route.children,
        match.remaining,
      );
      if (childResult.matches.isNotEmpty) {
        final candidate = _GreedyMatch(
          [MatchedRoute(route, match.params), ...childResult.matches],
          childResult.matched,
          consumedCount + childResult.consumedSegments,
          match.specificity + childResult.specificity,
        );
        if (candidate.matched) {
          bestFullMatch = pickBest(bestFullMatch, candidate);
        } else {
          bestPartialMatch = pickBest(bestPartialMatch, candidate);
        }
        continue;
      }
    }

    final candidate = _GreedyMatch(
      [MatchedRoute(route, match.params)],
      match.remaining.isEmpty,
      consumedCount,
      match.specificity,
    );
    if (candidate.matched) {
      bestFullMatch = pickBest(bestFullMatch, candidate);
    } else {
      bestPartialMatch = pickBest(bestPartialMatch, candidate);
    }
  }

  if (bestFullMatch != null) {
    return bestFullMatch;
  }
  if (bestPartialMatch != null) {
    return bestPartialMatch;
  }

  return const _GreedyMatch([], false, 0, PathSpecificity());
}
