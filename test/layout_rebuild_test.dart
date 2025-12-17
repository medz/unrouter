import 'package:flutter/widgets.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
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
          children: [Text(header), const Expanded(child: RouterView())],
        ),
      );
    };
  }

  Widget Function() trackedLeafFactory(String label, _Counts counts) {
    return () {
      counts.factory++;
      return _BuildCounter(
        onBuild: () => counts.build++,
        child: Text(label),
      );
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
        [
          Route.layout(trackedLayoutFactory('Auth', auth), [
            Route.path('login', trackedLeafFactory('Login', login)),
            Route.path('register', trackedLeafFactory('Register', register)),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/login',
      );

      await tester.pumpWidget(wrapRouter(router));
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 0, build: 0);

      router.push('/register');
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.text('Register'), findsOneWidget);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 1, build: 1);

      router.back();
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 1, build: 1);

      router.push('/register');
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.text('Register'), findsOneWidget);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 1, build: 1);
      expectCounts(register, name: 'Register', factory: 2, build: 2);

      router.push('/login');
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 2, build: 2);
      expectCounts(register, name: 'Register', factory: 2, build: 2);

      router.back();
      await tester.pump();
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.text('Register'), findsOneWidget);
      expectCounts(auth, name: 'Auth', factory: 1, build: 1);
      expectCounts(login, name: 'Login', factory: 2, build: 2);
      expectCounts(register, name: 'Register', factory: 2, build: 2);

      router.back();
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
        [
          Route.nested('parent', trackedLayoutFactory('Parent', parent), [
            Route.path('child1', trackedLeafFactory('Child 1', child1)),
            Route.path('child2', trackedLeafFactory('Child 2', child2)),
          ]),
        ],
        mode: HistoryMode.memory,
        initialLocation: '/parent/child1',
      );

      await tester.pumpWidget(wrapRouter(router));
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsNothing);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 0, build: 0);

      router.push('/parent/child2');
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsNothing);
      expect(find.text('Child 2'), findsOneWidget);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 1, build: 1);

      router.back();
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsNothing);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 1, build: 1);

      router.push('/parent/child2');
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsNothing);
      expect(find.text('Child 2'), findsOneWidget);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 1, build: 1);
      expectCounts(child2, name: 'Child 2', factory: 2, build: 2);

      router.push('/parent/child1');
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsNothing);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 2, build: 2);
      expectCounts(child2, name: 'Child 2', factory: 2, build: 2);

      router.back();
      await tester.pump();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child 1'), findsNothing);
      expect(find.text('Child 2'), findsOneWidget);
      expectCounts(parent, name: 'Parent', factory: 1, build: 1);
      expectCounts(child1, name: 'Child 1', factory: 2, build: 2);
      expectCounts(child2, name: 'Child 2', factory: 2, build: 2);

      router.back();
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

