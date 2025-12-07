import 'package:flutter/material.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

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

void main() {
  test('matches nested routes and params', () {
    final routes = <Route>[
      .new(
        path: '/',
        builder: (_) => const RootLayout(),
        children: [
          .new(path: 'profile/:id', builder: (_) => const ProfilePage()),
        ],
      ),
      .new(path: '**', builder: (_) => const NotFound()),
    ];

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
}
