import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('RouteIndex', () {
    test('throws on duplicate full paths', () {
      expect(
        () => RouteIndex.fromRoutes(const [
          Inlet(path: 'users', factory: _StubPage.new),
          Inlet(path: 'users', factory: _StubPage.new),
        ]),
        throwsFlutterError,
      );
    });

    test('throws on ** routes with children', () {
      expect(
        () => RouteIndex.fromRoutes(const [
          Inlet(
            path: '**',
            factory: _StubPage.new,
            children: [Inlet(path: 'child', factory: _StubPage.new)],
          ),
        ]),
        throwsFlutterError,
      );
    });

    test('throws on optional segments', () {
      expect(
        () => RouteIndex.fromRoutes(const [
          Inlet(path: 'users/:id?', factory: _StubPage.new),
        ]),
        throwsFlutterError,
      );
    });
  });
}

class _StubPage extends StatelessWidget {
  const _StubPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
