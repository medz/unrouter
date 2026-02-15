import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('RouteParams.required', () {
    test('returns value when key exists', () {
      const params = RouteParams({'id': '42'});
      expect(params.required('id'), '42');
    });

    test('throws ArgumentError when key is missing', () {
      const params = RouteParams({'id': '42'});
      expect(
        () => params.required('slug'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'toString',
            contains('Required parameter "slug" not found'),
          ),
        ),
      );
    });
  });

  group('RouteParams.decode', () {
    test('decodes value before passing into fn', () {
      const params = RouteParams({'name': 'a%20b%2Fc'});
      final value = params.decode<String>('name', (value) => value);
      expect(value, 'a b/c');
    });

    test('supports typed decode result', () {
      const params = RouteParams({'id': '42'});
      final value = params.decode<int>('id', int.parse);
      expect(value, 42);
    });

    test('throws ArgumentError when key is missing', () {
      const params = RouteParams({'id': '42'});
      expect(
        () => params.decode<String>('slug', (value) => value),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'toString',
            contains('Required parameter "slug" not found'),
          ),
        ),
      );
    });
  });
}
