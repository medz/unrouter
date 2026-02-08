# flutter_unrouter

Flutter adapter for `unrouter`.

## Install

```bash
flutter pub add flutter_unrouter
```

## Entrypoint

- `package:flutter_unrouter/flutter_unrouter.dart`

## What this package adds

- Flutter `RouterConfig` integration (`Unrouter`)
- Flutter route builders/pages/transitions
- `UnrouterScope` and `BuildContext` extensions (`context.unrouter`)
- Shell UI binding on top of core shell runtime (`ShellState`)

Route matching, guards, redirects, loader execution, and runtime controller
semantics still come from `unrouter`.

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
    routes: <RouteRecord<AppRoute>>[
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

## Route records

Adapter route record surface:

- `RouteDefinition<T>` for non-loader routes
- `DataRouteDefinition<T, L>` for loader routes
- `RouteRecord<T>` as adapter record contract

`dataRoute<T, L>()` returns `DataRouteDefinition<T, L>`.

## Runtime access

```dart
final controller = context.unrouterAs<AppRoute>();
controller.go(const HomeRoute());
controller.push<void>(const HomeRoute());
controller.back();
```

Optional `Unrouter` builders:

- `unknown(BuildContext, Uri)`
- `blocked(BuildContext, Uri)` (falls back to `unknown` when absent)
- `loading(BuildContext, Uri)`
- `onError(BuildContext, Object, StackTrace)`

## Example

```bash
cd pub/flutter_unrouter/example
flutter pub get
flutter run -d chrome
```
