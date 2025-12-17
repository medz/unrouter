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

  group('Nested Routing', () {
    testWidgets('matches nested route', (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            const Text('Auth Layout'),
            Routes([
              Unroute(path: 'login', factory: () => const Text('Login')),
              Unroute(path: 'register', factory: () => const Text('Register')),
            ]),
          ],
        );
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'auth', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/auth/login',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Auth Layout'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
    });

    testWidgets('matches different nested route', (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            const Text('Auth Layout'),
            Routes([
              Unroute(path: 'login', factory: () => const Text('Login')),
              Unroute(path: 'register', factory: () => const Text('Register')),
            ]),
          ],
        );
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'auth', factory: createLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/auth/register',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Auth Layout'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('deeply nested routes', (tester) async {
      Widget createPostsLayout() {
        return Column(
          children: [
            const Text('Posts Layout'),
            Routes([
              Unroute(path: ':postId', factory: () {
                return Builder(
                  builder: (context) {
                    final state = RouterStateProvider.of(context);
                    return Text('Post: ${state.params['postId']}');
                  },
                );
              }),
            ]),
          ],
        );
      }

      Widget createUserLayout() {
        return Column(
          children: [
            const Text('User Layout'),
            Routes([
              Unroute(path: 'posts', factory: createPostsLayout),
            ]),
          ],
        );
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'users/:userId', factory: createUserLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/users/alice/posts/123',
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('User Layout'), findsOneWidget);
      expect(find.text('Posts Layout'), findsOneWidget);
      expect(find.text('Post: 123'), findsOneWidget);
    });

    testWidgets('nested routes with params at each level', (tester) async {
      late Map<String, String> capturedParams;

      Widget createPostLayout() {
        return Builder(
          builder: (context) {
            final state = RouterStateProvider.of(context);
            capturedParams = state.params;
            return Column(
              children: [
                Text('User: ${state.params['userId']}'),
                Text('Post: ${state.params['postId']}'),
              ],
            );
          },
        );
      }

      Widget createUserLayout() {
        return Routes([
          Unroute(path: 'posts/:postId', factory: createPostLayout),
        ]);
      }

      final router = Unrouter(
        Routes([
          Unroute(path: 'users/:userId', factory: createUserLayout),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/users/bob/posts/456',
      );

      await tester.pumpWidget(wrapRouter(router));

      // Both params should be captured
      expect(capturedParams['userId'], 'bob');
      expect(capturedParams['postId'], '456');
      expect(find.text('User: bob'), findsOneWidget);
      expect(find.text('Post: 456'), findsOneWidget);
    });

    testWidgets('nested index routes', (tester) async {
      Widget createLayout() {
        return Column(
          children: [
            const Text('Layout'),
            Routes([
              Unroute(path: null, factory: () => const Text('Index')),
              Unroute(path: 'page', factory: () => const Text('Page')),
            ]),
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
      expect(find.text('Page'), findsNothing);
    });
  });
}
