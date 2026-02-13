String normalizePath(Iterable<String> paths) {
  final segments = <String>[];
  for (final path in paths) {
    if (path.isEmpty) continue;
    for (final segment in path.split('/')) {
      if (segment.isEmpty) continue;
      segments.add(segment);
    }
  }

  if (segments.isEmpty) return '/';
  return '/${segments.join('/')}';
}
