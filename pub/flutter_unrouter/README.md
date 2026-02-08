# flutter_unrouter

Flutter adapter package for unrouter.

## Install

```bash
flutter pub add flutter_unrouter
```

## Entrypoints

- `package:flutter_unrouter/flutter_unrouter.dart`: Flutter routing API

## Layering

`flutter_unrouter` is an adapter package:

- Route resolution and runtime navigation semantics come from `unrouter`.
- Shell branch restoration/stack coordination also comes from
  `unrouter` (`ShellCoordinator`).
- This package only adds Flutter bindings (RouterDelegate/Scope/BuildContext
  extensions/Page & transition builders).

## Quick start

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

Optional pending-state UI can read the target URI:

```dart
loading: (context, uri) => const CircularProgressIndicator(),
```

## Example

```bash
cd pub/flutter_unrouter/example
flutter pub get
flutter run -d chrome
```
