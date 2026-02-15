extension type const RouteParams(Map<String, String> _)
    implements Map<String, String> {
  String required(String name) {
    return switch (_[name]) {
      String value => value,
      _ => throw ArgumentError('Required parameter "$name" not found', name),
    };
  }

  T decode<T>(String name, T Function(String value) fn) {
    return fn(Uri.decodeComponent(required(name)));
  }
}
