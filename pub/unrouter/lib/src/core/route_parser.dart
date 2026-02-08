extension type const TypedParams(Map<String, String> _)
    implements Map<String, String> {
  String required(String key) {
    if (!containsKey(key)) {
      throw FormatException('Missing required parameter "$key".');
    }

    return this[key]!;
  }

  T decode<T>(String key, T? Function(String raw) parser) {
    return switch (parser(required(key))) {
      T value => value,
      _ => throw FormatException(
        'Route parameter "$key" failed to decode as "$T".',
      ),
    };
  }

  num $num(String key) => decode(key, num.tryParse);
  int $int(String key) => decode(key, int.tryParse);
  double $double(String key) => decode(key, double.tryParse);

  T $enum<T extends Enum>(String key, Iterable<T> values) {
    return decode(key, (name) {
      for (final e in values) {
        if (e.name == name) return e;
      }
      throw FormatException('Route parameter "$key" failed to decode as "$T".');
    });
  }
}

/// Strongly typed parser helpers built from a matched URI.
class RouteParserState {
  RouteParserState({required this.uri, required Map<String, String> params})
    : params = TypedParams(params),
      query = TypedParams(uri.queryParameters);

  final Uri uri;
  final TypedParams params;
  final TypedParams query;
}
