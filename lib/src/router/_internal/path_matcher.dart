import 'package:roux/roux.dart' show routeToRegExp;

/// Normalizes a path by removing leading/trailing slashes and empty segments.
///
/// Examples:
/// - `'/'` -> `''`
/// - `'/about/'` -> `'about'`
/// - `'a//b'` -> `'a/b'`
/// - `null` -> `''`
String normalizePath(String? path) {
  if (path == null || path.isEmpty || path == '/') {
    return '';
  }

  // Remove leading and trailing slashes
  var normalized = path.trim();
  if (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }
  if (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  // Remove empty segments (consecutive slashes)
  final segments = normalized.split('/').where((s) => s.isNotEmpty);
  return segments.join('/');
}

/// Splits a path into segments.
List<String> splitPath(String path) {
  final normalized = normalizePath(path);
  if (normalized.isEmpty) {
    return [];
  }
  return normalized.split('/');
}

/// Result of a path match.
class PathSpecificity {
  const PathSpecificity({
    this.staticCount = 0,
    this.dynamicCount = 0,
    this.wildcardCount = 0,
  });

  final int staticCount;
  final int dynamicCount;
  final int wildcardCount;

  PathSpecificity operator +(PathSpecificity other) => PathSpecificity(
    staticCount: staticCount + other.staticCount,
    dynamicCount: dynamicCount + other.dynamicCount,
    wildcardCount: wildcardCount + other.wildcardCount,
  );

  int compareTo(PathSpecificity other) {
    if (staticCount != other.staticCount) {
      return staticCount.compareTo(other.staticCount);
    }
    if (dynamicCount != other.dynamicCount) {
      return dynamicCount.compareTo(other.dynamicCount);
    }
    if (wildcardCount != other.wildcardCount) {
      // Fewer wildcards is more specific.
      return other.wildcardCount.compareTo(wildcardCount);
    }
    return 0;
  }
}

class PathMatch {
  const PathMatch({
    required this.matched,
    required this.params,
    required this.remaining,
    this.specificity = const PathSpecificity(),
  });

  /// Whether the pattern matched the path.
  final bool matched;

  /// Extracted path parameters (e.g., `{id: '123'}`).
  final Map<String, String> params;

  /// Remaining path segments after matching.
  final List<String> remaining;

  /// Specificity of the matched pattern segments.
  final PathSpecificity specificity;

  /// Creates a failed match.
  static const PathMatch noMatch = PathMatch(
    matched: false,
    params: {},
    remaining: [],
  );
}

final Map<String, RegExp> _routeRegexCache = <String, RegExp>{};

String normalizePattern(String? pattern) {
  final normalized = normalizePath(pattern);
  if (normalized.isEmpty) return '';
  return normalized.replaceAll(r'\:', '%3A');
}

RegExp _routeRegexFor(String normalizedPattern) {
  final pattern = normalizedPattern.isEmpty ? '/' : '/$normalizedPattern';
  return _routeRegexCache.putIfAbsent(pattern, () => routeToRegExp(pattern));
}

PathSpecificity _patternSpecificity(List<String> segments) {
  var staticCount = 0;
  var dynamicCount = 0;
  var wildcardCount = 0;

  for (final segment in segments) {
    if (segment == r'\*' || segment == r'\*\*') {
      staticCount += 1;
      continue;
    }
    if (segment.startsWith('**') || segment == '*') {
      wildcardCount += 1;
      continue;
    }
    if (segment.contains(':')) {
      dynamicCount += 1;
      continue;
    }
    staticCount += 1;
  }

  return PathSpecificity(
    staticCount: staticCount,
    dynamicCount: dynamicCount,
    wildcardCount: wildcardCount,
  );
}

/// Matches a path pattern against a path.
///
/// Supports:
/// - Static segments: `'about'`, `'users/profile'`
/// - Dynamic params: `':id'`, `':userId'`
/// - Embedded params: `'/files/:name.:ext'`
/// - Single-segment wildcard: `'*'`
/// - Multi-segment wildcard: `'**'`, `'**:path'`
///
/// Returns [PathMatch] with:
/// - `matched`: whether the pattern matched
/// - `params`: extracted parameters
/// - `remaining`: unconsumed path segments
PathMatch matchPath(String? pattern, List<String> pathSegments) {
  final normalizedPattern = normalizePattern(pattern);
  if (normalizedPattern.contains('?')) {
    return PathMatch.noMatch;
  }

  // Index route matches empty path
  if (normalizedPattern.isEmpty) {
    return PathMatch(
      matched: pathSegments.isEmpty,
      params: const {},
      remaining: pathSegments,
      specificity: const PathSpecificity(),
    );
  }

  final patternSegments = splitPath(normalizedPattern);
  final hasMultiWildcard = patternSegments.any((segment) {
    if (segment == r'\*\*') return false;
    return segment.startsWith('**');
  });

  List<String> matchedSegments;
  List<String> remainingSegments;
  if (hasMultiWildcard) {
    matchedSegments = pathSegments;
    remainingSegments = const [];
  } else {
    if (pathSegments.length < patternSegments.length) {
      return PathMatch.noMatch;
    }
    matchedSegments = pathSegments.sublist(0, patternSegments.length);
    remainingSegments = pathSegments.sublist(patternSegments.length);
  }

  final candidatePath =
      matchedSegments.isEmpty ? '/' : '/${matchedSegments.join('/')}';
  final regex = _routeRegexFor(normalizedPattern);
  final match = regex.firstMatch(candidatePath);
  if (match == null) {
    return PathMatch.noMatch;
  }

  final params = <String, String>{};
  for (final name in match.groupNames) {
    final value = match.namedGroup(name);
    if (value != null) {
      params[name] = value;
    }
  }

  return PathMatch(
    matched: true,
    params: params,
    remaining: remainingSegments,
    specificity: _patternSpecificity(patternSegments),
  );
}
