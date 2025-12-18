import 'package:flutter/widgets.dart';

import '../history/history.dart';
import '../inlet.dart';
import '../router_state.dart';
import 'route_cache_key.dart';

/// A stateful view that renders a matched route and keeps a stack of pages.
///
/// - Leaf routes are keyed by history index (so they can be stacked).
/// - Routes with children (layout/nested) are keyed by [RouteCacheKey] (so they can be reused).
class StackedRouteView extends StatefulWidget {
  const StackedRouteView({
    super.key,
    required this.state,
    required this.levelOffset,
  });

  final RouterState state;
  final int levelOffset;

  @override
  State<StackedRouteView> createState() => _StackedRouteViewState();
}

class _StackedRouteViewState extends State<StackedRouteView> {
  final Map<Object, _PageEntry> _pageStack = {};
  final List<Object> _indexOrder = [];

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final routeIndex = state.level + widget.levelOffset;

    if (routeIndex < 0 || routeIndex >= state.matchedRoutes.length) {
      return const SizedBox.shrink();
    }

    final matched = state.matchedRoutes[routeIndex];
    final historyIndex = state.historyIndex;
    final historyAction = state.historyAction;

    final cacheKey = matched.route.children.isNotEmpty
        ? RouteCacheKey(matched.route, matched.params)
        : historyIndex;

    // On push/replace, remove any leaf indices that are no longer reachable.
    if (historyAction == HistoryAction.push) {
      _indexOrder.removeWhere((key) => key is int && key > historyIndex);
    }

    final nextState = state.withLevel(routeIndex);

    _PageEntry? pageEntry = _pageStack[cacheKey];
    final shouldRecreate =
        (historyAction == HistoryAction.push && cacheKey is int) ||
        (historyAction == HistoryAction.replace && pageEntry?.route != matched.route);

    if (pageEntry == null || shouldRecreate) {
      final widget = RouterStateProvider(
        state: nextState,
        child: KeyedSubtree(key: UniqueKey(), child: matched.route.factory()),
      );
      pageEntry = _PageEntry(
        route: matched.route,
        widget: widget,
        state: nextState,
      );
      _pageStack[cacheKey] = pageEntry;

      if (!_indexOrder.contains(cacheKey)) {
        _indexOrder.add(cacheKey);
      }
    } else {
      final existing = pageEntry;
      pageEntry = _PageEntry(
        route: existing.route,
        widget: RouterStateProvider(
          state: nextState,
          child: (existing.widget as RouterStateProvider).child,
        ),
        state: nextState,
      );
      _pageStack[cacheKey] = pageEntry;
      if (!_indexOrder.contains(cacheKey)) {
        _indexOrder.add(cacheKey);
      }
    }

    final stackIndex = _indexOrder.indexOf(cacheKey);

    final children = _indexOrder.map((key) {
      return _pageStack[key]?.widget ?? const SizedBox.shrink();
    }).toList();

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return IndexedStack(
      index: stackIndex >= 0 ? stackIndex : children.length - 1,
      children: children,
    );
  }
}

class _PageEntry {
  const _PageEntry({
    required this.route,
    required this.widget,
    required this.state,
  });

  final Inlet route;
  final Widget widget;
  final RouterState state;
}
