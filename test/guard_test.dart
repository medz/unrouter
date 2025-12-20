import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrap(Unrouter router) {
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> pumpGuards(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  testWidgets('guard allow permits navigation', (tester) async {
    var called = false;
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) {
          called = true;
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));
    expect(find.text('Home'), findsOneWidget);

    final result = await router.navigate(.parse('/login'));
    await pumpGuards(tester);

    expect(called, isTrue);
    expect(result, isA<NavigationSuccess>());
    final success = result as NavigationSuccess;
    expect(success.action, HistoryAction.push);
    expect(find.text('Login'), findsOneWidget);
    expect(router.history.location.uri.path, '/login');
  });

  testWidgets('guard cancel blocks navigation', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [(context) => GuardResult.cancel],
    );

    await tester.pumpWidget(wrap(router));
    expect(find.text('Home'), findsOneWidget);

    final result = await router.navigate(.parse('/login'));
    await pumpGuards(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(result, isA<NavigationCancelled>());
    expect(router.history.location.uri.path, '/');
    expect(router.history.index, 0);
  });

  testWidgets('guard chain stops after cancel', (tester) async {
    var firstCalled = false;
    var secondCalled = false;
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) {
          firstCalled = true;
          return GuardResult.cancel;
        },
        (context) {
          secondCalled = true;
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));

    final result = await router.navigate(.parse('/login'));
    await pumpGuards(tester);

    expect(firstCalled, isTrue);
    expect(secondCalled, isFalse);
    expect(result, isA<NavigationCancelled>());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(router.history.location.uri.path, '/');
  });

  testWidgets('async guard waits for completion', (tester) async {
    final completer = Completer<GuardResult>();
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [(context) => completer.future],
    );

    await tester.pumpWidget(wrap(router));

    final navigation = router.navigate(.parse('/login'));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Login'), findsNothing);

    completer.complete(GuardResult.allow);
    final result = await navigation;
    await pumpGuards(tester);

    expect(result, isA<NavigationSuccess>());
    expect(find.text('Login'), findsOneWidget);
    expect(router.history.location.uri.path, '/login');
  });

  testWidgets('GuardResult error is handled as guard result', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) {
          return Future<GuardResult>.error(GuardResult.cancel);
        },
      ],
    );

    await tester.pumpWidget(wrap(router));

    final result = await router.navigate(.parse('/login'));
    await pumpGuards(tester);

    expect(result, isA<NavigationCancelled>());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(router.history.location.uri.path, '/');
  });

  testWidgets('guard error cancels and reports exception', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) {
          if (context.to.uri.path == '/login') {
            throw StateError('boom');
          }
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));

    final result = await router.navigate(.parse('/login'));
    await pumpGuards(tester);

    expect(result, isA<NavigationFailed>());
    final failed = result as NavigationFailed;
    expect(failed.error, isA<StateError>());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(router.history.location.uri.path, '/');
  });

  testWidgets('guard redirect replaces by default', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(path: 'register', factory: () => const Text('Register')),
      ],
      history: MemoryHistory(),
      guards: [(context) => GuardResult.redirect(Uri.parse('/login'))],
    );

    await tester.pumpWidget(wrap(router));
    final result = await router.navigate(.parse('/register'));
    await pumpGuards(tester);

    expect(result, isA<NavigationRedirected>());
    final redirected = result as NavigationRedirected;
    expect(redirected.action, HistoryAction.replace);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsNothing);
    expect(router.history.location.uri.path, '/login');
    expect(router.history.index, 0);
  });

  testWidgets('guard allow respects replace navigation', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [(context) => GuardResult.allow],
    );

    await tester.pumpWidget(wrap(router));
    final result = await router.navigate(.parse('/login'), replace: true);
    await pumpGuards(tester);

    expect(result, isA<NavigationSuccess>());
    final success = result as NavigationSuccess;
    expect(success.action, HistoryAction.replace);
    expect(find.text('Login'), findsOneWidget);
    expect(router.history.location.uri.path, '/login');
    expect(router.history.index, 0);
  });

  testWidgets('guard redirect can push when replace is false', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(path: 'register', factory: () => const Text('Register')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) {
          if (context.to.uri.path == '/register') {
            return GuardResult.redirect(Uri.parse('/login'), replace: false);
          }
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));
    final result = await router.navigate(.parse('/register'));
    await pumpGuards(tester);

    expect(result, isA<NavigationRedirected>());
    final redirected = result as NavigationRedirected;
    expect(redirected.action, HistoryAction.push);
    expect(find.text('Login'), findsOneWidget);
    expect(router.history.location.uri.path, '/login');
    expect(router.history.index, 1);
  });

  testWidgets('setNewRoutePath is guarded (allow)', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [(context) => GuardResult.allow],
    );

    await tester.pumpWidget(wrap(router));

    await router.routerDelegate.setNewRoutePath(
      RouteInformation(uri: Uri.parse('/login')),
    );
    await pumpGuards(tester);

    expect(find.text('Login'), findsOneWidget);
    expect(router.history.location.uri.path, '/login');
    expect(router.history.index, 1);
  });

  testWidgets('setNewRoutePath is guarded (cancel)', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) {
          if (context.to.uri.path == '/login') {
            return GuardResult.cancel;
          }
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));

    await router.routerDelegate.setNewRoutePath(
      RouteInformation(uri: Uri.parse('/login')),
    );
    await pumpGuards(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(router.history.location.uri.path, '/');
    expect(router.history.index, 0);
  });

  testWidgets('setNewRoutePath is guarded (redirect)', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(path: 'blocked', factory: () => const Text('Blocked')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) {
          if (context.to.uri.path == '/login') {
            return GuardResult.redirect(Uri.parse('/blocked'));
          }
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));

    await router.routerDelegate.setNewRoutePath(
      RouteInformation(uri: Uri.parse('/login')),
    );
    await pumpGuards(tester);

    expect(find.text('Blocked'), findsOneWidget);
    expect(router.history.location.uri.path, '/blocked');
    expect(router.history.index, 0);
  });

  testWidgets('guard cancel on pop restores previous location', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(path: 'register', factory: () => const Text('Register')),
      ],
      history: MemoryHistory(
        initialEntries: [RouteInformation(uri: Uri.parse('/login'))],
      ),
      guards: [
        (context) {
          if (context.from.uri.path == '/register' &&
              context.to.uri.path == '/login') {
            return GuardResult.cancel;
          }
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));
    expect(find.text('Login'), findsOneWidget);

    router.navigate(.parse('/register'));
    await pumpGuards(tester);
    expect(find.text('Register'), findsOneWidget);

    final result = await router.navigate.back();
    await pumpGuards(tester);

    expect(result, isA<NavigationCancelled>());
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(router.history.location.uri.path, '/register');
    expect(router.history.index, 1);
  });

  testWidgets('guard cancel on pop with null delta replaces location', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(path: 'register', factory: () => const Text('Register')),
      ],
      history: _NullDeltaHistory(
        initialEntries: [
          RouteInformation(uri: Uri.parse('/login')),
          RouteInformation(uri: Uri.parse('/register')),
        ],
        initialIndex: 1,
      ),
      guards: [
        (context) {
          if (context.from.uri.path == '/register' &&
              context.to.uri.path == '/login') {
            return GuardResult.cancel;
          }
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));
    expect(find.text('Register'), findsOneWidget);

    final result = await router.navigate.back();
    await pumpGuards(tester);

    expect(result, isA<NavigationCancelled>());
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(router.history.location.uri.path, '/register');
  });

  testWidgets('guard redirect on pop syncs history', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'login', factory: () => const Text('Login')),
        Inlet(path: 'register', factory: () => const Text('Register')),
        Inlet(path: 'blocked', factory: () => const Text('Blocked')),
      ],
      history: MemoryHistory(
        initialEntries: [RouteInformation(uri: Uri.parse('/login'))],
      ),
      guards: [
        (context) {
          if (context.from.uri.path == '/register' &&
              context.to.uri.path == '/login') {
            return GuardResult.redirect(Uri.parse('/blocked'));
          }
          return GuardResult.allow;
        },
      ],
    );

    await tester.pumpWidget(wrap(router));
    router.navigate(.parse('/register'));
    await pumpGuards(tester);
    expect(find.text('Register'), findsOneWidget);

    final result = await router.navigate.back();
    await pumpGuards(tester);

    expect(result, isA<NavigationRedirected>());
    final redirected = result as NavigationRedirected;
    expect(redirected.action, HistoryAction.replace);
    expect(find.text('Blocked'), findsOneWidget);
    expect(router.history.location.uri.path, '/blocked');
    expect(router.history.index, 0);
  });

  testWidgets('maxRedirects cancels when exceeded', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'a', factory: () => const Text('A')),
        Inlet(path: 'b', factory: () => const Text('B')),
      ],
      history: MemoryHistory(),
      guards: [
        (context) => GuardResult.redirect(Uri.parse('/a')),
        (context) => GuardResult.redirect(Uri.parse('/b')),
      ],
      maxRedirects: 1,
    );

    await tester.pumpWidget(wrap(router));
    final result = await router.navigate(.parse('/a'));
    await pumpGuards(tester);

    expect(result, isA<NavigationCancelled>());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
    expect(router.history.location.uri.path, '/');
  });
}

class _NullDeltaHistory extends History {
  _NullDeltaHistory({
    List<RouteInformation>? initialEntries,
    int? initialIndex,
  }) {
    final entries = (initialEntries == null || initialEntries.isEmpty)
        ? [RouteInformation(uri: Uri.parse('/'))]
        : initialEntries;
    _entries = List<RouteInformation>.from(entries);
    index = _clampIndex(initialIndex ?? _entries.length - 1);
  }

  late final List<RouteInformation> _entries;
  final List<void Function(HistoryEvent event)> _listeners = [];

  @override
  late int index;

  @override
  HistoryAction action = .pop;

  @override
  RouteInformation get location => _entries[index];

  @override
  String createHref(Uri uri) {
    final buffer = StringBuffer(uri.path);
    if (uri.hasQuery) buffer.write('?${uri.query}');
    if (uri.hasFragment) buffer.write('#${uri.fragment}');
    return buffer.toString();
  }

  @override
  void push(Uri uri, [Object? state]) {
    action = .push;
    index += 1;
    if (index < _entries.length) {
      _entries.length = index;
    }
    _entries.add(RouteInformation(uri: uri, state: state));
  }

  @override
  void replace(Uri uri, [Object? state]) {
    action = .replace;
    _entries[index] = RouteInformation(uri: uri, state: state);
  }

  @override
  void go(int delta) {
    action = .pop;
    index = _clampIndex(index + delta);
    final event = HistoryEvent(action: action, location: location, delta: null);
    for (final listener in _listeners) {
      listener(event);
    }
  }

  @override
  void Function() listen(void Function(HistoryEvent event) listener) {
    _listeners.add(listener);
    return () {
      _listeners.removeWhere((e) => e == listener);
    };
  }

  @override
  void dispose() {
    _entries.clear();
    _listeners.clear();
  }

  int _clampIndex(int value) => value.clamp(0, _entries.length - 1);
}
