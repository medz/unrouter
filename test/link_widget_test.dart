import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Link widget', () {
    testWidgets('navigates when tapped', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const HomePage()),
          Inlet(path: 'about', factory: () => const AboutPage()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.text('Home Page'), findsOneWidget);
      expect(find.text('About Page'), findsNothing);

      // Tap the link
      await tester.tap(find.text('Go to About'));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsNothing);
      expect(find.text('About Page'), findsOneWidget);
      expect(router.history.location.uri.path, '/about');
    });

    testWidgets('supports replace option', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const HomePage()),
          Inlet(path: 'about', factory: () => const AboutPage()),
          Inlet(path: 'contact', factory: () => const ContactPage()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to about
      router.navigate(.parse('/about'));
      await tester.pumpAndSettle();
      expect(find.text('About Page'), findsOneWidget);

      // Tap the replace link
      await tester.tap(find.text('Replace with Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Contact Page'), findsOneWidget);

      // Go back should skip about and go to home
      router.navigate.back();
      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('supports state parameter', (tester) async {
      Object? capturedState;
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const HomePage()),
          Inlet(
            path: 'about',
            factory: () => Builder(
              builder: (context) {
                final state = context.routerState;
                capturedState = state.location.state;
                return const AboutPage();
              },
            ),
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Tap the link with state
      await tester.tap(find.text('Go to About with State'));
      await tester.pumpAndSettle();

      expect(find.text('About Page'), findsOneWidget);
      expect(capturedState, equals({'source': 'home'}));
    });

    testWidgets('Link builder provides location and navigate callback', (
      tester,
    ) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const BuilderTestPage()),
          Inlet(path: 'target', factory: () => const TargetPage()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.text('Builder Test'), findsOneWidget);
      expect(find.text('Uri: /target'), findsOneWidget);
      expect(find.text('State: test-state'), findsOneWidget);

      // Tap the custom link
      await tester.tap(find.text('Custom Link'));
      await tester.pumpAndSettle();

      expect(find.text('Target Page'), findsOneWidget);
    });

    testWidgets('Link builder navigate callback supports overrides', (
      tester,
    ) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const OverrideTestPage()),
          Inlet(path: 'page1', factory: () => const Page1()),
          Inlet(path: 'page2', factory: () => const Page2()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to page1
      await tester.tap(find.text('Go to Page 1'));
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);

      // Navigate to page2 with replace override
      await tester.tap(find.text('Replace with Page 2'));
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);

      // Go back should skip page1
      router.navigate.back();
      await tester.pumpAndSettle();
      expect(find.text('Override Test'), findsOneWidget);
    });

    testWidgets('Link has proper semantics', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const HomePage()),
          Inlet(path: 'about', factory: () => const AboutPage()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Find the Semantics widget
      final semanticsFinder = find.descendant(
        of: find.widgetWithText(Link, 'Go to About'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.link == true,
        ),
      );

      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Link has mouse cursor on hover', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const HomePage()),
          Inlet(path: 'about', factory: () => const AboutPage()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Find the MouseRegion widget
      final mouseRegionFinder = find.descendant(
        of: find.widgetWithText(Link, 'Go to About'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is MouseRegion &&
              widget.cursor == SystemMouseCursors.click,
        ),
      );

      expect(mouseRegionFinder, findsOneWidget);
    });
  });
}

// Test widgets
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Home Page'),
          Link(to: Uri.parse('/about'), child: const Text('Go to About')),
          Link(
            to: Uri.parse('/about'),
            state: const {'source': 'home'},
            child: const Text('Go to About with State'),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('About Page'),
          Link(
            to: Uri.parse('/contact'),
            replace: true,
            child: const Text('Replace with Contact'),
          ),
        ],
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Contact Page'));
  }
}

class TargetPage extends StatelessWidget {
  const TargetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Target Page'));
  }
}

class BuilderTestPage extends StatelessWidget {
  const BuilderTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Builder Test'),
          Link(
            to: Uri.parse('/target'),
            state: 'test-state',
            builder: (context, location, navigate) {
              return Column(
                children: [
                  Text('Uri: ${location.uri.path}'),
                  Text('State: ${location.state}'),
                  GestureDetector(
                    onTap: () => navigate(),
                    child: const Text('Custom Link'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class OverrideTestPage extends StatelessWidget {
  const OverrideTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Override Test'),
          Link(
            to: Uri.parse('/page1'),
            builder: (context, location, navigate) {
              return GestureDetector(
                onTap: () => navigate(),
                child: const Text('Go to Page 1'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Page 1'),
          Link(
            to: Uri.parse('/page2'),
            replace: false,
            builder: (context, location, navigate) {
              return GestureDetector(
                onTap: () => navigate(replace: true),
                child: const Text('Replace with Page 2'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Page 2'));
  }
}
