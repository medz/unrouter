import '../route.dart';

class RouteTree {
  RouteTree(List<Route> roots)
    : roots = roots.map(RouteNode.fromRoute).toList() {
    _catchAll = _findCatchAll(this.roots);
  }

  final List<RouteNode> roots;
  late final RouteNode? _catchAll;

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

  MatchResult? _matchNode(RouteNode node, List<String> segments, int index) {
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
      return MatchResult(cursor, [match]);
    }

    MatchResult? best;
    for (final child in node.children) {
      final childResult = _matchNode(child, segments, cursor);
      if (childResult != null && childResult.consumed <= segments.length) {
        final combined = MatchResult(childResult.consumed, [
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
      return MatchResult(cursor, [match]);
    }
    return null;
  }

  RouteNode? _findCatchAll(List<RouteNode> nodes) {
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
          throw StateError(
            'Missing param "${seg.name}" for route name "$name"',
          );
        }
        parts.add(value);
      } else if (seg.value.isNotEmpty) {
        parts.add(seg.value);
      }
    }
    return '/${parts.join('/')}';
  }

  List<Segment>? _findByName(
    List<RouteNode> nodes,
    List<Segment> acc,
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

class RouteNode {
  RouteNode(this.route, this.segments, this.children);

  factory RouteNode.fromRoute(Route route) {
    final parsed = _parseSegments(route.path);
    final nestedNodes = route.children.map(RouteNode.fromRoute).toList();
    return RouteNode(route, parsed, nestedNodes);
  }

  final Route route;
  final List<Segment> segments;
  final List<RouteNode> children;

  bool get isCatchAll => segments.length == 1 && segments.first.isWildcard;

  bool get hasWildcard => segments.any((e) => e.isWildcard);
}

class Segment {
  Segment(this.value, {this.isParam = false, this.isWildcard = false});

  final String value;
  final bool isParam;
  final bool isWildcard;

  String get name => value.replaceFirst(':', '');
}

List<Segment> _parseSegments(String path) {
  if (path == '/' || path.isEmpty) return const [];
  final normalized = path.startsWith('/') ? path.substring(1) : path;
  if (normalized.isEmpty) return const [];

  return normalized.split('/').map((part) {
    if (part == '**') return Segment(part, isWildcard: true);
    if (part.startsWith(':')) return Segment(part, isParam: true);
    return Segment(part);
  }).toList();
}

class MatchResult {
  MatchResult(this.consumed, this.matches);

  final int consumed;
  final List<RouteMatch> matches;
}
