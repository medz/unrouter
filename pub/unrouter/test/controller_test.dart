import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('controller resolves initial location', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          Route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await controller.idle;

    expect(controller.state.isMatched, isTrue);
    expect(controller.route, isA<HomeRoute>());
    expect(controller.uri.path, '/');
  });

  test('controller push/pop resolves typed result', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          Route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          Route<UserRoute>(
            path: '/users/:id',
            parse: (state) => UserRoute(id: state.params.$int('id')),
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await controller.idle;
    final result = controller.push<int>(const UserRoute(id: 7));
    await controller.idle;
    expect(controller.uri.path, '/users/7');

    expect(controller.pop(70), isTrue);
    await controller.idle;
    expect(await result, 70);
    expect(controller.uri.path, '/');
  });

  test('controller follows guard redirects', () async {
    var signedIn = false;
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          Route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          Route<LoginRoute>(path: '/login', parse: (_) => const LoginRoute()),
          Route<SecureRoute>(
            path: '/secure',
            parse: (_) => const SecureRoute(),
            guards: <RouteGuard<SecureRoute>>[
              (_) => signedIn
                  ? RouteGuardResult.allow()
                  : RouteGuardResult.redirect(uri: Uri(path: '/login')),
            ],
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await controller.idle;
    controller.goUri(Uri(path: '/secure'));
    await controller.idle;
    expect(controller.uri.path, '/login');
    expect(controller.state.isMatched, isTrue);

    signedIn = true;
    controller.goUri(Uri(path: '/secure'));
    await controller.idle;
    expect(controller.uri.path, '/secure');
    expect(controller.state.isMatched, isTrue);
  });

  test('blocked route falls back when a route is already committed', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          Route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          Route<SecureRoute>(
            path: '/secure',
            parse: (_) => const SecureRoute(),
            guards: <RouteGuard<SecureRoute>>[(_) => RouteGuardResult.block()],
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await controller.idle;
    controller.goUri(Uri(path: '/secure'));
    await controller.idle;

    expect(controller.uri.path, '/');
    expect(controller.state.isMatched, isTrue);
    expect(controller.route, isA<HomeRoute>());
  });

  test('blocked initial location becomes unmatched', () async {
    final history = MemoryHistory(
      initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/secure'))],
      initialIndex: 0,
    );
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          Route<SecureRoute>(
            path: '/secure',
            parse: (_) => const SecureRoute(),
            guards: <RouteGuard<SecureRoute>>[(_) => RouteGuardResult.block()],
          ),
        ],
      ),
      history: history,
    );
    addTearDown(controller.dispose);

    await controller.idle;

    expect(controller.uri.path, '/secure');
    expect(controller.state.isUnmatched, isTrue);
  });

  test('controller cast returns same runtime view', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          Route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          Route<UserRoute>(
            path: '/users/:id',
            parse: (state) => UserRoute(id: state.params.$int('id')),
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await controller.idle;

    final casted = controller.cast<AppRoute>();
    expect(casted, same(controller));

    casted.go(const UserRoute(id: 3));
    await casted.idle;

    expect(controller.uri.path, '/users/3');
    expect(casted.uri.path, '/users/3');
  });

  test(
    'controller history state composer is applied to navigation writes',
    () async {
      final controller = UnrouterController<AppRoute>(
        router: Unrouter<AppRoute>(
          routes: <RouteRecord<AppRoute>>[
            Route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
            Route<UserRoute>(
              path: '/users/:id',
              parse: (state) => UserRoute(id: state.params.$int('id')),
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);
      await controller.idle;

      controller.setHistoryStateComposer((request) {
        return <String, Object?>{
          'uri': request.uri.path,
          'action': request.action.name,
          'state': request.state,
          'current': request.currentState,
        };
      });

      controller.go(const UserRoute(id: 8), state: 'payload');
      await controller.idle;

      final historyState = controller.historyState as Map<String, Object?>;
      expect(historyState['uri'], '/users/8');
      expect(historyState['action'], HistoryAction.replace.name);
      expect(historyState['state'], 'payload');
      expect(historyState['current'], isNull);
    },
  );

  test('controller switchBranch/popBranch use configured resolvers', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          Route<BranchRoute>(path: '/a', parse: (_) => const BranchRoute('/a')),
          Route<BranchRoute>(path: '/b', parse: (_) => const BranchRoute('/b')),
          Route<BranchRoute>(
            path: '/b/details',
            parse: (_) => const BranchRoute('/b/details'),
          ),
        ],
      ),
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/a'))],
        initialIndex: 0,
      ),
    );
    addTearDown(controller.dispose);
    await controller.idle;

    controller.setShellBranchResolvers(
      resolveTarget: (index, {required initialLocation}) {
        switch (index) {
          case 0:
            return Uri(path: '/a');
          case 1:
            return initialLocation ? Uri(path: '/b') : Uri(path: '/b/details');
          default:
            throw RangeError.index(index, const <int>[0, 1], 'index');
        }
      },
      popTarget: () => Uri(path: '/a'),
    );

    expect(controller.switchBranch(1), isTrue);
    await controller.idle;
    expect(controller.uri.path, '/b/details');

    final pending = controller.pushUri<int>(Uri(path: '/b/details'));
    await controller.idle;

    expect(controller.popBranch(99), isTrue);
    await controller.idle;
    expect(await pending, 99);
    expect(controller.uri.path, '/a');
  });
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

final class LoginRoute extends AppRoute {
  const LoginRoute();

  @override
  Uri toUri() => Uri(path: '/login');
}

final class SecureRoute extends AppRoute {
  const SecureRoute();

  @override
  Uri toUri() => Uri(path: '/secure');
}

final class BranchRoute extends AppRoute {
  const BranchRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}
