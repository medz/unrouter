import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unstory/unstory.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class NestedLayout extends StatelessWidget {
  const NestedLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Outlet();
  }
}

class ChildView extends StatelessWidget {
  const ChildView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Child View');
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Home View');
  }
}

class FromView extends StatelessWidget {
  const FromView({super.key});

  @override
  Widget build(BuildContext context) {
    final from = useFromLocation(context);
    return Text('from:${from?.path ?? 'null'}');
  }
}

MemoryHistory createMemoryHistory(List<String> paths, {int? initialIndex}) {
  return MemoryHistory(
    initialEntries: paths
        .map((path) => HistoryLocation(Uri(path: path)))
        .toList(growable: false),
    initialIndex: initialIndex,
  );
}

Future<void> pumpRouterApp(WidgetTester tester, Unrouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: createRouterConfig(router)),
  );
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
            view: NestedLayout.new,
            children: [Inlet(path: 'child', view: ChildView.new)],
          ),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('Child View'), findsOneWidget);
    });

    testWidgets('updates fromLocation after navigation', (tester) async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: HomeView.new),
          Inlet(path: '/next', view: FromView.new),
        ],
      );

      await pumpRouterApp(tester, router);
      expect(find.text('Home View'), findsOneWidget);

      await router.push('/next');
      await tester.pump();
      await tester.pump();

      expect(find.text('from:/'), findsOneWidget);
    });
  });
}
