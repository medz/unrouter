extension type const RouteParams(Map<String, String> _)
    implements Map<String, String> {
  String required(String name) {
    return switch (_[name]) {
      String value => value,
      _ => throw ArgumentError('Required parameter "$name" not found', name),
    };
  }
}
