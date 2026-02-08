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
          route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          route<LoginRoute>(path: '/login', parse: (_) => const LoginRoute()),
          route<SecureRoute>(
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

  test('controller cast returns same runtime view', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          route<UserRoute>(
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

  test('controller writes provided history state payload', () async {
    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
          route<UserRoute>(
            path: '/users/:id',
            parse: (state) => UserRoute(id: state.params.$int('id')),
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);
    await controller.idle;

    const payload = <String, Object?>{
      'source': 'test',
      'purpose': 'state-pass-through',
    };

    controller.go(const UserRoute(id: 8), state: payload);
    await controller.idle;

    final historyState = controller.historyState as Map<String, Object?>;
    expect(historyState, payload);
  });

  test('controller switchBranch/popBranch use configured resolvers', () async {
    Uri resolveBranchTarget(int index, {required bool initialLocation}) {
      switch (index) {
        case 0:
          return Uri(path: '/a');
        case 1:
          return initialLocation ? Uri(path: '/b') : Uri(path: '/b/details');
      }
      throw RangeError.index(index, const <int>[0, 1], 'index');
    }

    Uri? popBranchTarget({Object? result}) {
      return Uri(path: '/a');
    }

    final controller = UnrouterController<AppRoute>(
      router: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          _ShellHostRouteRecord(
            path: '/a',
            parse: (_) => const BranchRoute('/a'),
            resolveTarget: resolveBranchTarget,
            popTarget: popBranchTarget,
          ),
          _ShellHostRouteRecord(
            path: '/b',
            parse: (_) => const BranchRoute('/b'),
            resolveTarget: resolveBranchTarget,
            popTarget: popBranchTarget,
          ),
          _ShellHostRouteRecord(
            path: '/b/details',
            parse: (_) => const BranchRoute('/b/details'),
            resolveTarget: resolveBranchTarget,
            popTarget: popBranchTarget,
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

final class _ShellHostRouteRecord extends RouteDefinition<BranchRoute>
    implements ShellRouteRecordHost {
  _ShellHostRouteRecord({
    required super.path,
    required super.parse,
    required Uri Function(int index, {required bool initialLocation})
    resolveTarget,
    required Uri? Function({Object? result}) popTarget,
  }) : _resolveTarget = resolveTarget,
       _popTarget = popTarget;

  final Uri Function(int index, {required bool initialLocation}) _resolveTarget;
  final Uri? Function({Object? result}) _popTarget;

  @override
  Uri resolveBranchTarget(int index, {bool initialLocation = false}) {
    return _resolveTarget(index, initialLocation: initialLocation);
  }

  @override
  bool canPopBranch() {
    return _popTarget() != null;
  }

  @override
  Uri? popBranch({Object? result}) {
    return _popTarget(result: result);
  }
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
