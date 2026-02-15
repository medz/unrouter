/// Typed helpers over matched route params.
extension type const RouteParams(Map<String, String> _)
    implements Map<String, String> {
  /// Returns a required param value.
  ///
  /// Throws an [ArgumentError] when [name] is missing.
  String required(String name) {
    return switch (_[name]) {
      String value => value,
      _ => throw ArgumentError('Required parameter "$name" not found', name),
    };
  }

  /// Decodes and transforms a required param value.
  ///
  /// The raw value is passed through [Uri.decodeComponent] before [fn].
  /// Throws an [ArgumentError] when [name] is missing.
  T decode<T>(String name, T Function(String value) fn) {
    return fn(Uri.decodeComponent(required(name)));
  }

  /// Parses a required param as `int`.
  int $int(String name) {
    return decode<int>(name, int.parse);
  }

  /// Parses a required param as `num`.
  num $num(String name) {
    return decode<num>(name, num.parse);
  }

  /// Parses a required param as `double`.
  double $double(String name) {
    return decode<double>(name, double.parse);
  }

  /// Parses a required param as an enum value by `Enum.name`.
  ///
  /// Throws an [ArgumentError] when [name] is missing or the value does not
  /// match one of [values].
  T $enum<T extends Enum>(String name, Iterable<T> values) {
    return decode<T>(name, (value) {
      for (final item in values) {
        if (item.name == value) {
          return item;
        }
      }
      throw ArgumentError.value(
        value,
        name,
        'Invalid enum value "$value". Expected one of: '
        '${values.map((item) => item.name).join(', ')}.',
      );
    });
  }
}
