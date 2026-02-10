import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
import 'package:test/test.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('renders matched and unknown routes', () async {
    final tester = await NoctermTester.create();
    addTearDown(tester.dispose);

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/home'))],
        initialIndex: 0,
      ),
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home-screen'),
        ),
      ],
    );

    await tester.pumpComponent(router);
    await _pumpFew(tester);
    expect(tester.terminalState, containsText('home-screen'));

    final unknownRouter = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[
          HistoryLocation(Uri(path: '/missing')),
        ],
        initialIndex: 0,
      ),
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home-screen'),
        ),
      ],
    );

    await tester.pumpComponent(unknownRouter);
    await _pumpFew(tester);
    expect(tester.terminalState, containsText('No route matches /missing'));
  });

  test('uses blocked/unknown/onError/loading fallbacks', () async {
    final tester = await NoctermTester.create();
    addTearDown(tester.dispose);

    final blockedRouter = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[
          HistoryLocation(Uri(path: '/secure')),
        ],
        initialIndex: 0,
      ),
      blocked: (_, uri) => Text('blocked:${uri.path}'),
      unknown: (_, uri) => Text('unknown:${uri.path}'),
      routes: <RouteRecord<AppRoute>>[
        route<SecureRoute>(
          path: '/secure',
          parse: (_) => const SecureRoute(),
          guards: <RouteGuard<SecureRoute>>[(_) => RouteGuardResult.block()],
          builder: (_, __) => const Text('secure-screen'),
        ),
      ],
    );

    await tester.pumpComponent(blockedRouter);
    await _pumpFew(tester);
    expect(tester.terminalState, containsText('unknown:/secure'));

    final unknownRouter = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/404'))],
        initialIndex: 0,
      ),
      unknown: (_, uri) => Text('unknown:${uri.path}'),
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home-screen'),
        ),
      ],
    );

    await tester.pumpComponent(unknownRouter);
    await _pumpFew(tester);
    expect(tester.terminalState, containsText('unknown:/404'));

    final errorRouter = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[
          HistoryLocation(Uri(path: '/users/not-int')),
        ],
        initialIndex: 0,
      ),
      onError: (_, error, __) => Text('error:${error.runtimeType}'),
      routes: <RouteRecord<AppRoute>>[
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) =>
              UserRoute(id: int.parse(state.params.required('id'))),
          builder: (_, __) => const Text('user-screen'),
        ),
      ],
    );

    await tester.pumpComponent(errorRouter);
    await _pumpFew(tester);
    expect(tester.terminalState, containsText('error:FormatException'));

    final loadingRouter = Unrouter<AppRoute>(
      resolveInitialRoute: false,
      loading: (_, uri) => Text('loading:${uri.path}'),
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home-screen'),
        ),
      ],
    );

    await tester.pumpComponent(loadingRouter);
    await _pumpFew(tester);
    expect(tester.terminalState, containsText('loading:/'));
  });

  test(
    'explicit history and didUpdateComponent reconfigure controller',
    () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      final first = Unrouter<AppRoute>(
        history: MemoryHistory(
          initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/a'))],
          initialIndex: 0,
        ),
        routes: <RouteRecord<AppRoute>>[
          route<ARoute>(
            path: '/a',
            parse: (_) => const ARoute(),
            builder: (_, __) => const Text('screen-a'),
          ),
        ],
      );

      final second = Unrouter<AppRoute>(
        history: MemoryHistory(
          initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/b'))],
          initialIndex: 0,
        ),
        routes: <RouteRecord<AppRoute>>[
          route<BRoute>(
            path: '/b',
            parse: (_) => const BRoute(),
            builder: (_, __) => const Text('screen-b'),
          ),
        ],
      );

      await tester.pumpComponent(_RouterHost(first: first, second: second));
      await _pumpFew(tester);
      expect(tester.terminalState, containsText('screen-a'));

      final hostState = tester.findState<_RouterHostState>();
      hostState.switchToSecond();
      await _pumpFew(tester);

      expect(tester.terminalState, containsText('screen-b'));
    },
  );

  test('without onError parser failures render default error component', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      final router = Unrouter<AppRoute>(
        history: MemoryHistory(
          initialEntries: <HistoryLocation>[
            HistoryLocation(Uri(path: '/users/not-int')),
          ],
          initialIndex: 0,
        ),
        routes: <RouteRecord<AppRoute>>[
          route<UserRoute>(
            path: '/users/:id',
            parse: (state) =>
                UserRoute(id: int.parse(state.params.required('id'))),
            builder: (_, __) => const Text('user-screen'),
          ),
        ],
      );

      await tester.pumpComponent(router);
      await _pumpFew(tester);
      expect(tester.terminalState, containsText('Route resolution error:'));
      expect(tester.terminalState, containsText('FormatException'));
    },
  );
}

Future<void> _pumpFew(NoctermTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump();
  }
}

class _RouterHost extends StatefulComponent {
  const _RouterHost({required this.first, required this.second});

  final Unrouter<AppRoute> first;
  final Unrouter<AppRoute> second;

  @override
  State createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  bool _second = false;

  void switchToSecond() {
    setState(() {
      _second = true;
    });
  }

  @override
  Component build(BuildContext context) {
    return _second ? component.second : component.first;
  }
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/home');
}

final class SecureRoute extends AppRoute {
  const SecureRoute();

  @override
  Uri toUri() => Uri(path: '/secure');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

final class ARoute extends AppRoute {
  const ARoute();

  @override
  Uri toUri() => Uri(path: '/a');
}

final class BRoute extends AppRoute {
  const BRoute();

  @override
  Uri toUri() => Uri(path: '/b');
}
