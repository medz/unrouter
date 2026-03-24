/// Typed helpers for matched route params.
///
/// Route params are captured from a matched path pattern (for example `:id`
/// or `*`) and exposed as a `Map<String, String>` with convenience decoders.
extension type const RouteParams(Map<String, String> _)
    implements Map<String, String> {
  /// Returns the required raw param value for [name].
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  String required(String name) {
    return switch (_[name]) {
      String value => value,
      _ => throw ArgumentError('Required parameter "$name" not found', name),
    };
  }

  /// Decodes and transforms the required param value for [name].
  ///
  /// The raw value is first passed through [Uri.decodeComponent], then sent to
  /// [fn] for conversion.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Any exception thrown by [fn] is rethrown to the caller.
  ///
  /// Example:
  /// ```dart
  /// final params = RouteParams({'id': '42', 'slug': 'hello%20world'});
  /// final id = params.decode('id', int.parse); // 42
  /// final slug = params.decode('slug', (value) => value); // hello world
  /// ```
  T decode<T>(String name, T Function(String value) fn) {
    return fn(Uri.decodeComponent(required(name)));
  }

  /// Parses the required param value for [name] as `int`.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Throws a [FormatException] if the decoded value is not a valid integer.
  int $int(String name) {
    return decode<int>(name, int.parse);
  }

  /// Parses the required param value for [name] as `num`.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Throws a [FormatException] if the decoded value is not numeric.
  num $num(String name) {
    return decode<num>(name, num.parse);
  }

  /// Parses the required param value for [name] as `double`.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Throws a [FormatException] if the decoded value is not a valid double.
  double $double(String name) {
    return decode<double>(name, double.parse);
  }

  /// Parses the required param value for [name] as an enum by `Enum.name`.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Throws an [ArgumentError] if the decoded value does not match [values].
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
