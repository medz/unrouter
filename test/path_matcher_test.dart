import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/src/path_matcher.dart';

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

    test('matches optional params when present', () {
      final match = matchPath(':lang?/about', ['en', 'about']);
      expect(match.matched, true);
      expect(match.params, {'lang': 'en'});
      expect(match.remaining, []);
    });

    test('matches optional params when absent', () {
      final match = matchPath(':lang?/about', ['about']);
      expect(match.matched, true);
      expect(match.params, {});
      expect(match.remaining, []);
    });

    test('matches optional static segments when present', () {
      final match = matchPath('users/:id/edit?', ['users', '123', 'edit']);
      expect(match.matched, true);
      expect(match.params, {'id': '123'});
      expect(match.remaining, []);
    });

    test('matches optional static segments when absent', () {
      final match = matchPath('users/:id/edit?', ['users', '123']);
      expect(match.matched, true);
      expect(match.params, {'id': '123'});
      expect(match.remaining, []);
    });

    test('matches wildcard', () {
      final match = matchPath('files/*', ['files', 'a', 'b', 'c']);
      expect(match.matched, true);
      expect(match.params, {});
      expect(match.remaining, []);
    });

    test('wildcard consumes all remaining segments', () {
      final match = matchPath('*', ['any', 'path', 'here']);
      expect(match.matched, true);
      expect(match.remaining, []);
    });

    test('returns remaining segments for partial match', () {
      final match = matchPath('auth', ['auth', 'login']);
      expect(match.matched, true);
      expect(match.params, {});
      expect(match.remaining, ['login']);
    });

    test('handles complex optional patterns', () {
      final match1 = matchPath('users/:id?/posts', ['users', 'posts']);
      expect(match1.matched, true);
      expect(match1.params, {});

      final match2 = matchPath('users/:id?/posts', ['users', '123', 'posts']);
      expect(match2.matched, true);
      expect(match2.params, {'id': '123'});
    });
  });
}
