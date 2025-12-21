import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unrouter/history.dart';

import 'inlet.dart';
import 'route_matcher.dart';
import '_internal/route_state_scope.dart';
import '_internal/routes_matcher.dart';

typedef RouteBlockerCallback =
    FutureOr<bool> Function(RouteBlockerContext context);
typedef RouteBlockedCallback =
    FutureOr<void> Function(RouteBlockerContext context);

class RouteBlockerContext {
  final RouteInformation from;
  final RouteInformation to;
  final HistoryAction action;
  final int? delta;
  final int level;

  const RouteBlockerContext({
    required this.from,
    required this.to,
    required this.action,
    required this.delta,
    required this.level,
  });
}

class RouteBlocker extends StatefulWidget {
  const RouteBlocker({
    super.key,
    required this.onWillPop,
    this.onBlocked,
    this.enabled = true,
    required this.child,
  });

  final RouteBlockerCallback onWillPop;
  final RouteBlockedCallback? onBlocked;
  final bool enabled;
  final Widget child;

  @override
  State<RouteBlocker> createState() => _RouteBlockerState();
}

class _RouteBlockerState extends State<RouteBlocker> {
  BlockerHandle? _handle;
  BlockerScopeData? _scope;
  int? _level;
  MatchedRoute? _matchedRoute;
  BlockerRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final blockerScope = BlockerScope.maybeOf(context);
    final scope = blockerScope?.scope;
    final level = RouteStateScope.maybeOf(
      context,
      aspect: RouteStateAspect.level,
    )?.level;
    final matchedRoutes = RouteStateScope.maybeOf(
      context,
      aspect: RouteStateAspect.matchedRoutes,
    )?.matchedRoutes;
    final matchedRoute =
        (matchedRoutes != null &&
            level != null &&
            level >= 0 &&
            level < matchedRoutes.length)
        ? matchedRoutes[level]
        : null;
    _registry = blockerScope?.registry;

    if (_handle == null) {
      _register(scope, level, matchedRoute);
    } else if (_scope != scope ||
        _level != level ||
        !_sameMatchedRouteOrNull(_matchedRoute, matchedRoute)) {
      _update(scope, level, matchedRoute);
    }
  }

  @override
  void didUpdateWidget(covariant RouteBlocker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update(_scope, _level, _matchedRoute);
  }

  void _register(
    BlockerScopeData? scope,
    int? level,
    MatchedRoute? matchedRoute,
  ) {
    if (scope == null || level == null || matchedRoute == null) {
      return;
    }
    final registry = _registry;
    if (registry == null) return;
    _handle = registry.register(
      BlockerEntry(
        onWillPop: widget.onWillPop,
        onBlocked: widget.onBlocked,
        enabled: widget.enabled,
        level: level,
        scope: scope,
        matchedRoute: matchedRoute,
      ),
    );
    _scope = scope;
    _level = level;
    _matchedRoute = matchedRoute;
  }

  void _update(
    BlockerScopeData? scope,
    int? level,
    MatchedRoute? matchedRoute,
  ) {
    final registry = _registry;
    if (registry == null) return;
    final current = _handle;
    if (scope == null || level == null || matchedRoute == null) {
      if (current != null) {
        registry.unregister(current);
        _handle = null;
      }
      _scope = scope;
      _level = level;
      _matchedRoute = matchedRoute;
      return;
    }

    if (current == null) {
      _register(scope, level, matchedRoute);
      return;
    }

    registry.update(
      current,
      BlockerEntry(
        onWillPop: widget.onWillPop,
        onBlocked: widget.onBlocked,
        enabled: widget.enabled,
        level: level,
        scope: scope,
        matchedRoute: matchedRoute,
        order: current.order,
      ),
    );
    _scope = scope;
    _level = level;
    _matchedRoute = matchedRoute;
  }

  @override
  void dispose() {
    final registry = _registry;
    final current = _handle;
    if (registry != null && current != null) {
      registry.unregister(current);
    }
    _registry = null;
    _handle = null;
    _matchedRoute = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

@internal
class BlockerScope extends InheritedWidget {
  const BlockerScope({
    super.key,
    required this.registry,
    required this.scope,
    required super.child,
  });

  final BlockerRegistry registry;
  final BlockerScopeData scope;

  static BlockerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BlockerScope>();
  }

  static BlockerScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'BlockerScope is missing from the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(BlockerScope oldWidget) {
    return registry != oldWidget.registry || scope != oldWidget.scope;
  }
}

@internal
abstract class BlockerScopeData {
  const BlockerScopeData();

  int get depth;

  ScopeMatch match(RouteInformation location);

  BlockerScopeData createRoutesScope({
    required List<Inlet> routes,
    required int anchorLevel,
    required List<MatchedRoute> anchorPrefix,
  });
}

class _RootBlockerScopeData extends BlockerScopeData {
  const _RootBlockerScopeData(this.routes);

  final Iterable<Inlet>? routes;

  @override
  int get depth => 0;

  @override
  ScopeMatch match(RouteInformation location) {
    if (routes == null) {
      return const ScopeMatch(active: true, matches: []);
    }
    final result = matchRoutes(routes!, location.uri.path);
    return ScopeMatch(active: true, matches: result.matches);
  }

  @override
  BlockerScopeData createRoutesScope({
    required List<Inlet> routes,
    required int anchorLevel,
    required List<MatchedRoute> anchorPrefix,
  }) {
    return _RoutesBlockerScopeData(
      parent: this,
      routes: routes,
      anchorLevel: anchorLevel,
      anchorPrefix: anchorPrefix,
    );
  }
}

class _RoutesBlockerScopeData extends BlockerScopeData {
  const _RoutesBlockerScopeData({
    required this.parent,
    required this.routes,
    required this.anchorLevel,
    required this.anchorPrefix,
  });

  final BlockerScopeData parent;
  final List<Inlet> routes;
  final int anchorLevel;
  final List<MatchedRoute> anchorPrefix;

  @override
  int get depth => parent.depth + 1;

  @override
  ScopeMatch match(RouteInformation location) {
    final parentMatch = parent.match(location);
    if (!parentMatch.active) {
      return const ScopeMatch(active: false, matches: []);
    }
    if (!_prefixMatches(anchorPrefix, parentMatch.matches)) {
      return const ScopeMatch(active: false, matches: []);
    }

    final pathToMatch = resolveRoutesPath(
      location,
      parentMatch.matches,
      anchorLevel,
    );
    final result = matchRoutesGreedy(routes, pathToMatch);
    return ScopeMatch(active: true, matches: result.matches);
  }

  @override
  BlockerScopeData createRoutesScope({
    required List<Inlet> routes,
    required int anchorLevel,
    required List<MatchedRoute> anchorPrefix,
  }) {
    return _RoutesBlockerScopeData(
      parent: this,
      routes: routes,
      anchorLevel: anchorLevel,
      anchorPrefix: anchorPrefix,
    );
  }
}

class ScopeMatch {
  const ScopeMatch({required this.active, required this.matches});

  final bool active;
  final List<MatchedRoute> matches;
}

@internal
class BlockerHandle {
  BlockerHandle(this.id, this.order);

  final Object id;
  final int order;
}

@internal
class BlockerEntry {
  BlockerEntry({
    required this.onWillPop,
    required this.onBlocked,
    required this.enabled,
    required this.level,
    required this.scope,
    required this.matchedRoute,
    int? order,
  }) : order = order ?? 0;

  final RouteBlockerCallback onWillPop;
  final RouteBlockedCallback? onBlocked;
  final bool enabled;
  final int level;
  final BlockerScopeData scope;
  final MatchedRoute matchedRoute;
  final int order;
}

@internal
class BlockerRegistry {
  final Map<Object, BlockerEntry> _entries = {};
  int _nextOrder = 0;

  bool get hasEntries => _entries.isNotEmpty;

  BlockerHandle register(BlockerEntry entry) {
    final id = Object();
    final order = _nextOrder++;
    _entries[id] = BlockerEntry(
      onWillPop: entry.onWillPop,
      onBlocked: entry.onBlocked,
      enabled: entry.enabled,
      level: entry.level,
      scope: entry.scope,
      matchedRoute: entry.matchedRoute,
      order: order,
    );
    return BlockerHandle(id, order);
  }

  void update(BlockerHandle handle, BlockerEntry entry) {
    _entries[handle.id] = BlockerEntry(
      onWillPop: entry.onWillPop,
      onBlocked: entry.onBlocked,
      enabled: entry.enabled,
      level: entry.level,
      scope: entry.scope,
      matchedRoute: entry.matchedRoute,
      order: handle.order,
    );
  }

  void unregister(BlockerHandle handle) {
    _entries.remove(handle.id);
  }

  List<BlockerEntry> _sortedEntries() {
    final entries = _entries.values.toList();
    entries.sort((a, b) {
      final depth = b.scope.depth.compareTo(a.scope.depth);
      if (depth != 0) return depth;
      final level = b.level.compareTo(a.level);
      if (level != 0) return level;
      return b.order.compareTo(a.order);
    });
    return entries;
  }

  Future<bool> shouldAllowPop({
    required RouteInformation from,
    required RouteInformation to,
    required HistoryAction action,
    required int? delta,
  }) async {
    for (final entry in _sortedEntries()) {
      if (!entry.enabled) continue;

      final fromMatch = entry.scope.match(from);
      if (!fromMatch.active) continue;
      if (!_isActiveRoute(entry, fromMatch)) continue;

      final toMatch = entry.scope.match(to);
      if (!_shouldCheckEntry(entry, fromMatch, toMatch, delta)) {
        continue;
      }

      final context = RouteBlockerContext(
        from: from,
        to: to,
        action: action,
        delta: delta,
        level: entry.level,
      );

      bool allow;
      try {
        allow = await Future.value(entry.onWillPop(context));
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'unrouter',
            context: ErrorDescription('during RouteBlocker.onWillPop'),
          ),
        );
        allow = false;
      }

      if (!allow) {
        if (entry.onBlocked != null) {
          try {
            await Future.value(entry.onBlocked!(context));
          } catch (error, stackTrace) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stackTrace,
                library: 'unrouter',
                context: ErrorDescription('during RouteBlocker.onBlocked'),
              ),
            );
          }
        }
        return false;
      }
    }
    return true;
  }
}

bool _shouldCheckEntry(
  BlockerEntry entry,
  ScopeMatch fromMatch,
  ScopeMatch toMatch,
  int? delta,
) {
  if (delta == 0) {
    final leafLevel = fromMatch.matches.isEmpty
        ? 0
        : fromMatch.matches.length - 1;
    return entry.level >= leafLevel;
  }

  if (!toMatch.active) {
    return true;
  }

  final divergence = _findDivergenceLevel(fromMatch.matches, toMatch.matches);
  if (divergence == null) return false;
  return entry.level >= divergence;
}

int? _findDivergenceLevel(List<MatchedRoute> from, List<MatchedRoute> to) {
  final minLength = from.length < to.length ? from.length : to.length;
  for (var i = 0; i < minLength; i++) {
    if (!_sameMatchedRoute(from[i], to[i])) {
      return i;
    }
  }
  if (from.length != to.length) {
    return minLength;
  }
  return null;
}

bool _sameMatchedRoute(MatchedRoute a, MatchedRoute b) {
  if (!identical(a.route, b.route)) return false;
  return _sameParams(a.params, b.params);
}

bool _sameMatchedRouteOrNull(MatchedRoute? a, MatchedRoute? b) {
  if (a == null || b == null) return a == b;
  return _sameMatchedRoute(a, b);
}

bool _isActiveRoute(BlockerEntry entry, ScopeMatch fromMatch) {
  if (entry.level < 0 || entry.level >= fromMatch.matches.length) {
    return false;
  }
  return _sameMatchedRoute(entry.matchedRoute, fromMatch.matches[entry.level]);
}

bool _sameParams(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _prefixMatches(List<MatchedRoute> anchor, List<MatchedRoute> current) {
  if (anchor.isEmpty) return true;
  if (current.length < anchor.length) return false;
  for (var i = 0; i < anchor.length; i++) {
    if (!_sameMatchedRoute(anchor[i], current[i])) {
      return false;
    }
  }
  return true;
}

@internal
BlockerScopeData createRootBlockerScope(Iterable<Inlet>? routes) {
  return _RootBlockerScopeData(routes);
}
