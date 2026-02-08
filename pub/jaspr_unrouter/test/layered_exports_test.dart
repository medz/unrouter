import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart' as unrouter;
import 'package:unrouter/unrouter.dart' as core;
import 'package:test/test.dart';

void main() {
  test('layered entrypoints expose expected symbols', () {
    expect(unrouter.RouteGuardResult.allow().isAllowed, isTrue);
    expect(unrouter.RouteResolutionType.values, isNotEmpty);
    expect(unrouter.StateSnapshot, isNotNull);
    expect(unrouter.Unrouter, isNotNull);
    expect(unrouter.UnrouterController, isNotNull);
    expect(unrouter.UnrouterScope, isNotNull);
    expect(unrouter.UnrouterLink, isNotNull);
    expect(unrouter.UnrouterLinkMode.values, isNotEmpty);
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
          builder: (_, __) => const Component.text('home'),
        ),
      ],
    );

    final result = await router.resolve(Uri(path: '/'));
    expect(result.isMatched, isTrue);
    expect(result.record, isA<unrouter.RouteRecord<AppRoute>>());
    expect(result.record!.path, '/');
  });

  test('router config can mount into jaspr router component', () {
    final mounted = unrouter.Unrouter<AppRoute>(
      routes: <unrouter.RouteRecord<AppRoute>>[
        unrouter.route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home'),
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
          builder: (_, __) => const Component.text('home'),
        ),
      ],
    );

    expect(mounted.resolveInitialRoute, isFalse);
  });

  test('link component can be created for typed route', () {
    const link = unrouter.UnrouterLink<HomeRoute>(
      route: HomeRoute(),
      children: <Component>[Component.text('Home')],
    );

    expect(link, isA<Component>());
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
