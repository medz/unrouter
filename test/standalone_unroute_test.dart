import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrapRouter(Unrouter router) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Router.withConfig(config: router),
    );
  }

  group('Standalone Unroute', () {
    testWidgets('Unroute caches widget - only creates once', (tester) async {
      var layoutBuildCount = 0;
      var bBuildCount = 0;
      var cBuildCount = 0;

      Widget createLayout() {
        layoutBuildCount++;
        return Column(
          children: [
            Text('Layout (built $layoutBuildCount times)'),
            Unroute(
              path: 'b',
              factory: () {
                bBuildCount++;
                return Text('B (built $bBuildCount times)');
              },
            ),
            Unroute(
              path: 'c',
              factory: () {
                cBuildCount++;
                return Text('C (built $cBuildCount times)');
              },
            ),
          ],
        );
      }

      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: 'a', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/a/b',
      );

      await tester.pumpWidget(wrapRouter(router));

      // Initial: /a/b
      expect(layoutBuildCount, 1, reason: 'Layout created once');
      expect(bBuildCount, 1, reason: 'B created once');
      expect(cBuildCount, 0, reason: 'C not created yet');

      // Navigate to /a/c
      router.push('/a/c');
      await tester.pumpAndSettle();

      expect(layoutBuildCount, 1, reason: 'Layout NOT rebuilt (cached)');
      expect(bBuildCount, 1, reason: 'B not rebuilt (cached)');
      expect(cBuildCount, 1, reason: 'C created once');

      // Navigate back to /a/b
      router.push('/a/b');
      await tester.pumpAndSettle();

      expect(layoutBuildCount, 1, reason: 'Layout still NOT rebuilt');
      expect(bBuildCount, 1, reason: 'B still not rebuilt (reused cache)');
      expect(cBuildCount, 1, reason: 'C still cached');

      // Navigate to /a/c again
      router.push('/a/c');
      await tester.pumpAndSettle();

      expect(layoutBuildCount, 1, reason: 'Layout never rebuilt');
      expect(bBuildCount, 1, reason: 'B never rebuilt');
      expect(cBuildCount, 1, reason: 'C reused cache');
    });

    testWidgets('Unroute can be used directly in widget tree', (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            const Text('Header'),
            Unroute(path: 'b', factory: () => const Text('Child B')),
            Unroute(path: 'c', factory: () => const Text('Child C')),
            const Text('Footer'),
          ],
        );
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'a', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/a/b',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Child B'), findsOneWidget);
      expect(find.text('Child C'), findsNothing);  // Not matched
      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('Unroute switches when route changes', (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            const Text('Header'),
            Unroute(path: 'b', factory: () => const Text('Child B')),
            Unroute(path: 'c', factory: () => const Text('Child C')),
          ],
        );
      }

      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: 'a', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/a/b',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Child B'), findsOneWidget);
      expect(find.text('Child C'), findsNothing);

      // Navigate to /a/c
      router.push('/a/c');
      await tester.pumpAndSettle();

      expect(find.text('Child B'), findsNothing);
      expect(find.text('Child C'), findsOneWidget);
    });

    testWidgets('Multiple Unroutes can be used in complex layouts',
        (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            Row(
              children: [
                Unroute(path: 'sidebar', factory: () => const Text('Sidebar')),
                Unroute(path: 'main', factory: () => const Text('Main')),
              ],
            ),
            Unroute(path: 'footer', factory: () => const Text('Footer')),
          ],
        );
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'page', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/page/main',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Sidebar'), findsNothing);
      expect(find.text('Main'), findsOneWidget);
      expect(find.text('Footer'), findsNothing);
    });

    testWidgets('Unroute works with index routes', (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            const Text('Layout'),
            Unroute(path: null, factory: () => const Text('Index')),
            Unroute(path: 'details', factory: () => const Text('Details')),
          ],
        );
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'section', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/section',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Index'), findsOneWidget);
      expect(find.text('Details'), findsNothing);
    });

    testWidgets('Unroute with dynamic params', (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            Unroute(
              path: 'user/:id',
              factory: () {
                return Builder(
                  builder: (context) {
                    final state = RouterStateProvider.of(context);
                    return Text('User: ${state.params['id']}');
                  },
                );
              },
            ),
            Unroute(
              path: 'post/:id',
              factory: () {
                return Builder(
                  builder: (context) {
                    final state = RouterStateProvider.of(context);
                    return Text('Post: ${state.params['id']}');
                  },
                );
              },
            ),
          ],
        );
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'content', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/content/user/123',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('User: 123'), findsOneWidget);
      expect(find.textContaining('Post:'), findsNothing);
    });
  });
}
