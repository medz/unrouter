# Core routing guide

## Route definitions

Use `route<T>()` for regular routes:

```dart
route<UserRoute>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.pathInt('id')),
  builder: (_, route) => UserPage(id: route.id),
)
```

Use `routeWithLoader<T, L>()` when data loading should happen before building:

```dart
routeWithLoader<UserRoute, User>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.pathInt('id')),
  loader: (context) async => api.fetchUser(context.route.id),
  builder: (_, __, user) => UserPage(user: user),
)
```

## Parser helpers

`RouteParserState` provides typed helpers:

- `path`, `pathOrNull`, `pathInt`
- `query`, `queryOrNull`, `queryInt`, `queryIntOrNull`, `queryEnum`

## Guards and redirects

Guards run before route commit:

```dart
guards: [
  (context) async {
    final signedIn = await auth.isSignedIn();
    if (signedIn) {
      return RouteGuardResult.allow();
    }
    return RouteGuardResult.redirect(Uri(path: '/login'));
  },
]
```

Route-level redirects are also supported:

```dart
redirect: (_) => Uri(path: '/new-home')
```

Router-level redirect safety controls:

```dart
Unrouter<AppRoute>(
  maxRedirectHops: 8,
  redirectLoopPolicy: RedirectLoopPolicy.error,
  onRedirectDiagnostics: (event) {
    debugPrint('${event.reason.name} ${event.hop}/${event.maxHops}');
  },
  routes: [...],
)
```

## Shell branches

Use `shell()` and `branch()` for bottom-tab or multi-stack navigation:

```dart
...shell<AppRoute>(
  branches: [
    branch<AppRoute>(
      initialLocation: Uri(path: '/feed'),
      routes: [...],
    ),
    branch<AppRoute>(
      initialLocation: Uri(path: '/settings'),
      routes: [...],
    ),
  ],
  builder: (context, shell, child) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.activeBranchIndex,
      onDestinationSelected: (index) => shell.goBranch(index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  ),
),
```

Useful shell operations:

- `shell.goBranch(index)` restores current top of target branch stack.
- `shell.goBranch(index, initialLocation: true)` resets target branch stack.
- `shell.popBranch()` pops in active branch stack.
- `shell.popBranch(result)` pops and completes pending push result.

## State and timeline introspection

Core state APIs are available through `BuildContext`:

```dart
final snapshot = context.unrouterAs<AppRoute>().state;
final timeline = context.unrouterAs<AppRoute>().stateTimeline;
final listenable = context.unrouterAs<AppRoute>().stateListenable;
```

See `doc/state_envelope.md` for `history.state` serialization and versioning.
