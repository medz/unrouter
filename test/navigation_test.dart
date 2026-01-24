import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrapRouter(Unrouter router) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Router.withConfig(config: router),
    );
  }

  group('Navigation', () {
    testWidgets('push navigates to new route', (tester) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Home')),
          Inlet(path: 'about', factory: () => const Text('About')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsNothing);

      // Navigate to about
      final result = await router.navigate(path: '/about');
      await tester.pumpAndSettle();

      expect(result, isA<NavigationSuccess>());
      final success = result as NavigationSuccess;
      expect(success.action, HistoryAction.push);
      expect(find.text('Home'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('replace changes current route', (tester) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Home')),
          Inlet(path: 'about', factory: () => const Text('About')),
          Inlet(path: 'contact', factory: () => const Text('Contact')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      // Go to about
      router.navigate(path: '/about');
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);

      // Replace with contact
      router.navigate(path: '/contact', replace: true);
      await tester.pumpAndSettle();
      expect(find.text('Contact'), findsOneWidget);

      // Go back should skip about and go to home
      router.navigate.back();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('concurrent navigation resolves to last request', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Home')),
          Inlet(path: 'about', factory: () => const Text('About')),
          Inlet(path: 'contact', factory: () => const Text('Contact')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      final first = router.navigate(path: '/about');
      final second = router.navigate(path: '/contact');
      await tester.pumpAndSettle();

      final firstResult = await first;
      final secondResult = await second;

      expect(firstResult, isA<NavigationSuccess>());
      expect(secondResult, isA<NavigationSuccess>());
      expect(router.history.location.uri.path, '/contact');
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('About'), findsNothing);
    });

    testWidgets('back navigates to previous route', (tester) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Home')),
          Inlet(path: 'about', factory: () => const Text('About')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      await router.navigate(path: '/about');
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);

      final result = await router.navigate.back();
      await tester.pumpAndSettle();
      expect(result, isA<NavigationSuccess>());
      final success = result as NavigationSuccess;
      expect(success.action, HistoryAction.pop);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('forward navigates after going back', (tester) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Home')),
          Inlet(path: 'about', factory: () => const Text('About')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      router.navigate(path: '/about');
      await tester.pumpAndSettle();

      router.navigate.back();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      router.navigate.forward();
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('go with positive delta goes forward', (tester) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Page 0')),
          Inlet(path: '1', factory: () => const Text('Page 1')),
          Inlet(path: '2', factory: () => const Text('Page 2')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      router.navigate(path: '/1');
      await tester.pumpAndSettle();

      router.navigate(path: '/2');
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);

      // Go back to beginning
      router.navigate.go(-2);
      await tester.pumpAndSettle();
      expect(find.text('Page 0'), findsOneWidget);

      // Go forward 2 steps
      router.navigate.go(2);
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('go with negative delta goes back', (tester) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Page 0')),
          Inlet(path: '1', factory: () => const Text('Page 1')),
          Inlet(path: '2', factory: () => const Text('Page 2')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      router.navigate(path: '/1');
      await tester.pumpAndSettle();

      router.navigate(path: '/2');
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);

      router.navigate.go(-1);
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);

      router.navigate.go(-1);
      await tester.pumpAndSettle();
      expect(find.text('Page 0'), findsOneWidget);
    });

    testWidgets('push updates nested routes', (tester) async {
      late Unrouter router;

      Widget createLayout() {
        return Column(children: [const Text('Layout'), const Outlet()]);
      }

      router = Unrouter(
        routes: [
          Inlet(
            path: 'section',
            factory: createLayout,
            children: [
              Inlet(path: 'a', factory: () => const Text('Page A')),
              Inlet(path: 'b', factory: () => const Text('Page B')),
            ],
          ),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/section/a'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Page A'), findsOneWidget);

      router.navigate(path: '/section/b');
      await tester.pumpAndSettle();

      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Page B'), findsOneWidget);
      expect(find.text('Page A'), findsNothing);
    });
  });
}
