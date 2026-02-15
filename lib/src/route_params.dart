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

  int $int(String name) {
    return decode<int>(name, int.parse);
  }

  num $num(String name) {
    return decode<num>(name, num.parse);
  }

  double $double(String name) {
    return decode<double>(name, double.parse);
  }
}
