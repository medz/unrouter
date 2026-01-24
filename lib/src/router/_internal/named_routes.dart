import 'package:flutter/foundation.dart';

import '../inlet.dart';
import 'path_matcher.dart';

class NamedRouteResolver {
  NamedRouteResolver(Iterable<Inlet>? routes)
    : _routes = routes,
      _entries = routes == null ? const {} : _collectNamedRoutes(routes);

  final Iterable<Inlet>? _routes;
  final Map<String, _NamedRouteEntry> _entries;

  Uri resolve(
    String name, {
    Map<String, String> params = const {},
    Map<String, String>? queryParameters,
    String? fragment,
  }) {
    if (_routes == null) {
      throw FlutterError(
        'Named routes require declarative routes (Unrouter.routes).\n'
        'No routes were provided to Unrouter.',
      );
    }

    final entry = _entries[name];
    if (entry == null) {
      final available = _entries.keys.toList()..sort();
      final hint = available.isEmpty
          ? 'No route names are defined.'
          : 'Available names: ${available.join(', ')}.';
      throw FlutterError('Unknown route name "$name". $hint');
    }

    final path = _buildPath(name, entry.pattern, params);
    return Uri(
      path: path,
      queryParameters:
          queryParameters != null && queryParameters.isNotEmpty
              ? queryParameters
              : null,
      fragment: fragment != null && fragment.isNotEmpty ? fragment : null,
    );
  }
}

class _NamedRouteEntry {
  const _NamedRouteEntry({
    required this.pattern,
  });

  final String pattern;
}

Map<String, _NamedRouteEntry> _collectNamedRoutes(Iterable<Inlet> routes) {
  final entries = <String, _NamedRouteEntry>{};

  void visit(Inlet route, String basePattern) {
    final pattern = _joinPattern(basePattern, route.path);

    final name = route.name;
    if (name != null) {
      if (name.isEmpty) {
        throw FlutterError(
          'Route names must not be empty.\n'
          'Found an empty name on route with path "${route.path}".',
        );
      }
      final existing = entries[name];
      if (existing != null) {
        throw FlutterError(
          'Duplicate route name "$name".\n'
          'Route names must be unique.\n'
          'Existing: "${existing.pattern}", New: "$pattern".',
        );
      }
      entries[name] = _NamedRouteEntry(
        pattern: pattern,
      );
    }

    if (route.children.isEmpty) return;
    for (final child in route.children) {
      visit(child, pattern);
    }
  }

  for (final route in routes) {
    visit(route, '');
  }

  return entries;
}

String _joinPattern(String base, String segment) {
  final normalizedSegment = normalizePath(segment);
  if (normalizedSegment.isEmpty) return base;
  if (base.isEmpty) return normalizedSegment;
  return '$base/$normalizedSegment';
}

String _buildPath(String name, String pattern, Map<String, String> params) {
  final segments = splitPath(pattern);
  if (segments.isEmpty) return '/';

  final resolved = <String>[];
  for (final rawSegment in segments) {
    if (rawSegment == '*') {
      final wildcardValue = params['*'];
      if (wildcardValue == null || wildcardValue.isEmpty) {
        break;
      }
      final wildcardSegments = splitPath(wildcardValue);
      if (wildcardSegments.isNotEmpty) {
        resolved.addAll(wildcardSegments);
      } else {
        resolved.add(wildcardValue);
      }
      break;
    }

    final isOptional = rawSegment.endsWith('?');
    final segment = isOptional
        ? rawSegment.substring(0, rawSegment.length - 1)
        : rawSegment;

    if (segment.startsWith(':')) {
      final paramName = segment.substring(1);
      final value = params[paramName];
      if (value == null || value.isEmpty) {
        if (isOptional) {
          continue;
        }
        throw FlutterError(
          'Missing param "$paramName" for route "$name".\n'
          'Pattern: "$pattern".',
        );
      }
      resolved.add(value);
      continue;
    }

    if (isOptional) {
      resolved.add(segment);
      continue;
    }

    resolved.add(segment);
  }

  if (resolved.isEmpty) return '/';
  return '/${resolved.join('/')}';
}
