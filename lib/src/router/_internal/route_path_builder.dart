import 'package:flutter/foundation.dart';

import 'path_matcher.dart';

String buildPathFromPattern({
  required String pattern,
  required Map<String, String> params,
  required String label,
}) {
  if (pattern.contains('?')) {
    throw FlutterError(
      'Optional segments are not supported.\n'
      'Pattern: "$pattern".',
    );
  }

  final normalizedPattern = normalizePattern(pattern);
  final segments = splitPath(normalizedPattern);
  if (segments.isEmpty) return '';

  final resolved = <String>[];
  var unnamedWildcardIndex = 0;
  final paramToken = RegExp(r':(\w+)');
  for (final rawSegment in segments) {
    if (rawSegment.startsWith('**')) {
      final paramName =
          rawSegment == '**'
              ? '_'
              : (rawSegment.length > 3 ? rawSegment.substring(3) : '');
      final wildcardValue = params[paramName];
      if (paramName.isEmpty) {
        throw FlutterError(
          'Missing param for wildcard in route "$label".\n'
          'Pattern: "$pattern".',
        );
      }
      if ((wildcardValue == null || wildcardValue.isEmpty) && paramName != '_') {
        throw FlutterError(
          'Missing param "$paramName" for route "$label".\n'
          'Pattern: "$pattern".',
        );
      }
      if (wildcardValue != null && wildcardValue.isNotEmpty) {
        final wildcardSegments = splitPath(wildcardValue);
        if (wildcardSegments.isNotEmpty) {
          for (final segment in wildcardSegments) {
            resolved.add(Uri.encodeComponent(segment));
          }
        } else {
          resolved.add(Uri.encodeComponent(wildcardValue));
        }
      }
      break;
    }

    if (rawSegment == '*') {
      final paramName = '_${unnamedWildcardIndex++}';
      final value = params[paramName];
      if (value == null || value.isEmpty) {
        throw FlutterError(
          'Missing param "$paramName" for route "$label".\n'
          'Pattern: "$pattern".',
        );
      }
      resolved.add(Uri.encodeComponent(value));
      continue;
    }

    if (rawSegment.contains(':')) {
      final segment = rawSegment.replaceAllMapped(paramToken, (match) {
        final name = match.group(1);
        if (name == null || name.isEmpty) {
          return '';
        }
        final value = params[name];
        if (value == null || value.isEmpty) {
          throw FlutterError(
            'Missing param "$name" for route "$label".\n'
            'Pattern: "$pattern".',
          );
        }
        return Uri.encodeComponent(value);
      });
      resolved.add(segment);
      continue;
    }

    resolved.add(rawSegment);
  }

  return resolved.join('/');
}
