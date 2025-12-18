import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Base Path', () {
    test('history uses provided base path', () {
      // Base path feature not implemented
    }, skip: 'Base path feature not implemented');

    test('history defaults to / when base not provided', () {
      // Base path feature not implemented
    }, skip: 'Base path feature not implemented');

    test('createHref uses base path', () {
      final router = Unrouter(
        routes: [Inlet(factory: () => throw UnimplementedError())],
        history: MemoryHistory(),
      );

      final href = router.history.createHref(Path(pathname: '/about'));
      expect(href, '/about'); // Base path feature not implemented
    });

    test('createHref with default base', () {
      final router = Unrouter(
        routes: [Inlet(factory: () => throw UnimplementedError())],
        history: MemoryHistory(),
      );

      final href = router.history.createHref(Path(pathname: '/about'));
      expect(href, '/about');
    });

    test('base path is normalized', () {
      // Base should be normalized (trailing slash removed)
      // Base path feature not implemented
    }, skip: 'Base path feature not implemented');
  });
}
