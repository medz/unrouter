# Core routing guide

This guide targets `package:unrouter/unrouter.dart`.

## Route definitions

Non-loader route:

```dart
route<UserRoute>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.params.$int('id')),
)
```

Loader route:

```dart
dataRoute<UserRoute, User>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.params.$int('id')),
  loader: (context) => api.fetchUser(context.route.id),
)
```

## Parser helpers (`RouteState`)

`RouteState` is passed to `parse`.

- `state.params.required('id')`
- `state.params.$int('id')`, `$double`, `$num`, `$enum`
- `state.query.required('tab')`
- `state.query.$enum('tab', Tab.values)`
- raw query map: `state.location.uri.queryParameters`

## Guards and redirects

Route guards:

```dart
guards: [
  (context) async {
    final signedIn = await auth.isSignedIn();
    if (signedIn) return RouteGuardResult.allow();
    return RouteGuardResult.redirect(Uri(path: '/login'));
  },
]
```

Route redirect:

```dart
redirect: (_) => Uri(path: '/canonical-path')
```

Router-level redirect safety:

```dart
Unrouter<AppRoute>(
  routes: [...],
  maxRedirectHops: 8,
  redirectLoopPolicy: RedirectLoopPolicy.error,
  onRedirectDiagnostics: (event) {
    print('${event.reason.name} ${event.hop}/${event.maxHops}');
  },
)
```

## Route resolution

```dart
final result = await router.resolve(Uri(path: '/users/1'));

if (result.isMatched) {
  print(result.record?.path);
  print(result.route);
} else if (result.isRedirect) {
  print(result.redirectUri);
}
```

## Shell metadata (adapter-facing)

Core shell contracts are runtime/UI agnostic:

- `ShellBranch`
- `ShellState`
- `ShellRouteRecordHost`
- `shell()` and `branch()` for branch table assembly

Adapter-focused helpers:

- `ShellCoordinator`
- `buildShellRouteRecords`
- `requireShellRouteRecord`
