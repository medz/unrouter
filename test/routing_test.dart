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

  group('Basic Routing', () {
    testWidgets('renders index route', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Index')),
          Inlet(path: 'about', factory: () => const Text('About')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Index'), findsOneWidget);
      expect(find.text('About'), findsNothing);
    });

    testWidgets('renders path route', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Index')),
          Inlet(path: 'about', factory: () => const Text('About')),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/about'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Index'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('navigates between routes', (tester) async {
      late Unrouter router;

      router = Unrouter(
        routes: [
          Inlet(factory: () => const Text('Index')),
          Inlet(path: 'about', factory: () => const Text('About')),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Index'), findsOneWidget);

      router.navigate(.parse('/about'));
      await tester.pumpAndSettle();

      expect(find.text('Index'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });
  });

  group('Nested Routing', () {
    testWidgets('renders nested routes with Outlet', (tester) async {
      Widget createConcerts() {
        return Column(
          children: [const Text('Concerts Layout'), const Outlet()],
        );
      }

      final router = Unrouter(
        routes: [
          Inlet(
            path: 'concerts',
            factory: createConcerts,
            children: [
              Inlet(factory: () => const Text('All Concerts')),
              Inlet(path: 'trending', factory: () => const Text('Trending')),
            ],
          ),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/concerts'))],
        ),
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
          children: [const Text('Concerts Layout'), const Outlet()],
        );
      }

      router = Unrouter(
        routes: [
          Inlet(
            path: 'concerts',
            factory: createConcerts,
            children: [
              Inlet(factory: () => const Text('All Concerts')),
              Inlet(path: 'trending', factory: () => const Text('Trending')),
            ],
          ),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/concerts'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Concerts Layout'), findsOneWidget);
      expect(find.text('All Concerts'), findsOneWidget);

      router.navigate(.parse('/concerts/trending'));
      await tester.pumpAndSettle();

      expect(find.text('Concerts Layout'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('All Concerts'), findsNothing);
    });
  });

  group('Layout Routes', () {
    testWidgets('layout route wraps children without path segment', (
      tester,
    ) async {
      Widget createAuth() {
        return Column(children: [const Text('Auth Layout'), const Outlet()]);
      }

      final router = Unrouter(
        routes: [
          Inlet(
            factory: createAuth,
            children: [
              Inlet(path: 'login', factory: () => const Text('Login')),
              Inlet(path: 'register', factory: () => const Text('Register')),
            ],
          ),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/login'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Auth Layout'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
    });

    testWidgets('navigates between layout children', (tester) async {
      late Unrouter router;

      Widget createAuth() {
        return Column(children: [const Text('Auth Layout'), const Outlet()]);
      }

      router = Unrouter(
        routes: [
          Inlet(
            factory: createAuth,
            children: [
              Inlet(path: 'login', factory: () => const Text('Login')),
              Inlet(path: 'register', factory: () => const Text('Register')),
            ],
          ),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/login'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Login'), findsOneWidget);

      router.navigate(.parse('/register'));
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
            final state = context.routeState;
            final id = state.params['id'] ?? 'unknown';
            return Text('User: $id');
          },
        );
      }

      final router = Unrouter(
        routes: [Inlet(path: ':id', factory: createUser)],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/123'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('User: 123'), findsOneWidget);
    });

    testWidgets('extracts params from nested routes', (tester) async {
      Widget createUsers() {
        return Column(children: [const Text('Users'), const Outlet()]);
      }

      Widget createUser() {
        return Builder(
          builder: (context) {
            final state = context.routeState;
            final id = state.params['id'] ?? 'unknown';
            return Text('User: $id');
          },
        );
      }

      final router = Unrouter(
        routes: [
          Inlet(
            path: 'users',
            factory: createUsers,
            children: [Inlet(path: ':id', factory: createUser)],
          ),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/users/123'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Users'), findsOneWidget);
      expect(find.text('User: 123'), findsOneWidget);
    });
  });

  group('Complex Nesting', () {
    testWidgets('handles multiple levels of nesting', (tester) async {
      Widget createApp() {
        return Column(children: [const Text('App'), const Outlet()]);
      }

      Widget createUsers() {
        return Column(children: [const Text('Users'), const Outlet()]);
      }

      Widget createUserDetail() {
        return Builder(
          builder: (context) {
            final state = context.routeState;
            final userId = state.params['userId'] ?? 'unknown';
            return Column(children: [Text('User: $userId'), const Outlet()]);
          },
        );
      }

      Widget createPost() {
        return Builder(
          builder: (context) {
            final state = context.routeState;
            final userId = state.params['userId'] ?? 'unknown';
            final postId = state.params['postId'] ?? 'unknown';
            return Text('Post: $postId by User: $userId');
          },
        );
      }

      final router = Unrouter(
        routes: [
          Inlet(
            factory: createApp,
            children: [
              Inlet(
                path: 'users',
                factory: createUsers,
                children: [
                  Inlet(
                    path: ':userId',
                    factory: createUserDetail,
                    children: [Inlet(path: ':postId', factory: createPost)],
                  ),
                ],
              ),
            ],
          ),
        ],
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/users/123/456'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('App'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('User: 123'), findsOneWidget);
      expect(find.text('Post: 456 by User: 123'), findsOneWidget);
    });
  });
}
