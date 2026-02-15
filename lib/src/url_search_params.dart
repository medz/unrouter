import 'package:ht/ht.dart' as ht;

extension type URLSearchParams._(ht.URLSearchParams _)
    implements ht.URLSearchParams {
  URLSearchParams([Object? init]) : this._(ht.URLSearchParams(init));

  URLSearchParams clone() {
    return URLSearchParams._(_.clone());
  }

  String required(String name) {
    return switch (get(name)) {
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
