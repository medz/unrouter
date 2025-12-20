import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:unrouter/history.dart';

import '../inlet.dart';
import '../route_animation.dart';
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

class _StackedRouteViewElement extends ComponentElement
    implements TickerProvider {
  _StackedRouteViewElement(super.widget);

  final Map<Object, _PageEntry> _pageStack = {};
  final List<Object> _indexOrder = [];
  final Set<Object> _transientKeys = {};

  final Set<Ticker> _tickers = <Ticker>{};
  ValueListenable<bool>? _tickerModeNotifier;

  Object? _activeKey;
  Inlet? _activeRoute;

  _PendingTransition? _pendingTransition;
  bool _transitionScheduled = false;
  int _transitionId = 0;

  @override
  StackedRouteView get widget => super.widget as StackedRouteView;

  @override
  void update(covariant StackedRouteView newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTickerModeNotifier();
  }

  void _updateTickerModeNotifier() {
    final newNotifier = TickerMode.getNotifier(this);
    if (_tickerModeNotifier == newNotifier) return;
    _tickerModeNotifier?.removeListener(_handleTickerModeChanged);
    _tickerModeNotifier = newNotifier;
    _tickerModeNotifier?.addListener(_handleTickerModeChanged);
    _handleTickerModeChanged();
  }

  void _handleTickerModeChanged() {
    final muted = !(_tickerModeNotifier?.value ?? true);
    for (final ticker in _tickers) {
      ticker.muted = muted;
    }
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    _updateTickerModeNotifier();
    late final _RouteTicker ticker;
    ticker = _RouteTicker(
      onTick,
      () {
        _tickers.remove(ticker);
      },
      debugLabel: 'StackedRouteView',
    );
    _tickers.add(ticker);
    ticker.muted = !(_tickerModeNotifier?.value ?? true);
    return ticker;
  }

  @override
  void unmount() {
    for (final entry in _pageStack.values) {
      entry.animation.dispose();
    }
    _pageStack.clear();
    _indexOrder.clear();
    _transientKeys.clear();

    _tickerModeNotifier?.removeListener(_handleTickerModeChanged);
    _tickerModeNotifier = null;

    for (final ticker in List<Ticker>.from(_tickers)) {
      ticker.dispose();
    }
    _tickers.clear();

    super.unmount();
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

    // On push, remove any leaf indices that are no longer reachable.
    if (action == HistoryAction.push) {
      final removedKeys = _indexOrder
          .where((key) => key is int && key > historyIndex)
          .toList();
      for (final key in removedKeys) {
        _disposeEntry(key);
      }
    }

    final previousKey = _activeKey;
    final previousRoute = _activeRoute;

    final nextState = state.withLevel(routeIndex);

    _PageEntry? pageEntry = _pageStack[cacheKey];
    final shouldRecreate =
        (action == HistoryAction.push && cacheKey is int) ||
        (action == HistoryAction.replace && pageEntry?.route != matched.route);

    Object? outgoingKey = previousKey;

    if (action == HistoryAction.replace &&
        shouldRecreate &&
        previousKey == cacheKey &&
        pageEntry != null) {
      final transitionKey = _TransitionKey(cacheKey, _transitionId++);
      _pageStack[transitionKey] = pageEntry;
      _indexOrder.add(transitionKey);
      _transientKeys.add(transitionKey);
      outgoingKey = transitionKey;
      pageEntry = null;
    }

    if (pageEntry == null || shouldRecreate) {
      final routeWidget = RouteStateScope(
        state: nextState,
        child: KeyedSubtree(key: UniqueKey(), child: matched.route.factory()),
      );
      pageEntry = _PageEntry(
        route: matched.route,
        widget: routeWidget,
        state: nextState,
        animation: RouteAnimationHandle(vsync: this),
      );
      _pageStack[cacheKey] = pageEntry;
    } else {
      final existing = pageEntry;
      pageEntry = _PageEntry(
        route: existing.route,
        widget: RouteStateScope(
          state: nextState,
          child: (existing.widget as RouteStateScope).child,
        ),
        state: nextState,
        animation: existing.animation,
      );
      _pageStack[cacheKey] = pageEntry;
    }

    _ensureKeyOrder(cacheKey);

    final hasTransition = previousKey != null &&
        outgoingKey != null &&
        outgoingKey != cacheKey &&
        (action == HistoryAction.push ||
            action == HistoryAction.pop ||
            action == HistoryAction.replace) &&
        (previousRoute != matched.route || action != HistoryAction.replace);

    if (hasTransition) {
      _queueTransition(
        _PendingTransition(
          incomingKey: cacheKey,
          outgoingKey: outgoingKey,
          action: action,
        ),
      );
    }

    _activeKey = cacheKey;
    _activeRoute = matched.route;

    final orderedKeys = List<Object>.from(_indexOrder);
    if (orderedKeys.remove(cacheKey)) {
      orderedKeys.add(cacheKey);
    } else {
      orderedKeys.add(cacheKey);
    }

    final children = <Widget>[];
    for (final key in orderedKeys) {
      final entry = _pageStack[key];
      if (entry == null) continue;
      final isActive = key == cacheKey;
      children.add(_buildEntryWidget(entry, isActive));
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(children: children);
  }

  void _ensureKeyOrder(Object key) {
    _indexOrder.remove(key);
    _indexOrder.add(key);
  }

  Widget _buildEntryWidget(_PageEntry entry, bool isActive) {
    final scoped = RouteAnimationScope(
      handle: entry.animation,
      isActive: isActive,
      child: entry.widget,
    );
    final content = IgnorePointer(ignoring: !isActive, child: scoped);

    return AnimatedBuilder(
      animation: entry.animation,
      child: content,
      builder: (context, child) {
        final controller = entry.animation.controller;
        if (controller == null) {
          return Offstage(offstage: !isActive, child: child);
        }
        return AnimatedBuilder(
          animation: controller,
          child: child,
          builder: (context, child) {
            final visible = isActive ||
                controller.value > controller.lowerBound ||
                controller.isAnimating;
            return Offstage(offstage: !visible, child: child);
          },
        );
      },
    );
  }

  void _queueTransition(_PendingTransition transition) {
    _pendingTransition = transition;
    if (_transitionScheduled) return;
    _transitionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transitionScheduled = false;
      final pending = _pendingTransition;
      _pendingTransition = null;
      if (pending != null) {
        _runTransition(pending);
      }
      if (_pendingTransition != null) {
        _queueTransition(_pendingTransition!);
      }
    });
  }

  void _runTransition(_PendingTransition transition) {
    final incomingEntry = _pageStack[transition.incomingKey];
    final outgoingEntry = _pageStack[transition.outgoingKey];

    final incomingController = incomingEntry?.animation.controller;
    final outgoingController = outgoingEntry?.animation.controller;

    VoidCallback? removeTransientListener;
    if (_transientKeys.contains(transition.outgoingKey) &&
        outgoingController != null) {
      void statusListener(AnimationStatus status) {
        if (status != AnimationStatus.dismissed) return;
        outgoingController.removeStatusListener(statusListener);
        _disposeEntry(transition.outgoingKey);
      }

      outgoingController.addStatusListener(statusListener);
      removeTransientListener = () {
        outgoingController.removeStatusListener(statusListener);
      };
    }

    if (incomingController != null) {
      incomingController.forward(from: incomingController.lowerBound);
    }
    if (outgoingController != null) {
      outgoingController.reverse(from: outgoingController.upperBound);
    }

    if (_transientKeys.contains(transition.outgoingKey)) {
      if (outgoingController == null) {
        _disposeEntry(transition.outgoingKey);
        return;
      }
      if (outgoingController.status == AnimationStatus.dismissed) {
        removeTransientListener?.call();
        _disposeEntry(transition.outgoingKey);
      }
    }
  }

  void _disposeEntry(Object key) {
    final entry = _pageStack.remove(key);
    entry?.animation.dispose();
    _indexOrder.remove(key);
    _transientKeys.remove(key);
  }
}

class _PageEntry {
  const _PageEntry({
    required this.route,
    required this.widget,
    required this.state,
    required this.animation,
  });

  final Inlet route;
  final Widget widget;
  final RouteState state;
  final RouteAnimationHandle animation;
}

class _RouteTicker extends Ticker {
  _RouteTicker(super.onTick, this._onDispose, {super.debugLabel});

  final VoidCallback _onDispose;

  @override
  void dispose() {
    _onDispose();
    super.dispose();
  }
}

class _PendingTransition {
  const _PendingTransition({
    required this.incomingKey,
    required this.outgoingKey,
    required this.action,
  });

  final Object incomingKey;
  final Object outgoingKey;
  final HistoryAction action;
}

class _TransitionKey {
  const _TransitionKey(this.key, this.id);

  final Object key;
  final int id;

  @override
  String toString() => 'TransitionKey($key#$id)';
}
