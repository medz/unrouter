import 'package:flutter/widgets.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrapRouter(Unrouter router) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Router.withConfig(config: router),
    );
  }

  group('Basic Routing', () {
    testWidgets('renders index route', (tester) async {
      final router = Unrouter(
        [
          Route.index(() => const Text('Index')),
          Route.path('about', () => const Text('About')),
        ],
        mode: HistoryMode.memory,
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Index'), findsOneWidget);
      expect(find.text('About'), findsNothing);
    });

    testWidgets('renders path route', (tester) async {
      final router = Unrouter(
        [
          Route.index(() => const Text('Index')),
          Route.path('about', () => const Text('About')),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/about',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Index'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('navigates between routes', (tester) async {
      late Unrouter router;

      router = Unrouter(
        [
          Route.index(() => const Text('Index')),
          Route.path('about', () => const Text('About')),
        ],
        mode: HistoryMode.memory,
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Index'), findsOneWidget);

      router.push('/about');
      await tester.pumpAndSettle();

      expect(find.text('Index'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });
  });

  group('Nested Routing', () {
    testWidgets('renders nested routes with RouterView', (tester) async {
      Widget createConcerts() {
        return Column(
          children: [
            const Text('Concerts Layout'),
            const RouterView(),
          ],
        );
      }

      final router = Unrouter(
        [
          Route.nested('concerts', createConcerts, [
            Route.index(() => const Text('All Concerts')),
            Route.path('trending', () => const Text('Trending')),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/concerts',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Concerts Layout'), findsOneWidget);
      expect(find.text('All Concerts'), findsOneWidget);
      expect(find.text('Trending'), findsNothing);
    });

    testWidgets('navigates between nested routes', (tester) async {
      late Unrouter router;

      Widget createConcerts() {
        return Column(
          children: [
            const Text('Concerts Layout'),
            const RouterView(),
          ],
        );
      }

      router = Unrouter(
        [
          Route.nested('concerts', createConcerts, [
            Route.index(() => const Text('All Concerts')),
            Route.path('trending', () => const Text('Trending')),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/concerts',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Concerts Layout'), findsOneWidget);
      expect(find.text('All Concerts'), findsOneWidget);

      router.push('/concerts/trending');
      await tester.pumpAndSettle();

      expect(find.text('Concerts Layout'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('All Concerts'), findsNothing);
    });
  });

  group('Layout Routes', () {
    testWidgets('layout route wraps children without path segment', (tester) async {
      Widget createAuth() {
        return Column(
          children: [
            const Text('Auth Layout'),
            const RouterView(),
          ],
        );
      }

      final router = Unrouter(
        [
          Route.layout(createAuth, [
            Route.path('login', () => const Text('Login')),
            Route.path('register', () => const Text('Register')),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/login',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Auth Layout'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
    });

    testWidgets('navigates between layout children', (tester) async {
      late Unrouter router;

      Widget createAuth() {
        return Column(
          children: [
            const Text('Auth Layout'),
            const RouterView(),
          ],
        );
      }

      router = Unrouter(
        [
          Route.layout(createAuth, [
            Route.path('login', () => const Text('Login')),
            Route.path('register', () => const Text('Register')),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/login',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Login'), findsOneWidget);

      router.push('/register');
      await tester.pumpAndSettle();

      expect(find.text('Auth Layout'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    });
  });

  group('Dynamic Params', () {
    testWidgets('extracts params from path', (tester) async {
      Widget createUser() {
        return Builder(
          builder: (context) {
            final state = RouterStateProvider.of(context);
            final id = state.params['id'] ?? 'unknown';
            return Text('User: $id');
          },
        );
      }

      final router = Unrouter(
        [
          Route.path(':id', createUser),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/123',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('User: 123'), findsOneWidget);
    });

    testWidgets('extracts params from nested routes', (tester) async {
      Widget createUsers() {
        return Column(
          children: [
            const Text('Users'),
            const RouterView(),
          ],
        );
      }

      Widget createUser() {
        return Builder(
          builder: (context) {
            final state = RouterStateProvider.of(context);
            final id = state.params['id'] ?? 'unknown';
            return Text('User: $id');
          },
        );
      }

      final router = Unrouter(
        [
          Route.nested('users', createUsers, [
            Route.path(':id', createUser),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/users/123',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Users'), findsOneWidget);
      expect(find.text('User: 123'), findsOneWidget);
    });
  });

  group('Complex Nesting', () {
    testWidgets('handles multiple levels of nesting', (tester) async {
      Widget createApp() {
        return Column(
          children: [
            const Text('App'),
            const RouterView(),
          ],
        );
      }

      Widget createUsers() {
        return Column(
          children: [
            const Text('Users'),
            const RouterView(),
          ],
        );
      }

      Widget createUserDetail() {
        return Builder(
          builder: (context) {
            final state = RouterStateProvider.of(context);
            final userId = state.params['userId'] ?? 'unknown';
            return Column(
              children: [
                Text('User: $userId'),
                const RouterView(),
              ],
            );
          },
        );
      }

      Widget createPost() {
        return Builder(
          builder: (context) {
            final state = RouterStateProvider.of(context);
            final userId = state.params['userId'] ?? 'unknown';
            final postId = state.params['postId'] ?? 'unknown';
            return Text('Post: $postId by User: $userId');
          },
        );
      }

      final router = Unrouter(
        [
          Route.layout(createApp, [
            Route.nested('users', createUsers, [
              Route.nested(':userId', createUserDetail, [
                Route.path(':postId', createPost),
              ]),
            ]),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/users/123/456',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('App'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('User: 123'), findsOneWidget);
      expect(find.text('Post: 456 by User: 123'), findsOneWidget);
    });
  });
}
