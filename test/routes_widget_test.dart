import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Routes widget', () {
    testWidgets('renders matched route', (tester) async {
      final history = MemoryHistory(
        initialEntries: [RouteInformation(uri: Uri.parse('/'))],
      );

      final router = Unrouter(
        history: history,
        child: Routes(RouteIndex.fromRoutes(const [
          Inlet(factory: HomePage.new),
          Inlet(path: 'about', factory: AboutPage.new),
        ])),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsNothing);
    });

    testWidgets('navigates to different route', (tester) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        child: Routes(RouteIndex.fromRoutes(const [
          Inlet(factory: HomePage.new),
          Inlet(path: 'about', factory: AboutPage.new),
        ])),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      expect(find.text('Home'), findsOneWidget);

      // Navigate to /about
      router.navigate(path: '/about');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('nested Routes require full match', (tester) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/about'))],
        ),
        child: Routes(RouteIndex.fromRoutes(const [
          Inlet(factory: HomePage.new),
          Inlet(path: 'about', factory: AboutPageWithNestedRoutes.new),
        ])),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      expect(find.text('About'), findsOneWidget);
      expect(find.text('About Home'), findsOneWidget);
      expect(find.text('About Details'), findsNothing);

      // Navigate to /about/details (no partial match)
      router.navigate(path: '/about/details');
      await tester.pumpAndSettle();

      expect(find.text('About'), findsNothing);
      expect(find.text('About Home'), findsNothing);
      expect(find.text('About Details'), findsNothing);
    });

    testWidgets('routes + child combination works', (tester) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: RouteIndex.fromRoutes(const [Inlet(path: 'static', factory: StaticPage.new)]),
        child: Routes(RouteIndex.fromRoutes(const [
          Inlet(factory: HomePage.new),
          Inlet(path: 'about', factory: AboutPage.new),
        ])),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Should render dynamic route (child)
      expect(find.text('Home'), findsOneWidget);

      // Navigate to static route
      router.navigate(path: '/static');
      await tester.pumpAndSettle();

      expect(find.text('Static'), findsOneWidget);
      expect(find.text('Home'), findsNothing);

      // Navigate to dynamic route in child
      router.navigate(path: '/about');
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Static'), findsNothing);
    });

    testWidgets('only child without routes works', (tester) async {
      final history = MemoryHistory(
        initialEntries: [RouteInformation(uri: Uri.parse('/'))],
      );

      final router = Unrouter(
        history: history,
        child: Routes(RouteIndex.fromRoutes(const [
          Inlet(factory: HomePage.new),
          Inlet(path: 'about', factory: AboutPage.new),
        ])),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      expect(find.text('Home'), findsOneWidget);
    });
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Home');
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('About');
  }
}

class StaticPage extends StatelessWidget {
  const StaticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Static');
  }
}

class AboutPageWithNestedRoutes extends StatelessWidget {
  const AboutPageWithNestedRoutes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('About'),
        Routes(RouteIndex.fromRoutes(const [
          Inlet(factory: AboutHomePage.new),
          Inlet(path: 'details', factory: AboutDetailsPage.new),
        ])),
      ],
    );
  }
}

class AboutHomePage extends StatelessWidget {
  const AboutHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('About Home');
  }
}

class AboutDetailsPage extends StatelessWidget {
  const AboutDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('About Details');
  }
}
