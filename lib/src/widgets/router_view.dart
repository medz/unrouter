import 'package:flutter/widgets.dart' hide Route;

import '../history/types.dart';
import '../_internal/route_cache_key.dart';
import '../route.dart';
import '../router_state.dart';

/// A widget that renders the next matched child route.
///
/// RouterView must be used inside layout and nested routes to render their children.
/// It maintains a stack of child widgets to preserve state across navigation.
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
class RouterView extends StatefulWidget {
  const RouterView({super.key});

  @override
  State<RouterView> createState() => _RouterViewState();
}

class _RouterViewState extends State<RouterView> {
  /// Stack of child pages.
  ///
  /// - Leaf routes are keyed by history index (so they can be stacked).
  /// - Layout/nested routes are keyed by [RouteCacheKey] (so they can be reused).
  final Map<Object, _PageEntry> _pageStack = {};

  /// Stack key order, for IndexedStack rendering.
  final List<Object> _indexOrder = [];

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
    final historyIndex = state.historyIndex;
    final navigationType = state.navigationType;

    final cacheKey = nextMatched.route.children.isNotEmpty
        ? RouteCacheKey(nextMatched.route, nextMatched.params)
        : historyIndex;

    // On push/replace, remove any leaf indices that are no longer reachable.
    if (navigationType == NavigationType.push) {
      _indexOrder.removeWhere((key) => key is int && key > historyIndex);
    }

    final nextState = state.withLevel(nextIndex);

    // Get or create the page for this key.
    _PageEntry? pageEntry = _pageStack[cacheKey];
    final shouldRecreate =
        navigationType == NavigationType.push && cacheKey is int;

    if (pageEntry == null || shouldRecreate) {
      // Create new page for push/replace navigation or if not in cache.
      final widget = RouterStateProvider(
        state: nextState,
        child: KeyedSubtree(
          key: UniqueKey(),
          child: nextMatched.route.factory(),
        ),
      );

      pageEntry = _PageEntry(
        route: nextMatched.route,
        widget: widget,
        state: nextState,
      );
      _pageStack[cacheKey] = pageEntry;

      if (!_indexOrder.contains(cacheKey)) {
        _indexOrder.add(cacheKey);
      }
    } else {
      // Update state but keep widget
      pageEntry = _PageEntry(
        route: pageEntry.route,
        widget: RouterStateProvider(
          state: nextState,
          child: (pageEntry.widget as RouterStateProvider).child,
        ),
        state: nextState,
      );
      _pageStack[cacheKey] = pageEntry;
      if (!_indexOrder.contains(cacheKey)) {
        _indexOrder.add(cacheKey);
      }
    }

    // Find current index in stack
    final stackIndex = _indexOrder.indexOf(cacheKey);

    // Build all pages in stack
    final children = _indexOrder.map((key) {
      final entry = _pageStack[key];
      if (entry == null) return const SizedBox.shrink();
      return entry.widget;
    }).toList();

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use IndexedStack to preserve all pages
    return IndexedStack(
      index: stackIndex >= 0 ? stackIndex : children.length - 1,
      children: children,
    );
  }
}

/// Entry in the page stack.
class _PageEntry {
  const _PageEntry({
    required this.route,
    required this.widget,
    required this.state,
  });

  final Route route;
  final Widget widget;
  final RouterState state;
}
