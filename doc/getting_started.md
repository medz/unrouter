# Getting started

## Choose package

- Pure Dart runtime or custom runtime integration: use `unrouter`.
- Flutter app: use `flutter_unrouter` only (it already depends on `unrouter`).

## Install

Pure Dart:

```bash
dart pub add unrouter
```

Flutter:

```bash
flutter pub add flutter_unrouter
```

## Core imports

Pure Dart:

```dart
import 'package:unrouter/unrouter.dart';
```

Flutter:

```dart
import 'package:flutter_unrouter/flutter_unrouter.dart';
```

## Minimal typed router (pure Dart)

```dart
import 'package:unrouter/unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

void main() async {
  final router = Unrouter<AppRoute>(
    routes: [
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
      ),
    ],
  );

  final resolution = await router.resolve(Uri(path: '/'));
  print(resolution.isMatched); // true
}
```

## Minimal Flutter integration

```dart
import 'package:flutter/material.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

void main() {
  final router = Unrouter<AppRoute>(
    routes: [
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (_, __) => const Text('Home'),
      ),
    ],
  );

  runApp(MaterialApp.router(routerConfig: router));
}
```

## Runtime navigation API consistency

`unrouter` and `flutter_unrouter` expose the same primary controller methods:

- `go/goUri`
- `replace/replaceUri`
- `push/pushUri`
- `pop/popToUri/back/forward/goDelta`
- `state`, `resolution`, `stateListenable`

Flutter adds shell-only helpers (`switchBranch`, `popBranch`) on top.

## Next reads

- Core route semantics: `doc/core_routing.md`
- Runtime controller details: `doc/runtime_controller.md`
- Shell state envelope: `doc/state_envelope.md`
