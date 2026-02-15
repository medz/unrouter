import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

enum _Role { admin, member }

void main() {
  group('URLSearchParams.required', () {
    test('returns first value when key exists', () {
      final params = URLSearchParams('q=1&q=2');
      expect(params.required('q'), '1');
    });

    test('throws ArgumentError when key is missing', () {
      final params = URLSearchParams('q=1');
      expect(
        () => params.required('page'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'toString',
            contains('Required parameter "page" not found'),
          ),
        ),
      );
    });
  });

  group('URLSearchParams.decode', () {
    test('decodes value before passing into fn', () {
      final params = URLSearchParams({'name': 'a%20b%2Fc'});
      final value = params.decode<String>('name', (value) => value);
      expect(value, 'a b/c');
    });

    test('supports typed decode result', () {
      final params = URLSearchParams({'id': '42'});
      final value = params.decode<int>('id', int.parse);
      expect(value, 42);
    });
  });

  group(r'URLSearchParams.$int/$num/$double', () {
    test(r'$int parses int from decoded value', () {
      final params = URLSearchParams({'id': '%2B42'});
      expect(params.$int('id'), 42);
    });

    test(r'$num parses num from decoded value', () {
      final params = URLSearchParams({'value': '1%2E5'});
      expect(params.$num('value'), 1.5);
    });

    test(r'$double parses double from decoded value', () {
      final params = URLSearchParams({'value': '3%2E14'});
      expect(params.$double('value'), 3.14);
    });
  });

  group(r'URLSearchParams.$enum', () {
    test(r'$enum parses enum by decoded name', () {
      final params = URLSearchParams({'role': 'ad%6Din'});
      expect(params.$enum<_Role>('role', _Role.values), _Role.admin);
    });

    test(r'$enum throws ArgumentError for unknown value', () {
      final params = URLSearchParams({'role': 'owner'});
      expect(
        () => params.$enum<_Role>('role', _Role.values),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'toString',
            contains('Expected one of: admin, member'),
          ),
        ),
      );
    });
  });

  test('clone keeps helper methods available', () {
    final source = URLSearchParams({'id': '42'});
    final cloned = source.clone();
    expect(cloned.$int('id'), 42);
  });
}
