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
}
