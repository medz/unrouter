import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

class _Counts {
  int factory = 0;
  int build = 0;
}

class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild, required this.child});

  final void Function() onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}

void main() {
  Widget wrapRouter(Unrouter router) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Router.withConfig(config: router),
    );
  }

  Widget Function() trackedLayoutFactory(String header, _Counts counts) {
    return () {
      counts.factory++;
      return _BuildCounter(
        onBuild: () => counts.build++,
        child: Column(
          children: [
            Text(header),
            const Expanded(child: Outlet()),
          ],
        ),
      );
    };
  }

  Widget Function() trackedLeafFactory(String label, _Counts counts) {
    return () {
      counts.factory++;
      return _BuildCounter(onBuild: () => counts.build++, child: Text(label));
    };
  }

  void expectCounts(
    _Counts counts, {
    required String name,
    required int factory,
    required int build,
  }) {
    expect(counts.factory, factory, reason: '$name factory count mismatch');
    expect(counts.build, build, reason: '$name build count mismatch');
  }

  group('Layout rebuild optimization', () {
    testWidgets('layout route: factory + build counts', (tester) async {
      final auth = _Counts();
      final login = _Counts();
      final register = _Counts();

      final router = Unrouter(
        routes: RouteIndex.fromRoutes([
          Inlet(
            factory: trackedLayoutFactory('Auth', auth),
            children: [
              Inlet(path: 'login', factory: trackedLeafFactory('Login', login)),
              Inlet(
                path: 'register',
                factory: trackedLeafFactory('Register', register),
              ),
            ],
          ),
        ]),
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/login'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 0, build: 0);

      router.navigate(path: '/register');
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.text('Register'), findsOneWidget);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 1, build: 1);

      router.navigate.back();
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 1, build: 1);

      router.navigate(path: '/register');
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.text('Register'), findsOneWidget);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 2, build: 2);

      router.navigate(path: '/login');
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 2, build: 2);
      expectCounts(register, name: 'Register', factory: 2, build: 2);

      router.navigate.back();
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.text('Register'), findsOneWidget);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 2, build: 2);
      expectCounts(register, name: 'Register', factory: 2, build: 2);

      router.navigate.back();
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 2, build: 2);
      expectCounts(register, name: 'Register', factory: 2, build: 2);
    });

    testWidgets('nested route: factory + build counts', (tester) async {
      final parent = _Counts();
      final child1 = _Counts();
      final child2 = _Counts();

      final router = Unrouter(
        routes: RouteIndex.fromRoutes([
          Inlet(
            path: 'parent',
            factory: trackedLayoutFactory('Parent', parent),
            children: [
              Inlet(
                path: 'child1',
                factory: trackedLeafFactory('Child 1', child1),
              ),
              Inlet(
                path: 'child2',
                factory: trackedLeafFactory('Child 2', child2),
              ),
            ],
          ),
        ]),
        history: MemoryHistory(
          initialEntries: [RouteInformation(uri: Uri.parse('/parent/child1'))],
        ),
      );

      await tester.pumpWidget(wrapRouter(router));
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsNothing);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 0, build: 0);

      router.navigate(path: '/parent/child2');
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsNothing);
      expect(find.text('Child 2'), findsOneWidget);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 1, build: 1);

      router.navigate.back();
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsNothing);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 1, build: 1);

      router.navigate(path: '/parent/child2');
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsNothing);
      expect(find.text('Child 2'), findsOneWidget);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 2, build: 2);

      router.navigate(path: '/parent/child1');
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsNothing);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 2, build: 2);
      expectCounts(child2, name: 'Child 2', factory: 2, build: 2);

      router.navigate.back();
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsNothing);
      expect(find.text('Child 2'), findsOneWidget);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 2, build: 2);
      expectCounts(child2, name: 'Child 2', factory: 2, build: 2);

      router.navigate.back();
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsNothing);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 2, build: 2);
      expectCounts(child2, name: 'Child 2', factory: 2, build: 2);
    });
  });
}
