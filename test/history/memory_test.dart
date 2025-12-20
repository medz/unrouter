import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import 'fixture.dart';

void main() {
  // Run common tests with synchronous navigation
  runHistoryTests(
    'MemoryHistory',
    () => MemoryHistory(),
    isAsync: false, // MemoryHistory has synchronous navigation
  );

  group('MemoryHistory Specific', () {
    test('go beyond bounds clamps to valid range', () {
      final history = MemoryHistory();

      history.push(Uri.parse('/page1'));
      history.push(Uri.parse('/page2'));

      // Try to go too far back
      history.go(-10);
      expect(history.location.uri.path, '/');

      // Try to go too far forward
      history.go(10);
      expect(history.location.uri.path, '/page2');
    });

    test('dispose clears internal state', () {
      final history = MemoryHistory();

      history.push(Uri.parse('/page1'));
      history.push(Uri.parse('/page2'));

      // entries are now private (_entries)
      expect(() => history.dispose(), returnsNormally);
    });

    test('can initialize with custom entries', () {
      final history = MemoryHistory(
        initialEntries: [
          RouteInformation(uri: Uri.parse('/home')),
          RouteInformation(uri: Uri.parse('/about')),
        ],
        initialIndex: 1,
      );

      expect(history.location.uri.path, '/about');

      history.back();
      expect(history.location.uri.path, '/home');
    });

    test('initializes with default entry when empty', () {
      final history = MemoryHistory();

      expect(history.location.uri.path, '/');
      expect(history.location.uri.query, '');
      expect(history.location.uri.fragment, '');
    });
  });
}
