@TestOn('chrome')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history/browser.dart';

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
      history.push(Uri.parse('/users?page=1'));

      final location = history.location;
      expect(location.uri.path, '/users');
      expect(location.uri.query, 'page=1');
    });

    test('nested hash is preserved', () {
      history.push(Uri.parse('/docs?v=2#section-1'));

      final location = history.location;
      expect(location.uri.path, '/docs');
      expect(location.uri.query, 'v=2');
      expect(location.uri.fragment, 'section-1');
    });

    test('href format uses fragment', () {
      final href = history.createHref(Uri.parse('/users'));
      // The href should contain a fragment marker (#) with the path
      expect(href, contains('#'));
    });
  });
}
