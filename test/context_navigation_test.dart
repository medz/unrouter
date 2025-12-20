import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('BuildContext navigation extensions', () {
    testWidgets('context.navigate navigates to new route', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const HomePage()),
          Inlet(path: 'about', factory: () => const AboutPage()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsNothing);

      // Tap the button which uses context.navigate
      await tester.tap(find.text('Go to About'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('context.router accesses router instance', (tester) async {
      final router = Unrouter(
        routes: [Inlet(factory: () => const RouterAccessPage())],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.text('Router found: true'), findsOneWidget);
    });

    testWidgets('context.navigate with relative path', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(path: 'users', factory: () => const UsersPage()),
          Inlet(path: 'users/:id', factory: () => const UserDetailPage()),
          Inlet(path: 'users/:id/edit', factory: () => const EditUserPage()),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to /users
      router.navigate(.parse('/users'));
      await tester.pumpAndSettle();
      expect(find.text('Users'), findsOneWidget);

      // Use context.navigate with absolute path to /users/123
      await tester.tap(find.text('View User 123'));
      await tester.pumpAndSettle();
      expect(find.text('User Detail'), findsOneWidget);

      // Use context.navigate with relative path to 'edit'
      await tester.tap(find.text('Edit (relative)'));
      await tester.pumpAndSettle();
      expect(find.text('Edit User'), findsOneWidget);
      expect(router.history.location.uri.path, '/users/123/edit');
    });

    testWidgets('context.navigate with replace option', (tester) async {
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
      await tester.tap(find.text('Go to About'));
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);

      // Replace with contact using context.navigate
      await tester.tap(find.text('Replace with Contact'));
      await tester.pumpAndSettle();
      expect(find.text('Contact'), findsOneWidget);

      // Go back should skip about and return to home
      router.navigate.back();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('context.navigate throws helpful error when no Router', (
      tester,
    ) async {
      FlutterError? caughtError;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  try {
                    final _ = context.navigate;
                  } on FlutterError catch (e) {
                    caughtError = e;
                  }
                },
                child: const Text('Trigger Error'),
              );
            },
          ),
        ),
      );

      // Trigger the error
      await tester.tap(find.text('Trigger Error'));
      await tester.pump();

      // Verify the error message is helpful
      expect(caughtError, isA<FlutterError>());
      expect(
        caughtError!.message,
        contains(
          'context.navigate called with a context that does not contain a Router',
        ),
      );
    });

    testWidgets(
      'context.navigate throws helpful error with wrong delegate type',
      (tester) async {
        FlutterError? caughtError;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Router(
              routerDelegate: _NonNavigateDelegate(),
              routeInformationParser: _DummyRouteInformationParser(),
              routeInformationProvider: PlatformRouteInformationProvider(
                initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
              ),
              backButtonDispatcher: RootBackButtonDispatcher(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get the context from the widget built by the delegate
        final BuildContext context = tester.element(find.byType(SizedBox));

        try {
          final _ = context.navigate;
        } on FlutterError catch (e) {
          caughtError = e;
        }

        expect(caughtError, isNotNull);
        expect(
          caughtError!.message,
          contains('Router whose delegate does not implement Navigate'),
        );
      },
    );

    testWidgets('route state accessors expose granular values', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(
            path: 'parent',
            factory: () => Column(
              children: [
                const RouteInfoPanel(label: 'layout'),
                const Expanded(child: Outlet()),
              ],
            ),
            children: const [
              Inlet(factory: RouteInfoPanel.index),
              Inlet(path: ':id', factory: RouteInfoPanel.child),
            ],
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.navigate(.parse('/parent'));
      await tester.pumpAndSettle();

      final layoutText = tester.widget<Text>(
        find.byKey(const ValueKey('route-info-layout')),
      );
      final indexText = tester.widget<Text>(
        find.byKey(const ValueKey('route-info-index')),
      );

      expect(layoutText.data, contains('path:/parent'));
      expect(layoutText.data, contains('level:0'));
      expect(layoutText.data, contains('matched:2'));
      expect(layoutText.data, contains('params:{}'));
      expect(indexText.data, contains('path:/parent'));
      expect(indexText.data, contains('level:1'));
      expect(indexText.data, contains('matched:2'));
      expect(indexText.data, contains('params:{}'));

      router.navigate(.parse('/parent/42'));
      await tester.pumpAndSettle();

      final childText = tester.widget<Text>(
        find.byKey(const ValueKey('route-info-child')),
      );
      expect(childText.data, contains('path:/parent/42'));
      expect(childText.data, contains('level:1'));
      expect(childText.data, contains('matched:2'));
      expect(childText.data, contains('params:{id: 42}'));
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
          const Text('Home'),
          ElevatedButton(
            onPressed: () => context.navigate(.parse('/about')),
            child: const Text('Go to About'),
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
          const Text('About'),
          ElevatedButton(
            onPressed: () {
              context.navigate(.parse('/contact'), replace: true);
            },
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
    return const Scaffold(body: Text('Contact'));
  }
}

class RouterAccessPage extends StatelessWidget {
  const RouterAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Scaffold(
      // ignore: unnecessary_type_check
      body: Text('Router found: ${router is Unrouter}'),
    );
  }
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Users'),
          ElevatedButton(
            onPressed: () => context.navigate(.parse('/users/123')),
            child: const Text('View User 123'),
          ),
        ],
      ),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('User Detail'),
          ElevatedButton(
            onPressed: () => context.navigate(.parse('edit')),
            child: const Text('Edit (relative)'),
          ),
        ],
      ),
    );
  }
}

class EditUserPage extends StatelessWidget {
  const EditUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Edit User'));
  }
}

class RouteInfoPanel extends StatelessWidget {
  const RouteInfoPanel({super.key, required this.label});

  const RouteInfoPanel.index({super.key}) : label = 'index';

  const RouteInfoPanel.child({super.key}) : label = 'child';

  final String label;

  @override
  Widget build(BuildContext context) {
    final summary =
        '$label|path:${context.location.uri.path}'
        '|matched:${context.matchedRoutes.length}'
        '|params:${context.params}'
        '|level:${context.routeLevel}'
        '|index:${context.historyIndex}'
        '|action:${context.historyAction}';
    return Text(summary, key: ValueKey('route-info-$label'));
  }
}

// Helper classes for testing wrong delegate type
class _NonNavigateDelegate extends RouterDelegate<void>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<void> {
  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  GlobalKey<NavigatorState>? get navigatorKey => GlobalKey<NavigatorState>();

  @override
  Future<void> setNewRoutePath(void configuration) async {}
}

class _DummyRouteInformationParser extends RouteInformationParser<void> {
  @override
  Future<void> parseRouteInformation(RouteInformation routeInformation) async {
    return;
  }
}
