import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

class _NestedLayout extends StatelessWidget {
  const _NestedLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Outlet();
  }
}

class _ChildView extends StatelessWidget {
  const _ChildView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Child View');
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Home View');
  }
}

class _FromView extends StatelessWidget {
  const _FromView({super.key});

  @override
  Widget build(BuildContext context) {
    final from = useFromLocation(context);
    return Text('from:${from?.path ?? 'null'}');
  }
}

class _ViewB extends StatelessWidget {
  const _ViewB({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('View B');
  }
}

class _ViewC extends StatelessWidget {
  const _ViewC({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('View C');
  }
}

class _SharedANewLayout extends StatelessWidget {
  const _SharedANewLayout();

  static int buildCount = 0;

  static void resetCounters() {
    buildCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    _SharedANewLayout.buildCount += 1;
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
            view: _NestedLayout.new,
            children: [Inlet(path: 'child', view: _ChildView.new)],
          ),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('Child View'), findsOneWidget);
    });

    testWidgets('throws when location path has no matched route', (
      tester,
    ) async {
      final history = createMemoryHistory(['/missing']);
      final router = createRouter(
        history: history,
        routes: [Inlet(path: '/', view: EmptyView.new)],
      );

      await pumpRouterApp(tester, router);
      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(error.toString(), contains('No route matched path'));
    });

    test('popRoute delegates to router.pop', () async {
      final history = createMemoryHistory(['/', '/next'], initialIndex: 1);
      final router = createRouter(
        history: history,
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/next', view: EmptyView.new),
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
          Inlet(path: '/', view: _HomeView.new),
          Inlet(path: '/next', view: _FromView.new),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('Home View'), findsOneWidget);

      await router.push('/next');
      await tester.pump();
      await tester.pump();

      expect(find.text('from:/'), findsOneWidget);
    });

    testWidgets('shared /a layout does not rebuild on child switch', (
      tester,
    ) async {
      _SharedANewLayout.resetCounters();
      final history = createMemoryHistory(['/a/b']);
      final router = createRouter(
        history: history,
        routes: [
          Inlet(
            path: '/a',
            view: _SharedANewLayout.new,
            children: [
              Inlet(path: 'b', view: _ViewB.new),
              Inlet(path: 'c', view: _ViewC.new),
            ],
          ),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('View B'), findsOneWidget);
      expect(_SharedANewLayout.buildCount, 1);

      final buildsBeforeSwitch = _SharedANewLayout.buildCount;
      await router.push('/a/c');
      await tester.pump();
      await tester.pump();

      expect(find.text('View C'), findsOneWidget);
      expect(_SharedANewLayout.buildCount, buildsBeforeSwitch);
    });
  });
}
