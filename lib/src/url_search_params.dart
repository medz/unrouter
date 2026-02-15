import 'package:ht/ht.dart' as ht;

/// Typed helpers over `ht.URLSearchParams`.
extension type URLSearchParams._(ht.URLSearchParams _)
    implements ht.URLSearchParams {
  /// Creates a search params object from optional [init].
  URLSearchParams([Object? init]) : this._(ht.URLSearchParams(init));

  /// Returns a cloned instance with the same key-value pairs.
  URLSearchParams clone() {
    return URLSearchParams._(_.clone());
  }

  /// Returns a required query value.
  ///
  /// Throws an [ArgumentError] when [name] is missing.
  String required(String name) {
    return switch (get(name)) {
      String value => value,
      _ => throw ArgumentError('Required parameter "$name" not found', name),
    };
  }

  /// Decodes and transforms a required query value.
  ///
  /// The raw value is passed through [Uri.decodeComponent] before [fn].
  /// Throws an [ArgumentError] when [name] is missing.
  T decode<T>(String name, T Function(String value) fn) {
    return fn(Uri.decodeComponent(required(name)));
  }

  /// Parses a required query value as `int`.
  int $int(String name) {
    return decode<int>(name, int.parse);
  }

  /// Parses a required query value as `num`.
  num $num(String name) {
    return decode<num>(name, num.parse);
  }

  /// Parses a required query value as `double`.
  double $double(String name) {
    return decode<double>(name, double.parse);
  }

  /// Parses a required query value as an enum value by `Enum.name`.
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
