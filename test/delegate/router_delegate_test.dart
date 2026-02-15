import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

Widget _nestedShell() => const Outlet();

Widget _fromView() {
  return Builder(
    builder: (context) {
      final from = useFromLocation(context);
      return Text('from:${from?.path ?? 'null'}');
    },
  );
}

class _SharedALayout extends StatelessWidget {
  const _SharedALayout();

  static int buildCount = 0;

  static void resetCounters() {
    buildCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    _SharedALayout.buildCount += 1;
    return const Outlet();
  }
}

void main() {
  group('router delegate', () {
    testWidgets('renders matched nested route through outlet chain', (
      tester,
    ) async {
      final history = createMemoryHistory(['/child']);
      final router = createRouter(
        history: history,
        routes: [
          Inlet(
            path: '/',
            view: _nestedShell,
            children: [
              Inlet(path: 'child', view: () => const Text('Child Page')),
            ],
          ),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('Child Page'), findsOneWidget);
    });

    testWidgets('throws when location has no matched route', (tester) async {
      final history = createMemoryHistory(['/missing']);
      final router = createRouter(
        history: history,
        routes: [Inlet(path: '/', view: emptyView)],
      );

      await pumpRouterApp(tester, router);
      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(error.toString(), contains('No route matched'));
    });

    test('popRoute delegates to router.pop', () async {
      final history = createMemoryHistory(['/', '/next'], initialIndex: 1);
      final router = createRouter(
        history: history,
        routes: [
          Inlet(path: '/', view: emptyView),
          Inlet(path: '/next', view: emptyView),
        ],
      );

      final config = createRouterConfig(router);
      final popped = await config.routerDelegate.popRoute();

      expect(popped, isTrue);
      await flushAsyncQueue();
      expect(router.history.location.path, '/');
    });

    testWidgets('updates fromLocation after navigation', (tester) async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: () => const Text('Home Page')),
          Inlet(path: '/next', view: _fromView),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('Home Page'), findsOneWidget);

      await router.push('/next');
      await tester.pump();
      await tester.pump();

      expect(find.text('from:/'), findsOneWidget);
    });

    testWidgets('shared /a layout is not remounted when switching children', (
      tester,
    ) async {
      _SharedALayout.resetCounters();
      final history = createMemoryHistory(['/a/b']);
      final router = createRouter(
        history: history,
        routes: [
          Inlet(
            path: '/a',
            view: () => const _SharedALayout(),
            children: [
              Inlet(path: 'b', view: () => const Text('Page B')),
              Inlet(path: 'c', view: () => const Text('Page C')),
            ],
          ),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('Page B'), findsOneWidget);
      expect(_SharedALayout.buildCount, 1);

      final buildsBeforeSwitch = _SharedALayout.buildCount;
      await router.push('/a/c');
      await tester.pump();
      await tester.pump();

      expect(find.text('Page C'), findsOneWidget);
      expect(_SharedALayout.buildCount, buildsBeforeSwitch);
    });
  });
}
