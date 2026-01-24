import 'dart:io';

import 'package:path/path.dart' as p;

class RouteEntry {
  const RouteEntry({required this.path, required this.file});

  final String path;
  final String file;
}

List<RouteEntry> scanPages(
  Directory pagesDirectory, {
  required String rootDir,
}) {
  final entries = <RouteEntry>[];
  for (final entity in pagesDirectory.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final relative = p.relative(entity.path, from: pagesDirectory.path);
    final withoutExt = relative.substring(0, relative.length - 5);
    final segments = p.split(withoutExt);
    if (segments.isEmpty) continue;

    final pathSegments = <String>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment == 'index' && i == segments.length - 1) {
        continue;
      }
      final dynamic = _parseDynamicSegment(segment);
      if (dynamic != null) {
        pathSegments.add(dynamic);
        continue;
      }
      pathSegments.add(segment);
    }

    final path = pathSegments.isEmpty ? '/' : '/${pathSegments.join('/')}';
    final filePath = _relativeOrAbsolute(entity.path, rootDir);
    entries.add(RouteEntry(path: path, file: filePath));
  }

  entries.sort((a, b) => a.path.compareTo(b.path));
  return entries;
}

String _relativeOrAbsolute(String filePath, String rootDir) {
  if (p.isWithin(rootDir, filePath) || p.equals(rootDir, filePath)) {
    return p.relative(filePath, from: rootDir);
  }
  return p.normalize(filePath);
}

String? _parseDynamicSegment(String segment) {
  if (segment.startsWith('[') && segment.endsWith(']')) {
    final inner = segment.substring(1, segment.length - 1);
    if (inner.startsWith('...') && inner.length > 3) {
      return '*';
    }
    if (inner.isNotEmpty) {
      return ':$inner';
    }
  }
  return null;
}
