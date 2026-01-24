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

      await router.navigate.route('about');
      await tester.pumpAndSettle();
      expect(find.text('Name: about'), findsOneWidget);
    });

    testWidgets('navigate.route resolves names with params', (tester) async {
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

      final result = await router.navigate.route(
        'userDetail',
        params: {'id': '123'},
      );
      await tester.pumpAndSettle();

      expect(result, isA<NavigationSuccess>());
      expect(router.history.location.uri.path, '/users/123');
      expect(router.routerDelegate.currentConfiguration.name, 'userDetail');
      expect(find.text('User 123'), findsOneWidget);
    });

    testWidgets('navigate.route supports nested paths and query', (
      tester,
    ) async {
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
          Inlet(
            name: 'search',
            path: 'search',
            factory: SearchPage.new,
          ),
        ],
        history: MemoryHistory(),
      );

      await tester.pumpWidget(wrapRouter(router));

      await router.navigate.route('user', params: {'id': '42'});
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/users/42');

      await router.navigate.route(
        'search',
        queryParameters: {'q': 'flutter'},
        fragment: 'top',
      );
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/search');
      expect(router.history.location.uri.query, 'q=flutter');
      expect(router.history.location.uri.fragment, 'top');
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('navigate.route handles optional params', (tester) async {
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

      await router.navigate.route('about');
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/about');

      await router.navigate.route('about', params: {'lang': 'en'});
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/en/about');
    });

    testWidgets('navigate.route includes optional static segments', (
      tester,
    ) async {
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

      await router.navigate.route('editUser', params: {'id': '9'});
      await tester.pumpAndSettle();
      expect(router.history.location.uri.path, '/users/9/edit');
    });

    testWidgets('navigate.route throws for invalid names or params', (
      tester,
    ) async {
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
        () => router.navigate.route('missing'),
        throwsA(isA<FlutterError>()),
      );
      expect(
        () => router.navigate.route('userDetail'),
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
