import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrapRouter(Unrouter router) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Router.withConfig(config: router),
    );
  }

  group('Named routes', () {
    testWidgets('context.location exposes matched route name', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(name: 'home', factory: NameProbePage.new),
          Inlet(name: 'about', path: 'about', factory: NameProbePage.new),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(find.text('Name: home'), findsOneWidget);

      await router.navigate(name: 'about');
      await tester.pumpAndSettle();
      expect(find.text('Name: about'), findsOneWidget);
    });

    testWidgets('navigate resolves names with params', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(name: 'home', factory: () => const Text('Home')),
          Inlet(
            name: 'userDetail',
            path: 'users/:id',
            factory: UserDetailPage.new,
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      final result = await router.navigate(
        name: 'userDetail',
        params: {'id': '123'},
      );
      await tester.pumpAndSettle();

      expect(result, isA<NavigationSuccess>());
      expect(router.history.location.uri.path, '/users/123');
      expect(router.routerDelegate.currentConfiguration.name, 'userDetail');
      expect(find.text('User 123'), findsOneWidget);
    });

    testWidgets('navigate supports nested paths and query', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(name: 'home', factory: () => const Text('Home')),
          Inlet(
            path: 'users',
            factory: UsersLayout.new,
            children: [
              Inlet(name: 'usersIndex', factory: () => const Text('Users')),
              Inlet(name: 'user', path: ':id', factory: UserDetailPage.new),
            ],
          ),
          Inlet(name: 'search', path: 'search', factory: SearchPage.new),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      await router.navigate(name: 'user', params: {'id': '42'});
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/users/42');

      await router.navigate(
        name: 'search',
        query: {'q': 'flutter'},
        fragment: 'top',
      );
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/search');
      expect(router.history.location.uri.query, 'q=flutter');
      expect(router.history.location.uri.fragment, 'top');
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('navigate handles optional params', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(
            name: 'about',
            path: ':lang?/about',
            factory: () => const Text('About'),
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      await router.navigate(name: 'about');
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/about');

      await router.navigate(name: 'about', params: {'lang': 'en'});
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/en/about');
    });

    testWidgets('navigate includes optional static segments', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(
            name: 'editUser',
            path: 'users/:id/edit?',
            factory: () => const Text('Edit'),
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      await router.navigate(name: 'editUser', params: {'id': '9'});
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/users/9/edit');
    });

    testWidgets('navigate.route generates URIs', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(
            name: 'userDetail',
            path: 'users/:id',
            factory: UserDetailPage.new,
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      final uri = router.navigate.route(
        name: 'userDetail',
        params: {'id': '123'},
        query: {'tab': 'profile'},
        fragment: 'top',
      );

      expect(uri.path, '/users/123');
      expect(uri.query, 'tab=profile');
      expect(uri.fragment, 'top');
    });

    testWidgets('navigate.route supports path patterns', (tester) async {
      final router = Unrouter(
        routes: [Inlet(name: 'home', factory: () => const Text('Home'))],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      final uri = router.navigate.route(
        path: '/users/:id',
        params: {'id': '777'},
      );

      expect(uri.path, '/users/777');
    });

    testWidgets('navigate.route supports named wildcards', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(
            name: 'docs',
            path: 'docs/*path',
            factory: () => const Text('Docs'),
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      final uri = router.navigate.route(
        path: '/docs/*path',
        params: {'path': 'a/b'},
      );

      expect(uri.path, '/docs/a/b');
    });

    testWidgets('navigate supports path patterns', (tester) async {
      final router = Unrouter(
        routes: [Inlet(path: 'users/:id', factory: UserDetailPage.new)],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      await router.navigate(path: '/users/:id', params: {'id': '777'});
      await tester.pumpAndSettle();

      expect(router.history.location.uri.path, '/users/777');
      expect(find.text('User 777'), findsOneWidget);
    });

    testWidgets('navigate throws for invalid names or params', (tester) async {
      final router = Unrouter(
        routes: [
          Inlet(name: 'home', factory: () => const Text('Home')),
          Inlet(
            name: 'userDetail',
            path: 'users/:id',
            factory: UserDetailPage.new,
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      expect(
        () => router.navigate(name: 'missing'),
        throwsA(isA<FlutterError>()),
      );
      expect(
        () => router.navigate(name: 'userDetail'),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.params['id'] ?? 'unknown';
    return Text('User $id');
  }
}

class UsersLayout extends StatelessWidget {
  const UsersLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Outlet();
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Search');
  }
}

class NameProbePage extends StatelessWidget {
  const NameProbePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('Name: ${context.location.name ?? 'none'}');
  }
}
