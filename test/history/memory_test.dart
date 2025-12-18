import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/src/history/history.dart';
import 'package:unrouter/src/history/memory.dart';

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

      history.push(const Path(pathname: '/page1'));
      history.push(const Path(pathname: '/page2'));

      // Try to go too far back
      history.go(-10);
      expect(history.location.pathname, '/');

      // Try to go too far forward
      history.go(10);
      expect(history.location.pathname, '/page2');
    });

    test('dispose clears internal state', () {
      final history = MemoryHistory();

      history.push(const Path(pathname: '/page1'));
      history.push(const Path(pathname: '/page2'));

      expect(history.entries.length, 3);
      expect(() => history.dispose(), returnsNormally);
      expect(history.entries.isEmpty, true);
    });

    test('can initialize with custom entries', () {
      final history = MemoryHistory(
        initialEntries: const [
          Location(pathname: '/home', identifier: 'home'),
          Location(pathname: '/about', identifier: 'about'),
        ],
        initialIndex: 1,
      );

      expect(history.location.pathname, '/about');

      history.back();
      expect(history.location.pathname, '/home');
    });

    test('initializes with default entry when empty', () {
      final history = MemoryHistory();

      expect(history.location.pathname, '/');
      expect(history.location.search, '');
      expect(history.location.hash, '');
    });
  });
}
