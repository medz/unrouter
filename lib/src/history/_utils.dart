String normalizeBase(String base) {
  base = Uri.parse(base).path;
  return base.isEmpty ? '/' : base;
}

String createHref(String base, String location) {
  final index = base.indexOf('#');
  base = index != -1 ? base.substring(0, index) : base;
  return base + location;
}
