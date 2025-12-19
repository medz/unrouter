import 'package:flutter/widgets.dart';

import '../_internal/path_matcher.dart';
import '../inlet.dart';
import '../route_matcher.dart';
import '../router_state.dart';
import '../_internal/stacked_route_view.dart';

/// A widget that matches and renders routes based on the current location.
///
/// Unlike [Outlet], which renders the next child in a pre-matched declarative route stack,
/// `Routes` accepts its own [routes] list and performs matching based
/// on the current location and rendering level.
///
/// This enables widget-scoped routing where routes are defined directly within
/// the component tree rather than centrally in `Unrouter.routes`.
///
/// Example:
/// ```dart
/// class About extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         Text('About'),
///         Routes([
///           Inlet(factory: AboutHome.new),
///           Inlet(path: 'details', factory: AboutDetails.new),
///         ]),
///       ],
///     );
///   }
/// }
/// ```
class Routes extends StatelessWidget {
  /// Creates a Routes widget with a list of route definitions.
  const Routes(this.routes, {super.key});

  /// The routes to match against the current location.
  final List<Inlet> routes;

  @override
  Widget build(BuildContext context) {
    // Try to get router state - if we're nested in a router
    final state = RouterStateProvider.maybeOf(context);

    if (state == null) {
      // No router state available - can't match routes
      return const SizedBox.shrink();
    }

    // Get the full path from the location
    final fullPath = state.location.uri.path;

    // Determine which part of the path to match against
    String pathToMatch;

    if (state.matchedRoutes.isEmpty) {
      // No pre-matched routes - we're starting from scratch
      // Match against the full path
      pathToMatch = fullPath;
    } else {
      // We have pre-matched routes - need to figure out which segments are left
      // This happens when Routes is nested inside matched routes
      final segments = normalizePath(fullPath);
      final pathSegments = segments.isEmpty ? <String>[] : segments.split('/');

      int consumedSegments = 0;
      for (int i = 0; i <= state.level && i < state.matchedRoutes.length; i++) {
        final route = state.matchedRoutes[i].route;
        if (route.path.isNotEmpty) {
          final match = matchPath(route.path, pathSegments.sublist(consumedSegments));
          if (match.matched) {
            final consumed = pathSegments.sublist(consumedSegments).length - match.remaining.length;
            consumedSegments += consumed;
          }
        }
      }

      // Build path from remaining segments
      final remainingSegments = consumedSegments < pathSegments.length
          ? pathSegments.sublist(consumedSegments)
          : <String>[];
      pathToMatch = remainingSegments.isEmpty ? '/' : '/${remainingSegments.join('/')}';
    }

    // Match routes against the determined path
    // For dynamic routes, we want to allow partial matches
    // so that nested Routes widgets can continue matching
    final result = _matchRoutesGreedy(routes, pathToMatch);

    if (result.matches.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create a new router state with the matched routes
    final newState = RouterState(
      location: state.location,
      matchedRoutes: result.matches,
      level: 0,
      historyIndex: state.historyIndex,
      action: state.action,
    );

    return StackedRouteView(state: newState, levelOffset: 0);
  }

  /// Match routes with greedy matching - allows partial matches for dynamic nesting.
  ///
  /// Unlike standard matchRoutes which requires all path segments to be consumed,
  /// this allows matching a route even if there are remaining segments, enabling
  /// nested Routes widgets to continue matching.
  RouteMatchResult _matchRoutesGreedy(List<Inlet> routes, String location) {
    final segments = normalizePath(location);
    final pathSegments = segments.isEmpty ? <String>[] : segments.split('/');

    // Try to find the longest match
    List<MatchedRoute>? bestMatch;

    for (final route in routes) {
      if (route.path.isEmpty && route.children.isEmpty) {
        // Index route - only matches root
        if (pathSegments.isEmpty) {
          return RouteMatchResult([MatchedRoute(route, const {})], true);
        }
      } else if (route.path.isEmpty && route.children.isNotEmpty) {
        // Layout route - try children
        final childResult = _matchRoutesGreedy(route.children, location);
        if (childResult.matches.isNotEmpty) {
          return RouteMatchResult(
            [MatchedRoute(route, const {}), ...childResult.matches],
            childResult.matched,
          );
        }
      } else {
        // Path route - try to match
        final match = matchPath(route.path, pathSegments);
        if (match.matched) {
          final matched = [MatchedRoute(route, match.params)];

          // Check if we have children and remaining path
          if (route.children.isNotEmpty && match.remaining.isNotEmpty) {
            // Try to match children with remaining path
            final remainingPath = match.remaining.join('/');
            final childResult = _matchRoutesGreedy(route.children, remainingPath);
            if (childResult.matches.isNotEmpty) {
              return RouteMatchResult(
                [...matched, ...childResult.matches],
                childResult.matched,
              );
            }
          }

          // For dynamic nesting: accept partial match even if segments remain
          // The matched route might contain nested Routes widgets
          if (bestMatch == null || matched.length > bestMatch.length) {
            bestMatch = matched;
          }

          // If this is a complete match (no remaining segments), return immediately
          if (match.remaining.isEmpty) {
            return RouteMatchResult(matched, true);
          }
        }
      }
    }

    // Return best partial match if found
    if (bestMatch != null) {
      return RouteMatchResult(bestMatch, false);
    }

    return const RouteMatchResult([], false);
  }

}
