/// Normalizes path fragments into a canonical absolute path.
///
/// Empty fragments and duplicate slashes are removed, then the remaining
/// segments are joined with single `/` separators.
///
/// Returns `'/'` when all fragments are empty.
///
/// This helper is used internally for route declaration flattening and
/// navigation target normalization.
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
