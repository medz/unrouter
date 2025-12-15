Unrouter is a minimal Flutter router built on `routingkit`. It renders nested routes via `RouterView`, bridges Navigator 1 `pushNamed`, and keeps a platform-aware history (memory or web hash/path).

- Install
  ```yaml
  dependencies:
    unrouter: ^0.1.0
  ```

- Define routes
  ```dart
  final routes = <Route>[
    Route(
      path: '/',
      builder: (_) => const Layout(),
      children: [
        Route(path: '', builder: (_) => const HomePage(), name: 'home'),
        Route(path: 'users/:id', builder: (_) => const UserPage(), name: 'user'),
        Route(path: '**', builder: (_) => const NotFoundPage()),
      ],
    ),
  ];
  ```

- Build a router (defaults: web → hash history, others → memory)
  ```dart
  final router = createRouter(
    routes: routes,
    // optional: history: createWebHistory(), createWebHashHistory(), createMemoryHistory(),
    // optional: initialPath: '/home',
  );
  ```

- Wire into your app
  ```dart
  MaterialApp.router(
    routerDelegate: router.delegate,
    routeInformationParser: router.informationParser,
  );
  ```

- Navigate inside widgets
  ```dart
  final router = useRouter(context);
  final route = useRoute(context); // uri, params, query, state
  router.push(const RouteLocation.name('user', params: {'id': '42'}));
  ```

- Render nested content and links
  ```dart
  class Layout extends StatelessWidget {
    const Layout({super.key});
    @override
    Widget build(BuildContext context) => const RouterView();
  }

  const RouterLink(
    location: RouteLocation.path('/settings'),
    child: Text('Go settings'),
  );
  ```

- Navigator compatibility: `Navigator.of(context).pushNamed('/users/42')` is bridged into the same history stack; `pop` delegates to router history.
