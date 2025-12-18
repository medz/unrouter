@TestOn('chrome')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/browser.dart';
import 'package:unrouter/unrouter.dart';

import 'fixture.dart';

void main() {
  // Run common tests for BrowserHistory
  runHistoryTests(
    'BrowserHistory',
    () => BrowserHistory(),
    isAsync: true, // Browser navigation is async
  );

  // Run common tests for HashHistory
  runHistoryTests(
    'HashHistory',
    () => HashHistory(),
    isAsync: true, // Browser navigation is async
  );

  // HashHistory-specific tests
  group('HashHistory Specific', () {
    late HashHistory history;

    setUp(() {
      history = HashHistory();
    });

    tearDown(() {
      history.dispose();
    });

    test('location parses fragment correctly', () {
      history.push(const Path(pathname: '/users', search: 'page=1'));

      final location = history.location;
      expect(location.pathname, '/users');
      expect(location.search, 'page=1');
    });

    test('nested hash is preserved', () {
      history.push(
        const Path(pathname: '/docs', search: 'v=2', hash: 'section-1'),
      );

      final location = history.location;
      expect(location.pathname, '/docs');
      expect(location.search, 'v=2');
      expect(location.hash, 'section-1');
    });

    test('href format uses fragment', () {
      final href = history.createHref(const Path(pathname: '/users'));
      // The href should contain a fragment marker (#) with the path
      expect(href, contains('#'));
    });
  });
}
