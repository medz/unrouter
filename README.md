# unrouter

A URL-first typed router for Flutter.

## Why unrouter

- Typed route objects via `RouteData`
- Route matching powered by `roux`
- Browser history integration via `unstory`
- Core API by default, optional machine and devtools layers

## Install

```bash
flutter pub add unrouter
```

## Entrypoints

- `package:unrouter/unrouter.dart`: core routing API
- `package:unrouter/machine.dart`: machine commands/actions
- `package:unrouter/devtools.dart`: inspector/panel/replay tooling

Import `unrouter.dart` explicitly. Other entrypoints do not re-export core APIs.

## Quick start

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
  const UserRoute(this.id);
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
        builder: (_, __) => const Text('Home'),
      ),
      route<UserRoute>(
        path: '/users/:id',
        parse: (state) => UserRoute(state.pathInt('id')),
        builder: (_, route) => Text('User ${route.id}'),
      ),
    ],
    unknown: (_, uri) => Text('404 ${uri.path}'),
  );

  runApp(MaterialApp.router(routerConfig: router));
}
```

## Navigation

```dart
context.unrouter.go(const HomeRoute());
context.unrouter.push(const UserRoute(42));
context.unrouter.replace(const UserRoute(7));
final int? result = await context.unrouter.push<int>(const UserRoute(42));
context.unrouter.pop(7);
```

## Example app

```bash
cd example
flutter pub get
flutter run -d chrome
```

Open `/debug` (or tap the bug icon) for inspector/panel/replay diagnostics.

## Docs

- Overview: `doc/README.md`
- Getting started: `doc/getting_started.md`
- Core routing: `doc/core_routing.md`
- Machine API: `doc/machine_api.md`
- Devtools: `doc/devtools.md`
- Contracts: `doc/state_envelope.md`, `doc/machine_action_envelope_schema.md`
- Benchmark guide: `doc/router_benchmarking.md`
