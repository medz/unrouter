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

  group('RouteParams.$int/$num/$double', () {
    test(r'$int parses int from decoded value', () {
      const params = RouteParams({'id': '%2B42'});
      expect(params.$int('id'), 42);
    });

    test(r'$num parses num from decoded value', () {
      const params = RouteParams({'value': '1%2E5'});
      expect(params.$num('value'), 1.5);
    });

    test(r'$double parses double from decoded value', () {
      const params = RouteParams({'value': '3%2E14'});
      expect(params.$double('value'), 3.14);
    });
  });
}
