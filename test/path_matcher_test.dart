import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/src/router/_internal/path_matcher.dart';

void main() {
  group('normalizePath', () {
    test('handles null and empty paths', () {
      expect(normalizePath(null), '');
      expect(normalizePath(''), '');
      expect(normalizePath('/'), '');
    });

    test('removes leading and trailing slashes', () {
      expect(normalizePath('/about'), 'about');
      expect(normalizePath('about/'), 'about');
      expect(normalizePath('/about/'), 'about');
    });

    test('handles multiple segments', () {
      expect(normalizePath('a/b/c'), 'a/b/c');
      expect(normalizePath('/a/b/c'), 'a/b/c');
      expect(normalizePath('a/b/c/'), 'a/b/c');
    });

    test('removes empty segments', () {
      expect(normalizePath('a//b'), 'a/b');
      expect(normalizePath('a///b'), 'a/b');
    });
  });

  group('splitPath', () {
    test('splits normalized paths', () {
      expect(splitPath(''), []);
      expect(splitPath('/'), []);
      expect(splitPath('about'), ['about']);
      expect(splitPath('/a/b/c'), ['a', 'b', 'c']);
    });
  });

  group('matchPath', () {
    test('matches index routes', () {
      final match = matchPath(null, []);
      expect(match.matched, true);
      expect(match.params, {});
      expect(match.remaining, []);

      final match2 = matchPath('/', []);
      expect(match2.matched, true);

      final match3 = matchPath('', []);
      expect(match3.matched, true);
    });

    test('does not match index route with path', () {
      final match = matchPath(null, ['about']);
      expect(match.matched, false);
    });

    test('matches static routes', () {
      final match = matchPath('about', ['about']);
      expect(match.matched, true);
      expect(match.params, {});
      expect(match.remaining, []);
    });

    test('matches nested static routes', () {
      final match = matchPath('users/profile', ['users', 'profile']);
      expect(match.matched, true);
      expect(match.params, {});
      expect(match.remaining, []);
    });

    test('does not match different static routes', () {
      final match = matchPath('about', ['contact']);
      expect(match.matched, false);
    });

    test('matches dynamic params', () {
      final match = matchPath('users/:id', ['users', '123']);
      expect(match.matched, true);
      expect(match.params, {'id': '123'});
      expect(match.remaining, []);
    });

    test('matches multiple dynamic params', () {
      final match = matchPath('users/:userId/posts/:postId', [
        'users',
        'alice',
        'posts',
        '456',
      ]);
      expect(match.matched, true);
      expect(match.params, {'userId': 'alice', 'postId': '456'});
      expect(match.remaining, []);
    });

    test('matches embedded params', () {
      final match = matchPath('files/:name.:ext', ['files', 'report.pdf']);
      expect(match.matched, true);
      expect(match.params, {'name': 'report', 'ext': 'pdf'});
      expect(match.remaining, []);
    });

    test('matches single-segment wildcard', () {
      final match = matchPath('files/*', ['files', 'a', 'b', 'c']);
      expect(match.matched, true);
      expect(match.params, {'_0': 'a'});
      expect(match.remaining, ['b', 'c']);
    });

    test('matches multi-segment wildcard', () {
      final match = matchPath('files/**', ['files', 'a', 'b', 'c']);
      expect(match.matched, true);
      expect(match.params, {'_': 'a/b/c'});
      expect(match.remaining, []);
    });

    test('captures named multi-wildcard params', () {
      final match = matchPath('files/**:path', ['files', 'a', 'b']);
      expect(match.matched, true);
      expect(match.params, {'path': 'a/b'});
      expect(match.remaining, []);
    });

    test('returns remaining segments for partial match', () {
      final match = matchPath('auth', ['auth', 'login']);
      expect(match.matched, true);
      expect(match.params, {});
      expect(match.remaining, ['login']);
    });

  });
}
