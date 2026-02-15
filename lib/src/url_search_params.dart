import 'package:ht/ht.dart' as ht;

final Expando<bool> _parsedFromString = Expando<bool>('parsedFromString');

/// Typed helpers over `ht.URLSearchParams`.
///
/// This extension type mirrors the native API while adding strict decoding and
/// typed conversion helpers for common query parsing flows.
extension type URLSearchParams._(ht.URLSearchParams _)
    implements ht.URLSearchParams {
  /// Creates URL search params from an optional initializer.
  ///
  /// [init] accepts the same forms as `ht.URLSearchParams`, such as a query
  /// string, a map-like object, or another params instance.
  factory URLSearchParams([Object? init]) {
    final params = URLSearchParams._(ht.URLSearchParams(init));
    _parsedFromString[params._] = init is String;
    return params;
  }

  /// Returns a cloned instance with the same key-value pairs.
  URLSearchParams clone() {
    final cloned = URLSearchParams._(_.clone());
    _parsedFromString[cloned._] = _parsedFromString[_] ?? false;
    return cloned;
  }

  /// Returns the required raw query value for [name].
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  String required(String name) {
    return switch (get(name)) {
      String value => value,
      _ => throw ArgumentError('Required parameter "$name" not found', name),
    };
  }

  /// Decodes and transforms the required query value for [name].
  ///
  /// Values created from map-like initializers are first passed through
  /// [Uri.decodeComponent], then sent to [fn] for conversion.
  ///
  /// Values created from a query-string initializer are already decoded by
  /// `ht.URLSearchParams`, so this method forwards them to [fn] as-is.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Any exception thrown by [fn] is rethrown to the caller.
  ///
  /// Example:
  /// ```dart
  /// final query = URLSearchParams('page=2&tab=profile%20settings');
  /// final page = query.decode('page', int.parse); // 2
  /// final tab = query.decode('tab', (value) => value); // profile settings
  /// ```
  T decode<T>(String name, T Function(String value) fn) {
    final raw = required(name);
    final value = (_parsedFromString[_] ?? false)
        ? raw
        : Uri.decodeComponent(raw);
    return fn(value);
  }

  /// Parses the required query value for [name] as `int`.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Throws a [FormatException] if the decoded value is not a valid integer.
  int $int(String name) {
    return decode<int>(name, int.parse);
  }

  /// Parses the required query value for [name] as `num`.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Throws a [FormatException] if the decoded value is not numeric.
  num $num(String name) {
    return decode<num>(name, num.parse);
  }

  /// Parses the required query value for [name] as `double`.
  ///
  /// Throws an [ArgumentError] if [name] is not present.
  /// Throws a [FormatException] if the decoded value is not a valid double.
  double $double(String name) {
    return decode<double>(name, double.parse);
  }

  /// Parses the required query value for [name] as an enum by `Enum.name`.
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
