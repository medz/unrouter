import 'package:flutter/widgets.dart';

import '../_internal/routes_matcher.dart';
import '../blocker.dart';
import '../extensions.dart';
import '../route_index.dart';
import '../route_matcher.dart';
import '../route_state.dart';
import '../_internal/stacked_route_view.dart';

/// A widget that matches and renders routes based on the current location.
///
/// Unlike [Outlet], which renders the next child in a pre-matched declarative route stack,
/// `Routes` accepts its own [RouteIndex] and performs matching based
/// on the current location and rendering level.
///
/// This enables widget-scoped routing where routes are defined directly within
/// the component tree rather than centrally in `Unrouter.routes`.
///
/// `Routes` performs full matching for its scope. For nested paths, define
/// child [Inlet] routes and render them with [Outlet].
///
/// Example:
/// ```dart
/// class About extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         Text('About'),
///         Routes(RouteIndex.fromRoutes([
///           Inlet(factory: AboutHome.new),
///           Inlet(path: 'details', factory: AboutDetails.new),
///         ])),
///       ],
///     );
///   }
/// }
/// ```
class Routes extends StatelessWidget {
  /// Creates a Routes widget with a [RouteIndex].
  const Routes(this.routes, {super.key});

  /// The routes to match against the current location.
  final RouteIndex routes;

  @override
  Widget build(BuildContext context) {
    // Try to get router state - if we're nested in a router
    final state = context.maybeRouteState;

    if (state == null) {
      // No router state available - can't match routes
      return const SizedBox.shrink();
    }

    final pathToMatch = state.matchedRoutes.isEmpty
        ? state.location.uri.path
        : resolveRoutesPath(state.location, state.matchedRoutes, state.level);

    // Match routes against the determined path
    final result = routes.match(pathToMatch);

    if (result.matches.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create a new router state with the matched routes
    final newState = RouteState(
      location: state.location,
      matchedRoutes: result.matches,
      level: 0,
      historyIndex: state.historyIndex,
      action: state.action,
    );

    final parentScope = BlockerScope.maybeOf(context);
    final scopeData = parentScope?.scope.createRoutesScope(
      routes: routes,
      anchorLevel: state.level,
      anchorPrefix: _sliceMatchedRoutes(state.matchedRoutes, state.level),
    );

    final content = StackedRouteView(state: newState, levelOffset: 0);
    if (parentScope == null || scopeData == null) {
      return content;
    }

    return BlockerScope(
      registry: parentScope.registry,
      scope: scopeData,
      child: content,
    );
  }
}

List<MatchedRoute> _sliceMatchedRoutes(
  List<MatchedRoute> matchedRoutes,
  int level,
) {
  if (matchedRoutes.isEmpty) return const [];
  final end = (level + 1).clamp(0, matchedRoutes.length);
  return matchedRoutes.sublist(0, end);
}
