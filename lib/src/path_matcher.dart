/// Path matching utilities for route resolution.
library;

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
class PathMatch {
  const PathMatch({
    required this.matched,
    required this.params,
    required this.remaining,
  });

  /// Whether the pattern matched the path.
  final bool matched;

  /// Extracted path parameters (e.g., `{id: '123'}`).
  final Map<String, String> params;

  /// Remaining path segments after matching.
  final List<String> remaining;

  /// Creates a failed match.
  static const PathMatch noMatch = PathMatch(
    matched: false,
    params: {},
    remaining: [],
  );
}

/// Matches a path pattern against a path.
///
/// Supports:
/// - Static segments: `'about'`, `'users/profile'`
/// - Dynamic params: `':id'`, `':userId'`
/// - Optional params: `':id?'`
/// - Optional segments: `'edit?'`
/// - Wildcard: `'*'`
///
/// Returns [PathMatch] with:
/// - `matched`: whether the pattern matched
/// - `params`: extracted parameters
/// - `remaining`: unconsumed path segments
PathMatch matchPath(String? pattern, List<String> pathSegments) {
  final normalizedPattern = normalizePath(pattern);

  // Index route matches empty path
  if (normalizedPattern.isEmpty) {
    return PathMatch(
      matched: pathSegments.isEmpty,
      params: const {},
      remaining: pathSegments,
    );
  }

  final patternSegments = splitPath(normalizedPattern);
  final params = <String, String>{};
  var pathIndex = 0;

  for (var i = 0; i < patternSegments.length; i++) {
    final patternSegment = patternSegments[i];

    // Wildcard: match everything remaining
    if (patternSegment == '*') {
      return PathMatch(
        matched: true,
        params: params,
        remaining: [], // Wildcard consumes all remaining segments
      );
    }

    // No more path segments to match
    if (pathIndex >= pathSegments.length) {
      // Check if remaining pattern segments are all optional
      final remainingOptional = patternSegments
          .skip(i)
          .every((s) => s.endsWith('?'));

      if (remainingOptional) {
        return PathMatch(matched: true, params: params, remaining: []);
      }

      return PathMatch.noMatch;
    }

    final pathSegment = pathSegments[pathIndex];

    // Optional segment
    if (patternSegment.endsWith('?')) {
      final segmentWithoutQuestion = patternSegment.substring(
        0,
        patternSegment.length - 1,
      );

      // Dynamic optional param: `:id?`
      if (segmentWithoutQuestion.startsWith(':')) {
        final paramName = segmentWithoutQuestion.substring(1);

        // Try to match - if next pattern segment matches current path segment,
        // then this optional param should be skipped
        if (i + 1 < patternSegments.length) {
          final nextPattern = patternSegments[i + 1];
          if (!nextPattern.startsWith(':') && nextPattern == pathSegment) {
            // Skip this optional param
            continue;
          }
        }

        // Otherwise, consume this segment as the param
        params[paramName] = pathSegment;
        pathIndex++;
        continue;
      }

      // Static optional segment: `edit?`
      if (segmentWithoutQuestion == pathSegment) {
        pathIndex++;
      }
      // If not matched, it's optional so just continue
      continue;
    }

    // Dynamic param: `:id`
    if (patternSegment.startsWith(':')) {
      final paramName = patternSegment.substring(1);
      params[paramName] = pathSegment;
      pathIndex++;
      continue;
    }

    // Static segment: must match exactly
    if (patternSegment == pathSegment) {
      pathIndex++;
      continue;
    }

    // No match
    return PathMatch.noMatch;
  }

  // Return matched with remaining path segments
  return PathMatch(
    matched: true,
    params: params,
    remaining: pathSegments.sublist(pathIndex),
  );
}
