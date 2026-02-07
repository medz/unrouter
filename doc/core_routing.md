# Core routing guide

This guide focuses on `package:unrouter/unrouter.dart` only.

## Route definitions

Create typed routes with `route<T>()`:

```dart
route<UserRoute>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.pathInt('id')),
)
```

Create routes with async preload data using `routeWithLoader<T, L>()`:

```dart
routeWithLoader<UserRoute, User>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.pathInt('id')),
  loader: (context) async => api.fetchUser(context.route.id),
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

Route-level redirect:

```dart
redirect: (_) => Uri(path: '/new-home')
```

Router-level redirect safety:

```dart
Unrouter<AppRoute>(
  maxRedirectHops: 8,
  redirectLoopPolicy: RedirectLoopPolicy.error,
  onRedirectDiagnostics: (event) {
    print('${event.reason.name} ${event.hop}/${event.maxHops}');
  },
  routes: [...],
)
```

## Branch metadata for adapters

`unrouter` itself is runtime/UI agnostic. Use `shell()` and `branch()` to define
branch metadata that adapter packages can consume:

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
),
```

In core package, `shell()` flattens branch records and preserves branch info for
adapter-specific behaviors (for example `flutter_unrouter` shell navigation).

## Resolution and runtime state

Use `Unrouter.resolve` for one-off resolution:

```dart
final result = await router.resolve(Uri(path: '/users/1'));
if (result.isMatched) {
  print(result.route);
}
```

Use `UnrouterController` for runtime navigation/state flow:

```dart
final controller = UnrouterController<AppRoute>(
  router: router,
  history: MemoryHistory(),
);

await controller.idle;
print(controller.state.uri);
print(controller.resolution.type);
```

See `doc/runtime_controller.md` for the full controller API and adapter parity.
