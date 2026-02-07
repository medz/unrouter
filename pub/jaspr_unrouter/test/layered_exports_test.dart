import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart' as unrouter;
import 'package:test/test.dart';

void main() {
  test('layered entrypoints expose expected symbols', () {
    expect(unrouter.RouteGuardResult.allow().isAllowed, isTrue);
    expect(unrouter.UnrouterResolutionState.values, isNotEmpty);
    expect(unrouter.UnrouterStateSnapshot, isNotNull);
    expect(unrouter.Unrouter, isNotNull);
    expect(unrouter.UnrouterRouter, isNotNull);
    expect(unrouter.UnrouterController, isNotNull);
  });

  test('adapter router wraps core route records and resolve', () async {
    final router = unrouter.Unrouter<AppRoute>(
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

    final adapterRecord = router.routeRecordOf(result.record);
    expect(adapterRecord, isNotNull);
    expect(adapterRecord!.path, '/');
  });

  test('router config can mount into jaspr router component', () {
    final router = unrouter.Unrouter<AppRoute>(
      routes: <unrouter.RouteRecord<AppRoute>>[
        unrouter.route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home'),
        ),
      ],
    );

    final mounted = unrouter.UnrouterRouter<AppRoute>(router: router);
    expect(mounted, isA<Component>());
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
