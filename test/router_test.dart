import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  // Helper to wrap router in Directionality
  Widget wrapRouter(Unrouter router) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Router.withConfig(config: router),
    );
  }

  group('Basic Routing', () {
    testWidgets('renders index route', (tester) async {
      final router = Unrouter(
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
    });

    testWidgets('renders static route', (tester) async {
      final router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Home')),
          Unroute(path: 'about', factory: () => const Text('About')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/about',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Home'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('renders route with multiple segments', (tester) async {
      final router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Home')),
          Unroute(
            path: 'users/profile',
            factory: () => const Text('Profile'),
          ),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/users/profile',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('renders 404 for unknown route', (tester) async {
      final router = Unrouter(
        Routes([
          Unroute(path: null, factory: () => const Text('Home')),
          Unroute(path: 'about', factory: () => const Text('About')),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/unknown',
      );

      await tester.pumpWidget(wrapRouter(router));

      // Should render nothing (SizedBox.shrink)
      expect(find.text('Home'), findsNothing);
      expect(find.text('About'), findsNothing);
    });
  });

  group('Dynamic Routes', () {
    testWidgets('matches route with dynamic param', (tester) async {
      late String capturedId;

      final router = Unrouter(
        Routes([
          Unroute(
            path: 'users/:id',
            factory: () {
              return Builder(
                builder: (context) {
                  final state = RouterStateProvider.of(context);
                  capturedId = state.params['id'] ?? '';
                  return Text('User: $capturedId');
                },
              );
            },
          ),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/users/123',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(capturedId, '123');
      expect(find.text('User: 123'), findsOneWidget);
    });

    testWidgets('matches route with multiple params', (tester) async {
      late Map<String, String> capturedParams;

      final router = Unrouter(
        Routes([
          Unroute(
            path: 'users/:userId/posts/:postId',
            factory: () {
              return Builder(
                builder: (context) {
                  final state = RouterStateProvider.of(context);
                  capturedParams = state.params;
                  return Text(
                    'User: ${state.params['userId']}, '
                    'Post: ${state.params['postId']}',
                  );
                },
              );
            },
          ),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/users/alice/posts/456',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(capturedParams['userId'], 'alice');
      expect(capturedParams['postId'], '456');
      expect(find.text('User: alice, Post: 456'), findsOneWidget);
    });

    testWidgets('matches route with optional param present', (tester) async {
      late String? capturedLang;

      final router = Unrouter(
        Routes([
          Unroute(
            path: ':lang?/about',
            factory: () {
              return Builder(
                builder: (context) {
                  final state = RouterStateProvider.of(context);
                  capturedLang = state.params['lang'];
                  return Text('About (${capturedLang ?? "default"})');
                },
              );
            },
          ),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/en/about',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(capturedLang, 'en');
      expect(find.text('About (en)'), findsOneWidget);
    });

    testWidgets('matches route with optional param absent', (tester) async {
      late String? capturedLang;

      final router = Unrouter(
        Routes([
          Unroute(
            path: ':lang?/about',
            factory: () {
              return Builder(
                builder: (context) {
                  final state = RouterStateProvider.of(context);
                  capturedLang = state.params['lang'];
                  return Text('About (${capturedLang ?? "default"})');
                },
              );
            },
          ),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/about',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(capturedLang, null);
      expect(find.text('About (default)'), findsOneWidget);
    });

    testWidgets('matches wildcard route', (tester) async {
      final router = Unrouter(
        Routes([
          Unroute(
            path: 'files/*',
            factory: () => const Text('Files'),
          ),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/files/a/b/c',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Files'), findsOneWidget);
    });
  });
}
