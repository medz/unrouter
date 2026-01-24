import '_internal/path_matcher.dart';
import 'inlet.dart';

/// A matched [Inlet] with extracted path parameters.
///
/// [params] contains only the parameters captured by this route's own
/// [Inlet.path]. To get merged params for the currently-rendering widget, use
/// `RouteState.params`.
class MatchedRoute {
  const MatchedRoute(this.route, this.params);

  /// The matched route definition.
  final Inlet route;

  /// Parameters extracted from the matched portion of [route]'s path.
  final Map<String, String> params;

  @override
  String toString() =>
      'MatchedRoute(${route.path.isNotEmpty ? route.path : '<index>'}, params: $params)';
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
RouteMatchResult matchRoutes(Iterable<Inlet> routes, String location) {
  final segments = normalizePath(location);
  final pathSegments = segments.isEmpty ? <String>[] : segments.split('/');

  final result = _matchRecursive(routes, pathSegments, 0);
  return RouteMatchResult(result.matches, result.fullyMatched);
}

class _MatchResult {
  const _MatchResult(
    this.matches,
    this.fullyMatched,
    this.consumedSegments,
    this.specificity,
  );

  final List<MatchedRoute> matches;
  final bool fullyMatched;
  final int consumedSegments;
  final PathSpecificity specificity;
}

_MatchResult _matchRecursive(
  Iterable<Inlet> routes,
  List<String> segments,
  int offset,
) {
  _MatchResult? bestFullMatch;
  _MatchResult? bestPartialMatch;

  _MatchResult pickBest(_MatchResult? current, _MatchResult candidate) {
    if (current == null) return candidate;
    final specificCompare = candidate.specificity.compareTo(current.specificity);
    if (specificCompare > 0) return candidate;
    if (specificCompare < 0) return current;
    if (candidate.consumedSegments > current.consumedSegments) {
      return candidate;
    }
    return current;
  }

  // Try each route
  for (final route in routes) {
    if (route.path.isEmpty && route.children.isNotEmpty) {
      // Layout route - doesn't consume segment, just try children
      if (route.children.isNotEmpty) {
        final childResult = _matchRecursive(route.children, segments, offset);
        if (childResult.matches.isNotEmpty) {
          final candidate = _MatchResult(
            [MatchedRoute(route, const {}), ...childResult.matches],
            childResult.fullyMatched,
            childResult.consumedSegments,
            childResult.specificity,
          );
          if (candidate.fullyMatched) {
            bestFullMatch = pickBest(bestFullMatch, candidate);
          } else {
            bestPartialMatch = pickBest(bestPartialMatch, candidate);
          }
        }
      }
    } else if (route.path.isEmpty) {
      // Index route - matches when no segments left
      if (offset >= segments.length) {
        final candidate = _MatchResult(
          [MatchedRoute(route, const {})],
          true,
          0,
          const PathSpecificity(),
        );
        bestFullMatch = pickBest(bestFullMatch, candidate);
      }
    } else {
      // Path route - try to match current segment
      if (offset < segments.length) {
        final remainingPath = segments.sublist(offset);
        final match = matchPath(route.path, remainingPath);

        if (match.matched) {
          // Calculate how many segments were consumed
          final consumedCount = remainingPath.length - match.remaining.length;
          final newOffset = offset + consumedCount;

          if (route.children.isEmpty) {
            // Leaf route
            final candidate = _MatchResult(
              [MatchedRoute(route, match.params)],
              newOffset >= segments.length,
              consumedCount,
              match.specificity,
            );
            if (candidate.fullyMatched) {
              bestFullMatch = pickBest(bestFullMatch, candidate);
            } else {
              bestPartialMatch = pickBest(bestPartialMatch, candidate);
            }
          } else {
            // Has children - try to match remaining
            final childResult = _matchRecursive(
              route.children,
              segments,
              newOffset,
            );
            if (childResult.matches.isNotEmpty) {
              final candidate = _MatchResult(
                [MatchedRoute(route, match.params), ...childResult.matches],
                childResult.fullyMatched,
                consumedCount + childResult.consumedSegments,
                match.specificity + childResult.specificity,
              );
              if (candidate.fullyMatched) {
                bestFullMatch = pickBest(bestFullMatch, candidate);
              } else {
                bestPartialMatch = pickBest(bestPartialMatch, candidate);
              }
            } else if (match.remaining.isNotEmpty) {
              final candidate = _MatchResult(
                [MatchedRoute(route, match.params)],
                false,
                consumedCount,
                match.specificity,
              );
              bestPartialMatch = pickBest(bestPartialMatch, candidate);
            }
          }
        }
      }
    }
  }

  if (bestFullMatch != null) {
    return bestFullMatch;
  }
  if (bestPartialMatch != null) {
    return bestPartialMatch;
  }

  // No match found
  return const _MatchResult([], false, 0, PathSpecificity());
}
