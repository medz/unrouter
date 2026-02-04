import 'dart:io';

import 'package:path/path.dart' as p;

class RouteEntry {
  const RouteEntry({
    required this.path,
    required this.file,
    required this.treeSegments,
    required this.pathSegments,
    required this.isIndex,
  });

  final String path;
  final String file;
  final List<String> treeSegments;
  final List<String> pathSegments;
  final bool isIndex;
}

const String _indexToken = r'$index';

List<RouteEntry> scanPages(
  Directory pagesDirectory, {
  required String rootDir,
  void Function(String message)? onError,
}) {
  final entries = <RouteEntry>[];
  for (final entity in pagesDirectory.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final relative = p.relative(entity.path, from: pagesDirectory.path);
    final withoutExt = relative.substring(0, relative.length - 5);
    final segments = p.split(withoutExt);
    if (segments.isEmpty) continue;

    final treeSegments = <String>[];
    final pathSegments = <String>[];
    final isIndex = segments.last == 'index';
    var invalidSegment = false;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment == 'index' && i == segments.length - 1) {
        treeSegments.add(_indexToken);
        continue;
      }
      if (_isGroupSegment(segment)) {
        final groupName = segment.substring(1, segment.length - 1).trim();
        if (groupName.isEmpty) {
          onError?.call(
            'Invalid group segment "()" in ${_relativeOrAbsolute(entity.path, rootDir)}. Use a non-empty name, e.g. "(auth)".',
          );
          invalidSegment = true;
          break;
        }
        treeSegments.add(segment);
        continue;
      }
      if (segment == '[]') {
        onError?.call(
          'Invalid dynamic segment "[]" in ${_relativeOrAbsolute(entity.path, rootDir)}. Use [name] or [...name].',
        );
        invalidSegment = true;
        break;
      }
      final dynamic = _parseDynamicSegment(segment);
      if (dynamic != null) {
        treeSegments.add(dynamic);
        pathSegments.add(dynamic);
        continue;
      }
      treeSegments.add(segment);
      pathSegments.add(segment);
    }
    if (invalidSegment) {
      continue;
    }

    final path = pathSegments.join('/');
    final filePath = _relativeOrAbsolute(entity.path, rootDir);
    entries.add(
      RouteEntry(
        path: path,
        file: filePath,
        treeSegments: treeSegments,
        pathSegments: pathSegments,
        isIndex: isIndex,
      ),
    );
  }

  entries.sort((a, b) {
    final pathCompare = a.path.compareTo(b.path);
    if (pathCompare != 0) return pathCompare;
    final treeA = _treeKey(a.treeSegments);
    final treeB = _treeKey(b.treeSegments);
    return treeA.compareTo(treeB);
  });
  return entries;
}

String _relativeOrAbsolute(String filePath, String rootDir) {
  if (p.isWithin(rootDir, filePath) || p.equals(rootDir, filePath)) {
    return p.relative(filePath, from: rootDir);
  }
  return p.normalize(filePath);
}

bool _isGroupSegment(String segment) {
  return segment.startsWith('(') && segment.endsWith(')');
}

String _treeKey(List<String> segments) {
  if (segments.isEmpty) return '';
  return segments.join('/');
}

String? _parseDynamicSegment(String segment) {
  if (segment.startsWith('[') && segment.endsWith(']')) {
    final inner = segment.substring(1, segment.length - 1);
    if (inner == '...') {
      return '**';
    }
    if (inner.startsWith('...') && inner.length > 3) {
      final name = inner.substring(3);
      return '**:$name';
    }
    if (inner.isNotEmpty) {
      return ':$inner';
    }
  }
  return null;
}
