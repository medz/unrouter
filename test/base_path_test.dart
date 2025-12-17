import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Base Path', () {
    test('history uses provided base path', () {
      final router = Unrouter(
        routes: [Inlet(factory: () => throw UnimplementedError())],
        mode: HistoryMode.memory,
        base: '/my-app',
      );

      expect(router.history.base, '/my-app');
    });

    test('history defaults to / when base not provided', () {
      final router = Unrouter(
        routes: [Inlet(factory: () => throw UnimplementedError())],
        mode: HistoryMode.memory,
      );

      expect(router.history.base, '/');
    });

    test('createHref uses base path', () {
      final router = Unrouter(
        routes: [Inlet(factory: () => throw UnimplementedError())],
        mode: HistoryMode.memory,
        base: '/my-app',
      );

      final href = router.history.createHref('/about');
      expect(href, '/my-app/about');
    });

    test('createHref with default base', () {
      final router = Unrouter(
        routes: [Inlet(factory: () => throw UnimplementedError())],
        mode: HistoryMode.memory,
      );

      final href = router.history.createHref('/about');
      expect(href, '/about');
    });

    test('base path is normalized', () {
      final router = Unrouter(
        routes: [Inlet(factory: () => throw UnimplementedError())],
        mode: HistoryMode.memory,
        base: '/my-app/', // Trailing slash
      );

      // Base should be normalized (trailing slash removed)
      expect(router.history.base, '/my-app');
    });
  });
}
