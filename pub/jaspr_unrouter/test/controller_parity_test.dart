import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart';
import 'package:unrouter/unrouter.dart' as core;
import 'package:test/test.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('controller follows guard redirects', () async {
    var signedIn = false;
    final router = core.Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home'),
        ),
        route<LoginRoute>(
          path: '/login',
          parse: (_) => const LoginRoute(),
          builder: (_, __) => const Component.text('login'),
        ),
        route<SecureRoute>(
          path: '/secure',
          parse: (_) => const SecureRoute(),
          guards: <RouteGuard<SecureRoute>>[
            (_) => signedIn
                ? RouteGuardResult.allow()
                : RouteGuardResult.redirect(uri: Uri(path: '/login')),
          ],
          builder: (_, __) => const Component.text('secure'),
        ),
      ],
    );
    final controller = UnrouterController<AppRoute>(
      router: router,
      history: MemoryHistory(),
      resolveInitialRoute: true,
    );
    addTearDown(controller.dispose);

    await controller.idle;
    controller.go(const SecureRoute());
    await controller.idle;
    expect(controller.uri.path, '/login');
    expect(controller.state.isMatched, isTrue);

    signedIn = true;
    controller.go(const SecureRoute());
    await controller.idle;
    expect(controller.uri.path, '/secure');
    expect(controller.state.isMatched, isTrue);
  });

  test('blocked route falls back when a route is already committed', () async {
    final router = core.Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home'),
        ),
        route<SecureRoute>(
          path: '/secure',
          parse: (_) => const SecureRoute(),
          guards: <RouteGuard<SecureRoute>>[(_) => RouteGuardResult.block()],
          builder: (_, __) => const Component.text('secure'),
        ),
      ],
    );
    final controller = UnrouterController<AppRoute>(
      router: router,
      history: MemoryHistory(),
      resolveInitialRoute: true,
    );
    addTearDown(controller.dispose);

    await controller.idle;
    controller.go(const SecureRoute());
    await controller.idle;

    expect(controller.uri.path, '/');
    expect(controller.state.isMatched, isTrue);
    expect(controller.route, isA<HomeRoute>());
  });

  test('loader data is produced by core runtime controller', () async {
    final router = core.Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        routeWithLoader<ProfileRoute, String>(
          path: '/profile',
          parse: (_) => const ProfileRoute(),
          loader: (_) => 'profile-data',
          builder: (_, __, ___) => const Component.text('profile'),
        ),
      ],
    );
    final controller = UnrouterController<AppRoute>(
      router: router,
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[
          HistoryLocation(Uri(path: '/profile')),
        ],
        initialIndex: 0,
      ),
      resolveInitialRoute: true,
    );
    addTearDown(controller.dispose);

    await controller.idle;
    expect(controller.state.isMatched, isTrue);
    expect(controller.resolution.loaderData, 'profile-data');
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

final class ProfileRoute extends AppRoute {
  const ProfileRoute();

  @override
  Uri toUri() => Uri(path: '/profile');
}
