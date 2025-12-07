import 'package:flutter/material.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unrouter/src/router.dart' as internal;

class RootLayout extends StatelessWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class NotFound extends StatelessWidget {
  const NotFound({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

List<Route> _routes() => <Route>[
  .new(
    path: '/',
    builder: (_) => const RootLayout(),
    children: [
      .new(path: 'profile/:id', builder: (_) => const ProfilePage()),
    ],
  ),
  .new(path: '**', builder: (_) => const NotFound()),
];

void main() {
  tearDown(internal.resetUrlStrategyForTest);

  test('matches nested routes and params', () {
    final routes = _routes();

    final router = createRouter(routes: routes);
    final core = toZenRouterCoordinator(router);

    final page = core.parseRouteFromUri(Uri.parse('/profile/123?tab=posts'));

    expect(page.matches.length, 2);
    expect(page.matches.first.route.path, '/');
    expect(page.matches.last.route.path, 'profile/:id');
    expect(page.matches.last.params['id'], '123');

    final notFound = core.parseRouteFromUri(Uri.parse('/missing/path'));
    expect(notFound.matches.single.route.path, '**');
    expect(notFound.matches.single.params['pathMatch'], 'missing/path');
  });

  test('applies url strategy with default path', () {
    final routes = _routes();
    createRouter(routes: routes);

    expect(internal.debugConfiguredUrlStrategy, RouterUrlStrategy.path);
  });

  test('applies url strategy only once', () {
    final routes = _routes();
    createRouter(routes: routes, strategy: RouterUrlStrategy.hash);
    createRouter(routes: routes, strategy: RouterUrlStrategy.path);

    expect(internal.debugConfiguredUrlStrategy, RouterUrlStrategy.hash);
  });
}
