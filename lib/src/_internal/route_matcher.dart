import 'path_matcher.dart';

import '../inlet.dart';

/// A matched route with extracted parameters.
class MatchedRoute {
  const MatchedRoute(this.route, this.params);

  final Inlet route;
  final Map<String, String> params;

  @override
  String toString() =>
      'MatchedRoute(${route.path ?? '<index>'}, params: $params)';
}

/// Result of route matching.
class RouteMatchResult {
  const RouteMatchResult(this.matches, this.matched);

  /// Stack of matched routes from root to leaf.
  final List<MatchedRoute> matches;

  /// Whether the location was fully matched.
  final bool matched;

  @override
  String toString() => 'RouteMatchResult(matched: $matched, matches: $matches)';
}

/// Matches a location against a list of routes.
///
/// Returns a [RouteMatchResult] containing the matched route stack.
/// The first element is the root route, the last is the leaf route.
RouteMatchResult matchRoutes(List<Inlet> routes, String location) {
  final segments = normalizePath(location);
  final pathSegments = segments.isEmpty ? <String>[] : segments.split('/');

  final result = _matchRecursive(routes, pathSegments, 0);
  return RouteMatchResult(result.matches, result.fullyMatched);
}

class _MatchResult {
  const _MatchResult(this.matches, this.fullyMatched, this.consumedSegments);

  final List<MatchedRoute> matches;
  final bool fullyMatched;
  final int consumedSegments;
}

_MatchResult _matchRecursive(
  List<Inlet> routes,
  List<String> segments,
  int offset,
) {
  // Try each route
  for (final route in routes) {
    if ((route.path == null || route.path?.isEmpty == true) &&
        route.children.isNotEmpty) {
      // Layout route - doesn't consume segment, just try children
      if (route.children.isNotEmpty) {
        final childResult = _matchRecursive(route.children, segments, offset);
        if (childResult.fullyMatched) {
          // Prepend this layout to the match stack
          return _MatchResult(
            [MatchedRoute(route, const {}), ...childResult.matches],
            true,
            childResult.consumedSegments,
          );
        }
      }
    } else if (route.path == null) {
      // Index route - matches when no segments left
      if (offset >= segments.length) {
        return _MatchResult([MatchedRoute(route, const {})], true, 0);
      }
    } else {
      // Path route - try to match current segment
      if (offset < segments.length) {
        final remainingPath = segments.sublist(offset);
        final match = matchPath(route.path!, remainingPath);

        if (match.matched) {
          // Calculate how many segments were consumed
          final consumedCount = remainingPath.length - match.remaining.length;
          final newOffset = offset + consumedCount;

          if (route.children.isEmpty) {
            // Leaf route - check if all segments consumed
            if (newOffset >= segments.length) {
              return _MatchResult(
                [MatchedRoute(route, match.params)],
                true,
                consumedCount,
              );
            }
          } else {
            // Has children - try to match remaining
            final childResult = _matchRecursive(
              route.children,
              segments,
              newOffset,
            );
            if (childResult.fullyMatched) {
              return _MatchResult(
                [MatchedRoute(route, match.params), ...childResult.matches],
                true,
                consumedCount + childResult.consumedSegments,
              );
            }
          }
        }
      }
    }
  }

  // No match found
  return const _MatchResult([], false, 0);
}
