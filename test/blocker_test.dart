import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  setUp(() {
    _NestedRoutesHost.onLeafPop = null;
    _HybridHost.onLeafPop = null;
    _SectionShell.onSectionPop = null;
    _DetailShell.leafCompleter = null;
  });

  Widget wrap(Unrouter router) {
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> pumpPop(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  testWidgets('route blocker cancels back navigation', (tester) async {
    var willPopCalls = 0;
    var blockedCalls = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'about',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              willPopCalls++;
              return false;
            },
            onBlocked: (ctx) async {
              blockedCalls++;
            },
            child: const Text('About'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/about');
    await pumpPop(tester);
    expect(find.text('About'), findsOneWidget);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('About'), findsOneWidget);
    expect(router.history.location.uri.path, '/about');
    expect(willPopCalls, 1);
    expect(blockedCalls, 1);
  });

  testWidgets('route blocker allows back navigation', (tester) async {
    var willPopCalls = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'about',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              willPopCalls++;
              return true;
            },
            child: const Text('About'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/about');
    await pumpPop(tester);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationSuccess>());
    expect(find.text('Home'), findsOneWidget);
    expect(router.history.location.uri.path, '/');
    expect(willPopCalls, 1);
  });

  testWidgets('layout blocker does not block child back navigation', (
    tester,
  ) async {
    var layoutCalled = false;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              layoutCalled = true;
              return false;
            },
            child: const Outlet(),
          ),
          children: [
            Inlet(path: 'a', factory: () => const Text('A')),
            Inlet(path: 'b', factory: () => const Text('B')),
          ],
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/a');
    await pumpPop(tester);
    await router.navigate(path: '/b');
    await pumpPop(tester);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationSuccess>());
    expect(find.text('A'), findsOneWidget);
    expect(router.history.location.uri.path, '/a');
    expect(layoutCalled, isFalse);
  });

  testWidgets('route blocker works inside Routes widget', (tester) async {
    var called = false;
    final router = Unrouter(
      history: MemoryHistory(),
      child: Routes([
        Inlet(factory: () => const Text('Index')),
        Inlet(
          path: 'b',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              called = true;
              return false;
            },
            child: const Text('B'),
          ),
        ),
      ]),
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/b');
    await pumpPop(tester);
    expect(find.text('B'), findsOneWidget);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('B'), findsOneWidget);
    expect(router.history.location.uri.path, '/b');
    expect(called, isTrue);
  });

  testWidgets('go(0) triggers blockers', (tester) async {
    var called = false;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              called = true;
              return false;
            },
            child: const Text('Home'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    final navigation = router.navigate.go(0);
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(called, isTrue);
  });

  testWidgets('blocker cancel prevents guard on back', (tester) async {
    var guardCalled = 0;
    var blockerCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      guards: [
        (context) {
          guardCalled++;
          return GuardResult.allow;
        },
      ],
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'a',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              blockerCalled++;
              return false;
            },
            child: const Text('A'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/a');
    await pumpPop(tester);
    guardCalled = 0;
    blockerCalled = 0;

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('A'), findsOneWidget);
    expect(guardCalled, 0);
    expect(blockerCalled, 1);
  });

  testWidgets('blocker allows but guard cancels on back', (tester) async {
    var guardCalled = 0;
    var blockerCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      guards: [
        (context) {
          guardCalled++;
          if (context.to.uri.path == '/') {
            return GuardResult.cancel;
          }
          return GuardResult.allow;
        },
      ],
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'a',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              blockerCalled++;
              return true;
            },
            child: const Text('A'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/a');
    await pumpPop(tester);
    guardCalled = 0;
    blockerCalled = 0;

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('A'), findsOneWidget);
    expect(router.history.location.uri.path, '/a');
    expect(guardCalled, 1);
    expect(blockerCalled, 1);
  });

  testWidgets('blocker allows but guard redirects on back', (tester) async {
    var guardCalled = 0;
    var blockerCalled = 0;
    String? lastFromPath;
    String? lastToPath;
    final router = Unrouter(
      history: MemoryHistory(
        initialEntries: [
          RouteInformation(uri: .parse('/blocked')),
          RouteInformation(uri: .parse('/a')),
        ],
      ),
      guards: [
        (context) {
          guardCalled++;
          lastFromPath = context.from.uri.path;
          lastToPath = context.to.uri.path;
          if (context.to.uri.path == '/blocked') {
            return GuardResult.redirect(Uri.parse('/login'));
          }
          return GuardResult.allow;
        },
      ],
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'blocked', factory: () => const Text('Blocked')),
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(
          path: 'a',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              blockerCalled++;
              return true;
            },
            child: const Text('A'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await pumpPop(tester);
    guardCalled = 0;
    blockerCalled = 0;
    lastFromPath = null;
    lastToPath = null;

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(guardCalled, 1);
    expect(blockerCalled, 1);
    expect(lastFromPath, '/a');
    expect(lastToPath, '/blocked');
    expect(result, isA<NavigationRedirected>());
    final redirected = result as NavigationRedirected;
    expect(redirected.action, HistoryAction.replace);
    expect(find.text('Login'), findsOneWidget);
    expect(router.history.location.uri.path, '/login');
  });

  testWidgets('blocker in Routes works with global guard', (tester) async {
    var guardCalled = 0;
    var blockerCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      guards: [
        (context) {
          guardCalled++;
          if (context.to.uri.path == '/') {
            return GuardResult.cancel;
          }
          return GuardResult.allow;
        },
      ],
      child: Routes([
        Inlet(factory: () => const Text('Index')),
        Inlet(
          path: 'b',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              blockerCalled++;
              return true;
            },
            child: const Text('B'),
          ),
        ),
      ]),
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/b');
    await pumpPop(tester);
    guardCalled = 0;
    blockerCalled = 0;

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('B'), findsOneWidget);
    expect(router.history.location.uri.path, '/b');
    expect(guardCalled, 1);
    expect(blockerCalled, 1);
  });

  testWidgets('nested blockers respect child-first order', (tester) async {
    var parentCalled = 0;
    var childCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'nested',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              parentCalled++;
              return false;
            },
            child: RouteBlocker(
              onWillPop: (ctx) async {
                childCalled++;
                return false;
              },
              child: const Text('Nested'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/nested');
    await pumpPop(tester);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('Nested'), findsOneWidget);
    expect(childCalled, 1);
    expect(parentCalled, 0);
  });

  testWidgets('nested blocker parent runs when child allows', (tester) async {
    var parentCalled = 0;
    var childCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'nested',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              parentCalled++;
              return false;
            },
            child: RouteBlocker(
              onWillPop: (ctx) async {
                childCalled++;
                return true;
              },
              child: const Text('Nested'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/nested');
    await pumpPop(tester);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('Nested'), findsOneWidget);
    expect(childCalled, 1);
    expect(parentCalled, 1);
  });

  testWidgets('nested Routes leaf blocker blocks leaving parent scope', (
    tester,
  ) async {
    var leafCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      child: Routes([
        Inlet(factory: () => const Text('Index')),
        Inlet(path: 'parent', factory: () => const _NestedRoutesHost()),
      ]),
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/parent/child');
    await pumpPop(tester);
    expect(find.text('Child'), findsOneWidget);

    _NestedRoutesHost.onLeafPop = (ctx) async {
      leafCalled++;
      return false;
    };

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('Child'), findsOneWidget);
    expect(router.history.location.uri.path, '/parent/child');
    expect(leafCalled, 1);
  });

  testWidgets('parent blocker does not block nested route switches', (
    tester,
  ) async {
    var parentCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      child: Routes([
        Inlet(factory: () => const Text('Index')),
        Inlet(
          path: 'parent',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              parentCalled++;
              return false;
            },
            child: const _NestedRoutesHost(),
          ),
        ),
      ]),
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/parent/child');
    await pumpPop(tester);
    await router.navigate(path: '/parent/other');
    await pumpPop(tester);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationSuccess>());
    expect(find.text('Child'), findsOneWidget);
    expect(router.history.location.uri.path, '/parent/child');
    expect(parentCalled, 0);
  });

  testWidgets('hybrid blocker prevents guard on back', (tester) async {
    var guardCalled = 0;
    var blockerCalled = 0;
    _HybridHost.onLeafPop = (ctx) async {
      blockerCalled++;
      return false;
    };
    final router = Unrouter(
      history: MemoryHistory(),
      guards: [
        (context) {
          guardCalled++;
          return GuardResult.allow;
        },
      ],
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'app', factory: () => const _HybridHost()),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/app/child');
    await pumpPop(tester);
    guardCalled = 0;
    blockerCalled = 0;

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('AppChild'), findsOneWidget);
    expect(router.history.location.uri.path, '/app/child');
    expect(blockerCalled, 1);
    expect(guardCalled, 0);
  });

  testWidgets('hybrid blocker allows but guard cancels on back', (
    tester,
  ) async {
    var guardCalled = 0;
    var blockerCalled = 0;
    String? lastToPath;
    _HybridHost.onLeafPop = (ctx) async {
      blockerCalled++;
      return true;
    };
    final router = Unrouter(
      history: MemoryHistory(),
      guards: [
        (context) {
          guardCalled++;
          lastToPath = context.to.uri.path;
          if (context.to.uri.path == '/') {
            return GuardResult.cancel;
          }
          return GuardResult.allow;
        },
      ],
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'app', factory: () => const _HybridHost()),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/app/child');
    await pumpPop(tester);
    guardCalled = 0;
    blockerCalled = 0;
    lastToPath = null;

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('AppChild'), findsOneWidget);
    expect(router.history.location.uri.path, '/app/child');
    expect(blockerCalled, 1);
    expect(guardCalled, 1);
    expect(lastToPath, '/');
  });

  testWidgets('hybrid parent blocker does not block nested route switches', (
    tester,
  ) async {
    var parentCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'app',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              parentCalled++;
              return false;
            },
            child: const _HybridHost(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/app/child');
    await pumpPop(tester);
    await router.navigate(path: '/app/other');
    await pumpPop(tester);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationSuccess>());
    expect(find.text('AppChild'), findsOneWidget);
    expect(router.history.location.uri.path, '/app/child');
    expect(parentCalled, 0);
  });

  testWidgets('hybrid parent blocker blocks leaving scope', (tester) async {
    var parentCalled = 0;
    final router = Unrouter(
      history: MemoryHistory(),
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'app',
          factory: () => RouteBlocker(
            onWillPop: (ctx) async {
              parentCalled++;
              return false;
            },
            child: const _HybridHost(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await router.navigate(path: '/app/child');
    await pumpPop(tester);

    final navigation = router.navigate.back();
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationCancelled>());
    expect(find.text('AppChild'), findsOneWidget);
    expect(router.history.location.uri.path, '/app/child');
    expect(parentCalled, 1);
  });

  testWidgets(
    'multi-layer hybrid async blocker cancels before guard redirect',
    (tester) async {
      var guardCalled = 0;
      final completer = Completer<bool>();
      _DetailShell.leafCompleter = completer;
      final router = Unrouter(
        history: MemoryHistory(
          initialEntries: [
            RouteInformation(uri: .parse('/app/section/detail')),
            RouteInformation(uri: .parse('/app/section/detail/child')),
          ],
          initialIndex: 1,
        ),
        guards: [
          (context) {
            guardCalled++;
            if (context.to.uri.path == '/app/section/detail') {
              return GuardResult.redirect(Uri.parse('/login'));
            }
            return GuardResult.allow;
          },
        ],
        routes: [
          Inlet(factory: () => const Text('Home')),
          Inlet(path: 'login', factory: () => const Text('Login')),
          Inlet(
            path: 'app',
            factory: () => const _DeepHybridHost(),
            children: [
              Inlet(path: 'section', factory: () => const _SectionShell()),
            ],
          ),
        ],
      );

      await tester.pumpWidget(wrap(router));
      await pumpPop(tester);
      expect(find.text('DetailChild'), findsOneWidget);
      guardCalled = 0;

      final navigation = router.navigate.back();
      await pumpPop(tester);

      completer.complete(false);
      await pumpPop(tester);
      final result = await navigation;

      expect(result, isA<NavigationCancelled>());
      expect(router.history.location.uri.path, '/app/section/detail/child');
      expect(find.text('DetailChild'), findsOneWidget);
      expect(guardCalled, 0);
    },
  );

  testWidgets('multi-layer hybrid async blocker allows guard redirect', (
    tester,
  ) async {
    var guardCalled = 0;
    final completer = Completer<bool>();
    _DetailShell.leafCompleter = completer;
    final router = Unrouter(
      history: MemoryHistory(
        initialEntries: [
          RouteInformation(uri: .parse('/app/section/detail')),
          RouteInformation(uri: .parse('/app/section/detail/child')),
        ],
        initialIndex: 1,
      ),
      guards: [
        (context) {
          guardCalled++;
          if (context.to.uri.path == '/app/section/detail') {
            return GuardResult.redirect(Uri.parse('/login'));
          }
          return GuardResult.allow;
        },
      ],
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(
          path: 'app',
          factory: () => const _DeepHybridHost(),
          children: [
            Inlet(path: 'section', factory: () => const _SectionShell()),
          ],
        ),
      ],
    );

    await tester.pumpWidget(wrap(router));
    await pumpPop(tester);
    expect(find.text('DetailChild'), findsOneWidget);
    guardCalled = 0;

    final navigation = router.navigate.back();
    await pumpPop(tester);

    completer.complete(true);
    await pumpPop(tester);
    final result = await navigation;

    expect(result, isA<NavigationRedirected>());
    expect(router.history.location.uri.path, '/login');
    expect(find.text('Login'), findsOneWidget);
    expect(guardCalled, 1);
  });
}

class _NestedRoutesHost extends StatelessWidget {
  const _NestedRoutesHost();

  static RouteBlockerCallback? onLeafPop;

  @override
  Widget build(BuildContext context) {
    return Routes([
      Inlet(factory: () => const Text('ParentIndex')),
      Inlet(
        path: 'child',
        factory: () => RouteBlocker(
          onWillPop: (ctx) async {
            final callback = onLeafPop;
            if (callback != null) {
              return callback(ctx);
            }
            return true;
          },
          child: const Text('Child'),
        ),
      ),
      Inlet(path: 'other', factory: () => const Text('Other')),
    ]);
  }
}

class _HybridHost extends StatelessWidget {
  const _HybridHost();

  static RouteBlockerCallback? onLeafPop;

  @override
  Widget build(BuildContext context) {
    return Routes([
      Inlet(factory: () => const Text('AppIndex')),
      Inlet(
        path: 'child',
        factory: () => RouteBlocker(
          onWillPop: (ctx) async {
            final callback = onLeafPop;
            if (callback != null) {
              return callback(ctx);
            }
            return true;
          },
          child: const Text('AppChild'),
        ),
      ),
      Inlet(path: 'other', factory: () => const Text('AppOther')),
    ]);
  }
}

class _DeepHybridHost extends StatelessWidget {
  const _DeepHybridHost();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('AppShell'),
        const Expanded(child: Outlet()),
      ],
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell();

  static RouteBlockerCallback? onSectionPop;

  @override
  Widget build(BuildContext context) {
    final routes = Routes([
      Inlet(factory: () => const Text('SectionIndex')),
      Inlet(path: 'detail', factory: () => const _DetailShell()),
    ]);
    final callback = onSectionPop;
    if (callback == null) {
      return routes;
    }
    return RouteBlocker(onWillPop: callback, child: routes);
  }
}

class _DetailShell extends StatelessWidget {
  const _DetailShell();

  static Completer<bool>? leafCompleter;

  @override
  Widget build(BuildContext context) {
    return Routes([
      Inlet(factory: () => const Text('DetailIndex')),
      Inlet(
        path: 'child',
        factory: () => RouteBlocker(
          onWillPop: (ctx) async {
            final completer = leafCompleter;
            if (completer != null) {
              return completer.future;
            }
            return true;
          },
          child: const Text('DetailChild'),
        ),
      ),
      Inlet(path: 'other', factory: () => const Text('DetailOther')),
    ]);
  }
}
