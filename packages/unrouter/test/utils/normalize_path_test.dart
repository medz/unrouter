import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/src/utils.dart';

void main() {
  group('normalizePath', () {
    test('returns root for empty inputs', () {
      expect(normalizePath(const []), '/');
      expect(normalizePath(const ['', '/']), '/');
    });

    test('normalizes leading trailing and duplicated slashes', () {
      expect(normalizePath(const ['/users/', '/42/']), '/users/42');
      expect(normalizePath(const ['//a//', '///b///']), '/a/b');
    });

    test('joins multiple path pieces in order', () {
      expect(
        normalizePath(const ['/workspace', 'users', ':id']),
        '/workspace/users/:id',
      );
      expect(normalizePath(const ['docs', '*']), '/docs/*');
    });
  });
}
