import 'package:flutter/widgets.dart';

import '../history/history.dart';
import '../inlet.dart';
import '../route_state.dart';
import 'route_cache_key.dart';

/// Renders a matched route and keeps a stack of pages.
///
/// - Leaf routes are keyed by history index (so they can be stacked).
/// - Routes with children (layout/nested) are keyed by [RouteCacheKey] (so they can be reused).
///
/// This is implemented with a custom [Element] so the page cache lives on the
/// element (like a [StatefulWidget] would), without creating a [State] object.
class StackedRouteView extends Widget {
  const StackedRouteView({
    super.key,
    required this.state,
    required this.levelOffset,
  });

  final RouteState state;
  final int levelOffset;

  @override
  Element createElement() => _StackedRouteViewElement(this);
}

class _StackedRouteViewElement extends ComponentElement {
  _StackedRouteViewElement(super.widget);

  final Map<Object, _PageEntry> _pageStack = {};
  final List<Object> _indexOrder = [];

  @override
  StackedRouteView get widget => super.widget as StackedRouteView;

  @override
  void update(covariant StackedRouteView newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  Widget build() {
    final state = widget.state;
    final routeIndex = state.level + widget.levelOffset;

    if (routeIndex < 0 || routeIndex >= state.matchedRoutes.length) {
      return const SizedBox.shrink();
    }

    final matched = state.matchedRoutes[routeIndex];
    final historyIndex = state.historyIndex;
    final action = state.action;

    final cacheKey = matched.route.children.isNotEmpty
        ? RouteCacheKey(matched.route, matched.params)
        : historyIndex;

    // On push/replace, remove any leaf indices that are no longer reachable.
    if (action == HistoryAction.push) {
      _indexOrder.removeWhere((key) => key is int && key > historyIndex);
    }

    final nextState = state.withLevel(routeIndex);

    _PageEntry? pageEntry = _pageStack[cacheKey];
    final shouldRecreate =
        (action == HistoryAction.push && cacheKey is int) ||
        (action == HistoryAction.replace && pageEntry?.route != matched.route);

    if (pageEntry == null || shouldRecreate) {
      final widget = RouteStateScope(
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
        widget: RouteStateScope(
          state: nextState,
          child: (existing.widget as RouteStateScope).child,
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
  final RouteState state;
}
