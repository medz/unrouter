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

  group('Layout Rebuild Optimization', () {
    testWidgets(
      'layout route does not rebuild when switching between child routes',
      (tester) async {
        int layoutBuildCount = 0;
        int loginBuildCount = 0;
        int registerBuildCount = 0;

        Widget buildAuthLayout() {
          layoutBuildCount++;
          return Column(
            children: [
              const Text('Auth Header'),
              const Expanded(child: RouterView()),
            ],
          );
        }

        Widget buildLogin() {
          loginBuildCount++;
          return const Text('Login');
        }

        Widget buildRegister() {
          registerBuildCount++;
          return const Text('Register');
        }

        final router = Unrouter(
          [
            Route.index(() => const Text('Home')),
            Route.layout(buildAuthLayout, [
              Route.path('login', buildLogin),
              Route.path('register', buildRegister),
            ]),
          ],
          mode: HistoryMode.memory,
          initialLocation: '/login',
        );

        // Initial render at /login
        await tester.pumpWidget(wrapRouter(router));
        expect(find.text('Auth Header'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(loginBuildCount, 1);
        expect(registerBuildCount, 0);

        // Navigate to /register (push - creates new history entry)
        router.push('/register');
        await tester.pumpAndSettle();

        expect(find.text('Auth Header'), findsOneWidget);
        expect(find.text('Login'), findsNothing);
        expect(find.text('Register'), findsOneWidget);

        // IMPORTANT: Layout should NOT rebuild when switching between children
        expect(
          layoutBuildCount,
          1,
          reason:
              'Layout should not rebuild when switching between child routes',
        );
        expect(registerBuildCount, 1);

        // Navigate back to /login using back() - should reuse existing widget
        router.back();
        await tester.pumpAndSettle();

        expect(find.text('Auth Header'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Register'), findsNothing);

        // Layout and Login should not rebuild - back navigation reuses cached widgets
        expect(
          layoutBuildCount,
          1,
          reason:
              'Layout should not rebuild when switching between child routes',
        );
        expect(
          loginBuildCount,
          1,
          reason: 'Login should not rebuild when navigating back (Stack mode)',
        );
      },
    );

    testWidgets(
      'nested route does not rebuild when switching between child routes',
      (tester) async {
        int nestedBuildCount = 0;
        int child1BuildCount = 0;
        int child2BuildCount = 0;

        Widget buildNested() {
          nestedBuildCount++;
          return Column(
            children: [
              const Text('Nested Header'),
              const Expanded(child: RouterView()),
            ],
          );
        }

        Widget buildChild1() {
          child1BuildCount++;
          return const Text('Child 1');
        }

        Widget buildChild2() {
          child2BuildCount++;
          return const Text('Child 2');
        }

        final router = Unrouter(
          [
            Route.index(() => const Text('Home')),
            Route.nested('parent', buildNested, [
              Route.path('child1', buildChild1),
              Route.path('child2', buildChild2),
            ]),
          ],
          mode: HistoryMode.memory,
          initialLocation: '/parent/child1',
        );

        // Initial render at /parent/child1
        await tester.pumpWidget(wrapRouter(router));
        expect(find.text('Nested Header'), findsOneWidget);
        expect(find.text('Child 1'), findsOneWidget);
        expect(nestedBuildCount, 1);
        expect(child2BuildCount, 0);

        // Navigate to /parent/child2
        router.push('/parent/child2');
        await tester.pumpAndSettle();

        expect(find.text('Nested Header'), findsOneWidget);
        expect(find.text('Child 1'), findsNothing);
        expect(find.text('Child 2'), findsOneWidget);

        // Nested route should NOT rebuild when switching between children
        expect(
          nestedBuildCount,
          1,
          reason:
              'Nested route should not rebuild when switching between child routes',
        );
        expect(child2BuildCount, 1);
      },
    );

    testWidgets(
      'push after back recreates leaf route but not layout',
      (tester) async {
        int layoutBuildCount = 0;
        int loginBuildCount = 0;
        int registerBuildCount = 0;

        Widget buildAuthLayout() {
          layoutBuildCount++;
          return Column(
            children: [
              const Text('Auth Header'),
              const Expanded(child: RouterView()),
            ],
          );
        }

        Widget buildLogin() {
          loginBuildCount++;
          return const Text('Login');
        }

        Widget buildRegister() {
          registerBuildCount++;
          return const Text('Register');
        }

        final router = Unrouter(
          [
            Route.index(() => const Text('Home')),
            Route.layout(buildAuthLayout, [
              Route.path('login', buildLogin),
              Route.path('register', buildRegister),
            ]),
          ],
          mode: HistoryMode.memory,
          initialLocation: '/login',
        );

        // Initial render at /login
        await tester.pumpWidget(wrapRouter(router));
        expect(find.text('Auth Header'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(loginBuildCount, 1);
        expect(registerBuildCount, 0);

        // Push to /register - should create a new leaf widget.
        router.push('/register');
        await tester.pumpAndSettle();
        expect(find.text('Register'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(registerBuildCount, 1);

        // Back to /login - should reuse existing widgets.
        router.back();
        await tester.pumpAndSettle();
        expect(find.text('Login'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(loginBuildCount, 1);

        // Push to /register again (after back) - this is a new history entry,
        // so leaf should be recreated, but layout should still be reused.
        router.push('/register');
        await tester.pumpAndSettle();
        expect(find.text('Register'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(registerBuildCount, 2);

        // Push to /login again - new history entry, new leaf widget.
        router.push('/login');
        await tester.pumpAndSettle();
        expect(find.text('Login'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(loginBuildCount, 2);

        // Back twice should reuse cached leaf widgets (no additional builds).
        router.back();
        await tester.pumpAndSettle();
        expect(find.text('Register'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(registerBuildCount, 2);

        router.back();
        await tester.pumpAndSettle();
        expect(find.text('Login'), findsOneWidget);
        expect(layoutBuildCount, 1);
        expect(loginBuildCount, 2);
      },
    );
  });
}
