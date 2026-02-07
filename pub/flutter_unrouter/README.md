# flutter_unrouter

Flutter adapter package for unrouter.

## Install

```bash
flutter pub add flutter_unrouter
```

## Entrypoints

- `package:flutter_unrouter/flutter_unrouter.dart`: Flutter routing API
- `package:flutter_unrouter/machine.dart`: machine commands and timeline APIs

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

## Example

```bash
cd pub/flutter_unrouter/example
flutter pub get
flutter run -d chrome
```
