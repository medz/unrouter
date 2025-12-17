import 'package:flutter/widgets.dart';

import '../router_state.dart';

/// A widget that renders the next matched child route.
///
/// RouterView must be used inside layout and nested routes to render their children.
/// It looks at the current level in the RouterState and renders the next matched route.
///
/// Example:
/// ```dart
/// class AuthLayout extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: const Text('Auth')),
///       body: const RouterView(),  // Renders matched child (login/register)
///     );
///   }
/// }
/// ```
class RouterView extends StatelessWidget {
  const RouterView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = RouterStateProvider.of(context);
    final currentLevel = state.level;
    final nextIndex = currentLevel + 1;

    // Check if there's a child route to render
    if (nextIndex >= state.matchedRoutes.length) {
      return const SizedBox.shrink();
    }

    final nextMatched = state.matchedRoutes[nextIndex];
    final widget = nextMatched.route.factory();

    // Wrap child in provider with incremented level
    return RouterStateProvider(
      state: state.withLevel(nextIndex),
      child: widget,
    );
  }
}
