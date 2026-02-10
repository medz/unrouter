# unrouter

Platform-agnostic URL-first typed router core for Dart.

## Install

```bash
dart pub add unrouter
```

## Entrypoint

- `package:unrouter/unrouter.dart`

## Quick start

```dart
import 'package:unrouter/unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

void main() async {
  final router = Unrouter<AppRoute>(
    routes: [
      route<UserRoute>(
        path: '/users/:id',
        parse: (state) => UserRoute(id: state.params.$int('id')),
      ),
    ],
  );

  final result = await router.resolve(Uri(path: '/users/42'));
  print(result.isMatched); // true
}
```

## Data routes

Use `dataRoute<T, L>()` when a route needs async loader data:

```dart
dataRoute<UserRoute, User>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.params.$int('id')),
  loader: (context) => api.fetchUser(context.route.id),
)
```

## Route parser state

`RouteState` exposes typed param/query helpers:

- `state.params.required('id')`
- `state.params.$int('id')`
- `state.params.$enum('tab', Tab.values)`
- `state.query.required('q')`
- `state.query.$double('threshold')`
- raw query map via `state.location.uri.queryParameters`

## Runtime controller (pure Dart)

```dart
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

final controller = UnrouterController<AppRoute>(
  router: router,
  history: MemoryHistory(),
);

await controller.idle;
controller.go(const UserRoute(id: 1));
final result = await controller.push<int>(const UserRoute(id: 2));
controller.pop(7);
await controller.sync(Uri(path: '/users/3'));
controller.dispose();
```

Primary runtime APIs:

- navigation: `go/goUri`, `push/pushUri`, `pop`, `back`
- shell actions: `switchBranch`, `popBranch`
- state: `state`, `resolution`, `states`, `idle`
- utility: `href`, `cast<S>()`, `sync`

## Shell integration for adapters

Core provides shell contracts and helpers for adapter packages:

- `ShellBranch`, `ShellState`, `ShellRouteRecordHost`
- `ShellCoordinator`
- `buildShellRouteRecords`, `requireShellRouteRecord`

For Flutter usage, install `flutter_unrouter`. For Jaspr usage, install
`jaspr_unrouter`.

## Complete Dart example

See `/example/bin/main.dart` for a full pure Dart scenario that covers:

- typed parser helpers (`params/query`)
- redirect + guard + block flows
- loader routes with typed data
- `UnrouterController` navigation and state stream
- redirect diagnostics
