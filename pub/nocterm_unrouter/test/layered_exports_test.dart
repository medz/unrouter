import 'package:nocterm/nocterm.dart' hide isEmpty, isNotEmpty;
import 'package:nocterm_unrouter/nocterm_unrouter.dart' as unrouter;
import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart' as core;

void main() {
  test('layered entrypoints expose expected symbols', () {
    expect(unrouter.RouteGuardResult.allow().isAllowed, isTrue);
    expect(unrouter.RouteResolutionType.values, isNotEmpty);
    expect(unrouter.StateSnapshot, isNotNull);
    expect(unrouter.Unrouter, isNotNull);
    expect(unrouter.UnrouterController, isNotNull);
    expect(unrouter.UnrouterScope, isNotNull);
    expect(unrouter.ShellState, isNotNull);
    expect(unrouter.branch, isNotNull);
    expect(unrouter.shell, isNotNull);
  });

  test('adapter route records can be resolved through core router', () async {
    final router = core.Unrouter<AppRoute>(
      routes: <unrouter.RouteRecord<AppRoute>>[
        unrouter.route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home'),
        ),
      ],
    );

    final result = await router.resolve(Uri(path: '/'));
    expect(result.isMatched, isTrue);
    expect(result.record, isA<unrouter.RouteRecord<AppRoute>>());
    expect(result.record!.path, '/');
  });

  test('router config can mount into nocterm router component', () {
    final mounted = unrouter.Unrouter<AppRoute>(
      routes: <unrouter.RouteRecord<AppRoute>>[
        unrouter.route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home'),
        ),
      ],
    );
    expect(mounted, isA<Component>());
  });

  test('component defaults resolveInitialRoute to false', () {
    final mounted = unrouter.Unrouter<AppRoute>(
      routes: <unrouter.RouteRecord<AppRoute>>[
        unrouter.route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home'),
        ),
      ],
    );

    expect(mounted.resolveInitialRoute, isFalse);
  });
}

sealed class AppRoute implements unrouter.RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}
