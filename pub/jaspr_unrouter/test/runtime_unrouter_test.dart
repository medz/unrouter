import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart';
import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart' as core;

void main() {
  test(
    'adapter Unrouter resolves through core and exposes stateful API',
    () async {
      final router = Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          route<HomeRoute>(
            path: '/home',
            parse: (_) => const HomeRoute(),
            builder: (_, __) => const Component.text('home'),
          ),
        ],
      );

      final result = await router.resolve(Uri(path: '/home'));

      expect(router, isA<core.Unrouter<AppRoute>>());
      expect(router.createElement(), isA<StatefulElement>());
      expect(router.createState(), isA<State>());
      expect(result.isMatched, isTrue);
      expect(result.route, isA<HomeRoute>());
    },
  );

  test('constructor asserts on empty routes and invalid redirect hops', () {
    expect(
      () => Unrouter<AppRoute>(routes: <RouteRecord<AppRoute>>[]),
      throwsA(isA<AssertionError>()),
    );

    expect(
      () => Unrouter<AppRoute>(
        maxRedirectHops: 0,
        routes: <RouteRecord<AppRoute>>[
          route<HomeRoute>(
            path: '/home',
            parse: (_) => const HomeRoute(),
            builder: (_, __) => const Component.text('home'),
          ),
        ],
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/home');
}
