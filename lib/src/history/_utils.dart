String normalizeBase(String base) {
  base = Uri.parse(base).path;
  if (base.isEmpty) return '/';

  // Remove trailing slash unless it's the root path
  if (base != '/' && base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }

  return base;
}

String createHref(String base, String location) {
  final index = base.indexOf('#');
  base = index != -1 ? base.substring(0, index) : base;

  // If base is root '/', don't duplicate the slash
  if (base == '/' && location.startsWith('/')) {
    return location;
  }

  // Ensure location starts with /
  if (!location.startsWith('/')) {
    location = '/$location';
  }

  return base + location;
}
