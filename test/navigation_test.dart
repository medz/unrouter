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

  group('Navigation', () {
    testWidgets('push navigates to new route', (tester) async {
      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Home')),
          Unroute(path: 'about', factory: () => const Text('About')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsNothing);

      // Navigate to about
      router.push('/about');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('replace changes current route', (tester) async {
      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Home')),
          Unroute(path: 'about', factory: () => const Text('About')),
          Unroute(path: 'contact', factory: () => const Text('Contact')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/',
      );

      await tester.pumpWidget(wrapRouter(router));

      // Go to about
      router.push('/about');
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);

      // Replace with contact
      router.replace('/contact');
      await tester.pumpAndSettle();
      expect(find.text('Contact'), findsOneWidget);

      // Go back should skip about and go to home
      router.back();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('back navigates to previous route', (tester) async {
      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Home')),
          Unroute(path: 'about', factory: () => const Text('About')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/',
      );

      await tester.pumpWidget(wrapRouter(router));

      router.push('/about');
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);

      router.back();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('forward navigates after going back', (tester) async {
      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Home')),
          Unroute(path: 'about', factory: () => const Text('About')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/',
      );

      await tester.pumpWidget(wrapRouter(router));

      router.push('/about');
      await tester.pumpAndSettle();

      router.back();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      router.forward();
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('go with positive delta goes forward', (tester) async {
      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Page 0')),
          Unroute(path: '1', factory: () => const Text('Page 1')),
          Unroute(path: '2', factory: () => const Text('Page 2')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/',
      );

      await tester.pumpWidget(wrapRouter(router));

      router.push('/1');
      await tester.pumpAndSettle();

      router.push('/2');
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);

      // Go back to beginning
      router.go(-2);
      await tester.pumpAndSettle();
      expect(find.text('Page 0'), findsOneWidget);

      // Go forward 2 steps
      router.go(2);
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('go with negative delta goes back', (tester) async {
      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Page 0')),
          Unroute(path: '1', factory: () => const Text('Page 1')),
          Unroute(path: '2', factory: () => const Text('Page 2')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/',
      );

      await tester.pumpWidget(wrapRouter(router));

      router.push('/1');
      await tester.pumpAndSettle();

      router.push('/2');
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);

      router.go(-1);
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);

      router.go(-1);
      await tester.pumpAndSettle();
      expect(find.text('Page 0'), findsOneWidget);
    });

    testWidgets('push updates nested routes', (tester) async {
      late Unrouter router;

      Widget createLayout() {
        return Column(
          children: [
            const Text('Layout'),
            Routes([
              Unroute(path: 'a', factory: () => const Text('Page A')),
              Unroute(path: 'b', factory: () => const Text('Page B')),
            ]),
          ],
        );
      }

      router = Unrouter(
        Routes([
          Unroute(path: 'section', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/section/a',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Page A'), findsOneWidget);

      router.push('/section/b');
      await tester.pumpAndSettle();

      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Page B'), findsOneWidget);
      expect(find.text('Page A'), findsNothing);
    });
  });
}
