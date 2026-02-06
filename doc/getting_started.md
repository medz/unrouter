# Getting started

## Install

```bash
flutter pub add unrouter
```

## Core imports

```dart
import 'package:unrouter/unrouter.dart';
```

Use additional entrypoints only when needed:

- `package:unrouter/machine.dart`: machine command APIs.

## Minimal typed router

```dart
import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

void main() {
  final router = Unrouter<AppRoute>(
    routes: [
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (_, __) => const HomePage(),
      ),
      route<UserRoute>(
        path: '/users/:id',
        parse: (state) => UserRoute(id: state.pathInt('id')),
        builder: (_, route) => UserPage(id: route.id),
      ),
    ],
    unknown: (_, uri) => NotFoundPage(uri: uri),
  );

  runApp(MaterialApp.router(routerConfig: router));
}
```

## Navigate from widgets

```dart
context.unrouter.go(const HomeRoute());
context.unrouter.push(const UserRoute(id: 42));
context.unrouter.replace(const UserRoute(id: 7));
context.unrouter.back();

final int? value = await context.unrouter.push<int>(const UserRoute(id: 42));
context.unrouter.pop(7);
```

## Next reads

- Core behavior and advanced route features: `doc/core_routing.md`
- Command machine API: `doc/machine_api.md`
