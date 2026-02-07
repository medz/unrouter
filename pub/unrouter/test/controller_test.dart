import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('controller resolves initial location', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
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
          route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          route<UserRoute>(
            path: '/users/:id',
            parse: (state) => UserRoute(id: state.pathInt('id')),
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
          route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          route<LoginRoute>(path: '/login', parse: (_) => const LoginRoute()),
          route<SecureRoute>(
            path: '/secure',
            parse: (_) => const SecureRoute(),
            guards: <RouteGuard<SecureRoute>>[
              (_) => signedIn
                  ? RouteGuardResult.allow()
                  : RouteGuardResult.redirect(Uri(path: '/login')),
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
          route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          route<SecureRoute>(
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
          route<SecureRoute>(
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
