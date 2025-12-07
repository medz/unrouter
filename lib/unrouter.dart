import 'package:flutter/widgets.dart' as flutter;
import 'package:zenrouter/zenrouter.dart' as zenrouter;

/// Represents a navigation target.
class RouteLocation<T> {
  const RouteLocation.path(
    this.path, {
    this.state,
    this.hash,
    Map<String, String>? query,
    this.replace = false,
    this.force = false,
  }) : query = query ?? const {},
      name = null,
      params = const {};

  const RouteLocation.name(
    this.name, {
    this.params = const {},
    this.state,
    this.hash,
    Map<String, String>? query,
    this.replace = false,
    this.force = false,
  }) : path = null,
      query = query ?? const {};

  final String? path;
  final String? name;
  final Map<String, String> params;
  final T? state;
  final String? hash;
  final Map<String, String> query;
  final bool replace;
  final bool force;
}

/// Public router surface (zenrouter hidden).
abstract interface class Router {
  void back();
  void forward();
  void go(int delta);
  void push(RouteLocation location);
  void replace(RouteLocation location);

  flutter.RouterDelegate<Uri> get delegate;
  flutter.RouteInformationParser<Uri> get informationParser;
}

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

/// Internal coordinator that handles route parsing/rendering.
class _CoreCoordinator extends zenrouter.Coordinator<RoutePage> {
  _CoreCoordinator({required Iterable<Route> routes, String initialPath = '/'})
    : _tree = _RouteTree(routes.toList()),
      _initialUri = _normalize(initialPath);

  late Router router;

  final _RouteTree _tree;
  final Uri _initialUri;

  late final RoutePage _initialPage = parseRouteFromUri(_initialUri);

  /// Replace stack with [path].
  void goPath(String path) => replace(parseRouteFromUri(_normalize(path)));

  /// Push new page.
  Future<dynamic> pushPath(String path) =>
      push(parseRouteFromUri(_normalize(path)));

  @override
  flutter.Widget layoutBuilder(flutter.BuildContext context) =>
      zenrouter.NavigationStack<RoutePage>(
        path: root,
        coordinator: this,
        defaultRoute: _initialPage,
        resolver: (route) => zenrouter.StackTransition.material(
          flutter.Builder(builder: (ctx) => route.build(this, ctx)),
        ),
      );

  @override
  RoutePage parseRouteFromUri(Uri uri) {
    final matches = _tree.match(uri);
    if (matches != null) return RoutePage(uri: uri, matches: matches, router: router);

    final fallback = _tree.matchFallback(uri);
    if (fallback != null) return RoutePage(uri: uri, matches: fallback, router: router);

    throw StateError('No route matched for ${uri.path}');
  }

  String? pathForName(String name, Map<String, String> params) =>
      _tree.buildPathForName(name, params);

  static Uri _normalize(String path) =>
      path.startsWith('/') ? Uri.parse(path) : Uri.parse('/$path');
}

/// Public router facade built on top of [_CoreCoordinator].
class _RouterImpl implements Router {
  _RouterImpl({required Iterable<Route> routes, String initialPath = '/'})
    : _core = _CoreCoordinator(routes: routes, initialPath: initialPath) {
    _core.router = this;
  }

  final _CoreCoordinator _core;

  @override
  void back() => _core.pop();

  @override
  void forward() {
    // No forward stack support.
  }

  @override
  void go(int delta) {
    if (delta < 0) {
      for (int i = 0; i < delta.abs(); i++) {
        _core.pop();
      }
    } else if (delta > 0) {
      forward();
    }
  }

  @override
  void push(RouteLocation location) =>
      _core.pushPath(_locationToUri(location).toString());

  @override
  void replace(RouteLocation location) =>
      _core.goPath(_locationToUri(location).toString());

  @override
  flutter.RouterDelegate<Uri> get delegate => _core.routerDelegate;

  @override
  flutter.RouteInformationParser<Uri> get informationParser =>
      _core.routeInformationParser;

  zenrouter.Coordinator<RoutePage> _asCoordinator() => _core;

  Uri _locationToUri(RouteLocation location) {
    if (location.path != null) {
      return Uri(
        path: location.path,
        queryParameters: location.query.isEmpty
            ? null
            : Map<String, String>.from(location.query),
        fragment: location.hash,
      );
    }
    if (location.name != null) {
      final path = _core.pathForName(location.name!, location.params);
      if (path == null) {
        throw StateError('No route found with name ${location.name}');
      }
      return Uri(
        path: path,
        queryParameters: location.query.isEmpty
            ? null
            : Map<String, String>.from(location.query),
        fragment: location.hash,
      );
    }
    throw StateError('RouteLocation must have either path or name');
  }
}

/// Scope to expose router + snapshot.
class RouterScope extends flutter.InheritedWidget {
  const RouterScope({
    super.key,
    required this.router,
    required this.route,
    required super.child,
  });

  final Router router;
  final RouteSnapshot route;

  static RouterScope of(flutter.BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RouterScope>();
    if (scope == null) {
      throw StateError('RouterView must be under RouterScope');
    }
    return scope;
  }

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

Router useRouter(flutter.BuildContext context) =>
    RouterScope.of(context).router;

RouteSnapshot useRoute(flutter.BuildContext context) =>
    RouterScope.of(context).route;

Map<String, String> useRouterParams(flutter.BuildContext context) =>
    useRoute(context).params;

Map<String, String> useQueryParams(flutter.BuildContext context) =>
    useRoute(context).query;

/// Create a router instance.
Router createRouter({
  required Iterable<Route> routes,
  String initialPath = '/',
}) => _RouterImpl(routes: routes, initialPath: initialPath);

/// Access underlying zenrouter coordinator when needed.
zenrouter.Coordinator<RoutePage> toZenRouterCoordinator(Router router) {
  if (router is _RouterImpl) return router._asCoordinator();
  throw StateError('Unknown router implementation');
}

// ---------------------------------------------------------------------------
// zenrouter page wrapper
// ---------------------------------------------------------------------------

class RoutePage extends zenrouter.RouteTarget with zenrouter.RouteUnique {
  RoutePage({
    required this.uri,
    required List<RouteMatch> matches,
    required this.router,
  }) : matches = List.unmodifiable(matches);

  final Uri uri;
  final List<RouteMatch> matches;
  final Router router;

  @override
  List<Object?> get props => [uri.toString()];

  @override
  flutter.Widget build(
    covariant zenrouter.Coordinator coordinator,
    flutter.BuildContext context,
  ) {
    final snapshot = RouteSnapshot(uri: uri, matches: matches);
    return RouterScope(
      router: router,
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

    _MatchResult? best;
    for (final child in node.children) {
      final childResult = _matchNode(child, segments, cursor);
      if (childResult != null && childResult.consumed <= segments.length) {
        final combined = _MatchResult(childResult.consumed, [
          match,
          ...childResult.matches,
        ]);
        if (combined.consumed == segments.length) {
          return combined; // perfect match
        }
        if (best == null || combined.consumed > best.consumed) {
          best = combined;
        }
      }
    }

    if (best != null) return best;

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

  String? buildPathForName(String name, Map<String, String> params) {
    final segments = _findByName(roots, const [], name);
    if (segments == null) return null;
    final parts = <String>[];
    for (final seg in segments) {
      if (seg.isWildcard) continue;
      if (seg.isParam) {
        final value = params[seg.name];
        if (value == null) {
          throw StateError('Missing param "${seg.name}" for route name "$name"');
        }
        parts.add(value);
      } else if (seg.value.isNotEmpty) {
        parts.add(seg.value);
      }
    }
    return '/${parts.join('/')}';
  }

  List<_Segment>? _findByName(
    List<_RouteNode> nodes,
    List<_Segment> acc,
    String name,
  ) {
    for (final node in nodes) {
      final combined = [...acc, ...node.segments];
      if (node.route.name == name) return combined;
      final child = _findByName(node.children, combined, name);
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
