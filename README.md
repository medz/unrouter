# unrouter

A URL-first Flutter router with typed route objects.

## Highlights

- Typed route model via `RouteData`
- URL matching powered by `roux`
- Browser history integration powered by `unstory`
- Async route hooks: `guards`, `redirect`, `routeWithLoader`
- Shell branch routing with branch-stack restoration
- Optional advanced layers: machine API and devtools/replay diagnostics

## Install

```bash
flutter pub add unrouter
```

## Entrypoints

- `package:unrouter/unrouter.dart`: core routing API (default)
- `package:unrouter/machine.dart`: machine commands/actions/envelopes
- `package:unrouter/devtools.dart`: inspector/panel/replay tooling

`machine.dart` and `devtools.dart` do not re-export core APIs.
Import `unrouter.dart` explicitly.

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

## Navigate

```dart
context.unrouter.go(const HomeRoute());
context.unrouter.push(const UserRoute(id: 42));
context.unrouter.replace(const UserRoute(id: 7));
context.unrouter.back();

final int? value = await context.unrouter.push<int>(const UserRoute(id: 42));
context.unrouter.pop(7);
```

## Example app

```bash
cd example
flutter pub get
flutter run -d chrome
```

Open `/debug` (or tap the bug icon) to access inspector/panel/replay diagnostics.

## Documentation

- Index: `doc/README.md`
- Getting started: `doc/getting_started.md`
- Core routing: `doc/core_routing.md`
- Machine API: `doc/machine_api.md`
- Devtools: `doc/devtools.md`
- State envelope contract: `doc/state_envelope.md`
- Action envelope schema: `doc/machine_action_envelope_schema.md`
- Replay persistence templates: `doc/replay_persistence_examples.md`
- Benchmark guide: `doc/router_benchmarking.md`

## Benchmarks

```bash
cd bench
dart run main.dart
```

For stress profile:

```bash
cd bench
dart run main.dart --aggressive
```
