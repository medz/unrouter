import 'package:flutter/widgets.dart' as flutter;
import 'package:zenrouter/zenrouter.dart' as zenrouter;

/// Factory type for a route component (usually `.new`).
typedef RouteFactory<T extends flutter.Widget> = T Function();

/// Route definition.
class Route<T extends flutter.Widget> {
  const Route(this.path, this.factory, {this.name, this.children = const []});

  /// Path pattern (e.g. `/`, `about`, `:id`, `**`).
  final String path;

  /// Component factory (constructor tear-off).
  final RouteFactory<T> factory;

  /// Nested routes (rendered by RouterView).
  final Iterable<Route> children;

  /// Optional name.
  final String? name;
}

// ---------------------------------------------------------------------------
// Router runtime
// ---------------------------------------------------------------------------

/// Match info for a single route.
class RouteMatch {
  RouteMatch(this.route, this.params);

  final Route route;
  final Map<String, String> params;

  String? get name => route.name;
}

/// Snapshot of current navigation state.
class RouteSnapshot {
  RouteSnapshot({required this.uri, required this.matches});

  final Uri uri;
  final List<RouteMatch> matches;

  RouteMatch? get current => matches.isNotEmpty ? matches.last : null;
  String get path => uri.path;
  Map<String, String> get query => uri.queryParameters;

  Map<String, String> get params {
    final map = <String, String>{};
    for (final match in matches) {
      map.addAll(match.params);
    }
    return map;
  }

  String? get name => current?.name;
}

/// Main router built on zenrouter Coordinator.
class Unrouter extends zenrouter.Coordinator<UnRoutePage> {
  Unrouter({required Iterable<Route> routes, String initialPath = '/'})
    : _tree = _RouteTree(routes.toList()),
      _initialUri = _normalize(initialPath);

  final _RouteTree _tree;
  final Uri _initialUri;

  late final UnRoutePage _initialPage = parseRouteFromUri(_initialUri);

  /// Replace stack with [path].
  void go(String path) => replace(parseRouteFromUri(_normalize(path)));

  /// Push new page.
  Future<dynamic> pushPath(String path) =>
      push(parseRouteFromUri(_normalize(path)));

  /// Pop current.
  @override
  void pop([Object? result]) => super.pop(result);

  @override
  flutter.Widget layoutBuilder(flutter.BuildContext context) =>
      zenrouter.NavigationStack<UnRoutePage>(
        path: root,
        coordinator: this,
        defaultRoute: _initialPage,
        resolver: (route) => zenrouter.StackTransition.material(
          flutter.Builder(builder: (ctx) => route.build(this, ctx)),
        ),
      );

  @override
  UnRoutePage parseRouteFromUri(Uri uri) {
    final matches = _tree.match(uri);
    if (matches != null) return UnRoutePage(uri: uri, matches: matches);

    final fallback = _tree.matchFallback(uri);
    if (fallback != null) return UnRoutePage(uri: uri, matches: fallback);

    throw StateError('No route matched for ${uri.path}');
  }

  static Uri _normalize(String path) =>
      path.startsWith('/') ? Uri.parse(path) : Uri.parse('/$path');
}

/// Scope to expose router + snapshot.
class RouterScope extends flutter.InheritedWidget {
  const RouterScope({
    super.key,
    required this.router,
    required this.route,
    required super.child,
  });

  final Unrouter router;
  final RouteSnapshot route;

  static RouterScope of(flutter.BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RouterScope>();
    if (scope == null) {
      throw StateError('RouterView must be under RouterScope');
    }
    return scope;
  }

  @override
  @override
  bool updateShouldNotify(RouterScope oldWidget) =>
      route.uri != oldWidget.route.uri ||
      route.matches.length != oldWidget.route.matches.length;
}

/// Render the matched component at the current depth.
class RouterView extends flutter.StatelessWidget {
  const RouterView({super.key});

  @override
  flutter.Widget build(flutter.BuildContext context) {
    final scope = RouterScope.of(context);
    final currentDepth = _DepthMarker.currentDepth(context);

    if (currentDepth >= scope.route.matches.length) {
      return const flutter.SizedBox.shrink();
    }

    final match = scope.route.matches[currentDepth];
    final component = match.route.factory();

    return RouterScope(
      router: scope.router,
      route: scope.route,
      child: _DepthMarker(depth: currentDepth + 1, child: component),
    );
  }
}

/// Tracks depth for nested RouterView.
class _DepthMarker extends flutter.InheritedWidget {
  const _DepthMarker({required this.depth, required super.child});
  final int depth;

  static int currentDepth(flutter.BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DepthMarker>()?.depth ?? 0;

  @override
  bool updateShouldNotify(_DepthMarker oldWidget) => depth != oldWidget.depth;
}

// ---------------------------------------------------------------------------
// Hooks-style helpers
// ---------------------------------------------------------------------------

Unrouter useRouter(flutter.BuildContext context) =>
    RouterScope.of(context).router;

RouteSnapshot useRoute(flutter.BuildContext context) =>
    RouterScope.of(context).route;

Map<String, String> useRouterParams(flutter.BuildContext context) =>
    useRoute(context).params;

Map<String, String> useQueryParams(flutter.BuildContext context) =>
    useRoute(context).query;

// ---------------------------------------------------------------------------
// zenrouter page wrapper
// ---------------------------------------------------------------------------

class UnRoutePage extends zenrouter.RouteTarget with zenrouter.RouteUnique {
  UnRoutePage({required this.uri, required List<RouteMatch> matches})
    : matches = List.unmodifiable(matches);

  final Uri uri;
  final List<RouteMatch> matches;

  @override
  @override
  List<Object?> get props => [uri.toString()];

  @override
  flutter.Widget build(
    covariant zenrouter.Coordinator coordinator,
    flutter.BuildContext context,
  ) {
    final snapshot = RouteSnapshot(uri: uri, matches: matches);
    return RouterScope(
      router: coordinator as Unrouter,
      route: snapshot,
      child: const RouterView(),
    );
  }

  @override
  Uri toUri() => uri;
}

// ---------------------------------------------------------------------------
// Route tree + matcher
// ---------------------------------------------------------------------------

class _RouteTree {
  _RouteTree(List<Route> roots)
    : roots = roots.map(_RouteNode.fromRoute).toList() {
    _catchAll = _findCatchAll(this.roots);
  }

  final List<_RouteNode> roots;
  late final _RouteNode? _catchAll;

  List<RouteMatch>? match(Uri uri) {
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    for (final root in roots) {
      final result = _matchNode(root, segments, 0);
      if (result != null && result.consumed == segments.length) {
        return result.matches;
      }
    }
    return null;
  }

  List<RouteMatch>? matchFallback(Uri uri) {
    if (_catchAll == null) return null;
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    final result = _matchNode(_catchAll, segments, 0);
    return result?.matches;
  }

  _MatchResult? _matchNode(_RouteNode node, List<String> segments, int index) {
    var cursor = index;
    final params = <String, String>{};

    for (final seg in node.segments) {
      if (seg.isWildcard) {
        if (cursor < segments.length) {
          params['pathMatch'] = segments.skip(cursor).join('/');
        }
        cursor = segments.length;
        break;
      }
      if (cursor >= segments.length) return null;

      final current = segments[cursor];
      if (seg.isParam) {
        params[seg.name] = current;
      } else if (seg.value != current) {
        return null;
      }
      cursor += 1;
    }

    final match = RouteMatch(node.route, params);
    if (node.children.isEmpty) {
      return _MatchResult(cursor, [match]);
    }

    for (final child in node.children) {
      final childResult = _matchNode(child, segments, cursor);
      if (childResult != null && childResult.consumed <= segments.length) {
        return _MatchResult(childResult.consumed, [
          match,
          ...childResult.matches,
        ]);
      }
    }

    if (cursor == segments.length || node.hasWildcard) {
      return _MatchResult(cursor, [match]);
    }
    return null;
  }

  _RouteNode? _findCatchAll(List<_RouteNode> nodes) {
    for (final node in nodes) {
      if (node.isCatchAll) return node;
      final child = _findCatchAll(node.children);
      if (child != null) return child;
    }
    return null;
  }
}

class _RouteNode {
  _RouteNode(this.route, this.segments, this.children);

  factory _RouteNode.fromRoute(Route route) {
    final parsed = _parseSegments(route.path);
    final nestedNodes = route.children.map(_RouteNode.fromRoute).toList();
    return _RouteNode(route, parsed, nestedNodes);
  }

  final Route route;
  final List<_Segment> segments;
  final List<_RouteNode> children;

  bool get isCatchAll => segments.length == 1 && segments.first.isWildcard;

  bool get hasWildcard => segments.any((e) => e.isWildcard);
}

class _Segment {
  _Segment(this.value, {this.isParam = false, this.isWildcard = false});

  final String value;
  final bool isParam;
  final bool isWildcard;

  String get name => value.replaceFirst(':', '');
}

List<_Segment> _parseSegments(String path) {
  if (path == '/' || path.isEmpty) return const [];
  final normalized = path.startsWith('/') ? path.substring(1) : path;
  if (normalized.isEmpty) return const [];

  return normalized.split('/').map((part) {
    if (part == '**') return _Segment(part, isWildcard: true);
    if (part.startsWith(':')) return _Segment(part, isParam: true);
    return _Segment(part);
  }).toList();
}

class _MatchResult {
  _MatchResult(this.consumed, this.matches);

  final int consumed;
  final List<RouteMatch> matches;
}
