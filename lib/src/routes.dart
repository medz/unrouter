import 'package:flutter/widgets.dart';

import 'path_matcher.dart';
import 'router_state.dart';
import 'unroute.dart';

/// A widget that renders one of its route children based on the current location.
///
/// Routes can be nested to create hierarchical routing:
/// ```dart
/// Routes([
///   Unroute(path: 'auth', factory: AuthLayout.new),
/// ])
///
/// class AuthLayout extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         Header(),
///         Routes([
///           Unroute(path: 'login', factory: Login.new),
///           Unroute(path: 'register', factory: Register.new),
///         ]),
///       ],
///     );
///   }
/// }
/// ```
class Routes extends StatelessWidget {
  const Routes(this.routes, {super.key});

  /// The route configurations to match against.
  final Iterable<Unroute> routes;

  @override
  Widget build(BuildContext context) {
    final state = RouterStateProvider.of(context);
    final remainingPath = state.remainingPath;

    // Try to match each route
    for (final route in routes) {
      final match = matchPath(route.path, remainingPath);

      if (match.matched) {
        // Update router state with new params and remaining path
        final newState = state.withRemainingPath(
          match.remaining,
          match.params,
        );

        // Render the matched route with updated state
        return RouterStateProvider(
          state: newState,
          child: route.factory(),
        );
      }
    }

    // No route matched - render empty container or 404
    // TODO: Support custom 404 widget
    return const SizedBox.shrink();
  }
}
