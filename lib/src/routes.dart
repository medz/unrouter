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
class Routes extends StatefulWidget {
  const Routes(this.routes, {super.key});

  /// The route configurations to match against.
  final Iterable<Unroute> routes;

  @override
  State<Routes> createState() => _RoutesState();
}

class _RoutesState extends State<Routes> {
  /// Cached widget for the currently matched route.
  Widget? _cachedWidget;

  /// Path of the currently cached route.
  String? _cachedRoutePath;

  @override
  Widget build(BuildContext context) {
    final state = RouterStateProvider.of(context);
    final remainingPath = state.remainingPath;

    // Try to match each route
    for (final route in widget.routes) {
      final match = matchPath(route.path, remainingPath);

      if (match.matched) {
        // Update router state with new params and remaining path
        final newState = state.withRemainingPath(
          match.remaining,
          match.params,
        );

        // Check if we can reuse the cached widget
        // Only create new widget if the matched route changed
        if (route.path != _cachedRoutePath || _cachedWidget == null) {
          _cachedWidget = route.factory();
          _cachedRoutePath = route.path;
        }

        // Render the matched route with updated state
        return RouterStateProvider(
          state: newState,
          child: _cachedWidget!,
        );
      }
    }

    // No route matched - clear cache and render empty container
    _cachedWidget = null;
    _cachedRoutePath = null;
    return const SizedBox.shrink();
  }
}
