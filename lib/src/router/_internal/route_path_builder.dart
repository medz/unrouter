import 'package:flutter/foundation.dart';

import 'path_matcher.dart';

String buildPathFromPattern({
  required String pattern,
  required Map<String, String> params,
  required String label,
}) {
  final segments = splitPath(pattern);
  if (segments.isEmpty) return '';

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
          'Missing param "$paramName" for route "$label".\n'
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

  return resolved.join('/');
}
