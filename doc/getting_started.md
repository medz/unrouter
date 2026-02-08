# Getting started

## Choose package

- Pure Dart runtime, no UI binding: `unrouter`
- Flutter app integration: `flutter_unrouter`
- Jaspr app integration: `jaspr_unrouter`

Use one adapter package in apps; adapters already depend on core `unrouter`.

## Install

Core:

```bash
dart pub add unrouter
```

Flutter:

```bash
flutter pub add flutter_unrouter
```

Jaspr:

```bash
dart pub add jaspr_unrouter
```

## Minimal typed routing (core)

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

final router = Unrouter<AppRoute>(
  routes: [
    route<UserRoute>(
      path: '/users/:id',
      parse: (state) => UserRoute(id: state.params.$int('id')),
    ),
  ],
);
```

## Loader routes

Use `dataRoute<T, L>()` for async preload data:

```dart
dataRoute<UserRoute, User>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.params.$int('id')),
  loader: (context) => api.fetchUser(context.route.id),
)
```

## Runtime navigation

```dart
final controller = UnrouterController<AppRoute>(router: router);

controller.go(const UserRoute(id: 1));
final value = await controller.push<int>(const UserRoute(id: 2));
controller.pop(7);
controller.back();
await controller.sync(Uri(path: '/users/3'));
```

Current primary controller methods:

- `go/goUri`
- `push/pushUri`
- `pop`
- `back`
- `sync`
- `switchBranch/popBranch` (shell record context only)

## Flutter mount

```dart
runApp(MaterialApp.router(routerConfig: router));
```

Where `router` is `Unrouter<AppRoute>` from `flutter_unrouter`.

## Jaspr mount

```dart
runApp(
  Unrouter<AppRoute>(
    routes: [...],
  ),
);
```

Where `Unrouter` is from `jaspr_unrouter`.
