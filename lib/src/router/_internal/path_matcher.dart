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

/// Matches a path pattern against a path.
///
/// Supports:
/// - Static segments: `'about'`, `'users/profile'`
/// - Dynamic params: `':id'`, `':userId'`
/// - Optional params: `':id?'`
/// - Optional segments: `'edit?'`
/// - Wildcard: `'*'`, `'*name'`
///
/// Returns [PathMatch] with:
/// - `matched`: whether the pattern matched
/// - `params`: extracted parameters
/// - `remaining`: unconsumed path segments
PathMatch matchPath(String? pattern, List<String> pathSegments) {
  final normalizedPattern = normalizePath(pattern);
  var staticCount = 0;
  var dynamicCount = 0;
  var wildcardCount = 0;

  // Index route matches empty path
  if (normalizedPattern.isEmpty) {
    return PathMatch(
      matched: pathSegments.isEmpty,
      params: const {},
      remaining: pathSegments,
      specificity: PathSpecificity(
        staticCount: staticCount,
        dynamicCount: dynamicCount,
        wildcardCount: wildcardCount,
      ),
    );
  }

  final patternSegments = splitPath(normalizedPattern);
  final params = <String, String>{};
  var pathIndex = 0;

  for (var i = 0; i < patternSegments.length; i++) {
    final patternSegment = patternSegments[i];

    // Wildcard: match everything remaining
    if (patternSegment.startsWith('*')) {
      wildcardCount += 1;
      final name = patternSegment.substring(1);
      final value = pathSegments.sublist(pathIndex).join('/');
      if (name.isEmpty) {
        params['*'] = value;
      } else {
        params[name] = value;
      }
      return PathMatch(
        matched: true,
        params: params,
        remaining: [], // Wildcard consumes all remaining segments
        specificity: PathSpecificity(
          staticCount: staticCount,
          dynamicCount: dynamicCount,
          wildcardCount: wildcardCount,
        ),
      );
    }

    // No more path segments to match
    if (pathIndex >= pathSegments.length) {
      // Check if remaining pattern segments are all optional
      final remainingOptional = patternSegments
          .skip(i)
          .every((s) => s.endsWith('?'));

      if (remainingOptional) {
        return PathMatch(
          matched: true,
          params: params,
          remaining: [],
          specificity: PathSpecificity(
            staticCount: staticCount,
            dynamicCount: dynamicCount,
            wildcardCount: wildcardCount,
          ),
        );
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
        dynamicCount += 1;
        pathIndex++;
        continue;
      }

      // Static optional segment: `edit?`
      if (segmentWithoutQuestion == pathSegment) {
        staticCount += 1;
        pathIndex++;
      }
      // If not matched, it's optional so just continue
      continue;
    }

    // Dynamic param: `:id`
    if (patternSegment.startsWith(':')) {
      final paramName = patternSegment.substring(1);
      params[paramName] = pathSegment;
      dynamicCount += 1;
      pathIndex++;
      continue;
    }

    // Static segment: must match exactly
    if (patternSegment == pathSegment) {
      staticCount += 1;
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
    specificity: PathSpecificity(
      staticCount: staticCount,
      dynamicCount: dynamicCount,
      wildcardCount: wildcardCount,
    ),
  );
}
