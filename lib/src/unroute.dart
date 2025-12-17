import 'package:flutter/widgets.dart';

import 'path_matcher.dart';
import 'router_state.dart';

/// A route configuration that can be nested in the widget tree.
///
/// Unroute can be used in two ways:
///
/// 1. **Inside Routes** - for route switching:
/// ```dart
/// Routes([
///   Unroute(path: 'about', factory: About.new),
///   Unroute(path: 'contact', factory: Contact.new),
/// ])
/// ```
///
/// 2. **Standalone** - for conditional rendering or layouts:
/// ```dart
/// Column([
///   Header(),
///   Unroute(path: 'feed', factory: Feed.new),  // shows when path matches
///   Footer(),
/// ])
///
/// TabBarView([
///   Unroute(path: 'tab1', factory: Tab1.new),
///   Unroute(path: 'tab2', factory: Tab2.new),
/// ])
/// ```
///
/// **Performance**: Unroute caches the created widget. When switching routes,
/// only the newly matched Unroute creates its widget for the first time.
/// Subsequent matches reuse the cached widget.
class Unroute extends StatefulWidget {
  const Unroute({
    super.key,
    this.path,
    required this.factory,
  });

  /// The path pattern for this route.
  ///
  /// - `null`, `''`, or `'/'` for index routes
  /// - Static segments: `'about'`, `'users/profile'`
  /// - Dynamic params: `':id'`, `':userId'`
  /// - Optional params: `':id?'`, `':lang?/about'`
  /// - Optional segments: `'edit?'`
  /// - Wildcard: `'*'`, `'files/*'`
  final String? path;

  /// Factory function that creates the widget for this route.
  final Widget Function() factory;

  @override
  State<Unroute> createState() => _UnrouteState();
}

class _UnrouteState extends State<Unroute> {
  /// Cached widget created by factory().
  /// This ensures the widget is only created once, even when switching routes.
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    // When used standalone (not inside Routes), Unroute checks if its
    // path matches the current route and renders accordingly.
    final state = RouterStateProvider.maybeOf(context);

    // If no router state, just render (for testing or non-router context)
    if (state == null) {
      _cachedWidget ??= widget.factory();
      return _cachedWidget!;
    }

    final remainingPath = state.remainingPath;
    final match = matchPath(widget.path, remainingPath);

    if (match.matched) {
      // Update router state with new params and remaining path
      final newState = state.withRemainingPath(
        match.remaining,
        match.params,
      );

      // Create widget only once, then cache it
      // This ensures that when switching from /a/b to /a/c and back to /a/b,
      // the B widget is not recreated
      _cachedWidget ??= widget.factory();

      // Render the matched route with updated state
      return RouterStateProvider(
        state: newState,
        child: _cachedWidget!,
      );
    }

    // Path doesn't match - render nothing, but keep cache
    // This is important: when switching from /a/b to /a/c,
    // B's Unroute doesn't match but keeps its cached widget
    return const SizedBox.shrink();
  }
}
