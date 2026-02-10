# flutter_unrouter

Flutter adapter for `unrouter`.

## Install

```bash
flutter pub add flutter_unrouter
```

## Entrypoint

```dart
import 'package:flutter_unrouter/flutter_unrouter.dart';
```

## What this adapter adds

- `Unrouter<R>` implementing `RouterConfig<HistoryLocation>`
- Flutter route records with widget/page/transition builders
- `UnrouterScope` and `BuildContext` extensions (`context.unrouter`)
- Shell composition helpers for branch-based UI

Core semantics (matching, guards, redirects, loaders, state model) are still
owned by `unrouter`.

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
        builder: (_, __) => const Scaffold(body: Center(child: Text('Home'))),
      ),
    ],
  );

  runApp(MaterialApp.router(routerConfig: router));
}
```

## Route records

- `RouteDefinition<T>` via `route<T>()`
- `DataRouteDefinition<T, L>` via `dataRoute<T, L>()`
- Optional per-route page configuration:
  - `pageBuilder`
  - `transitionBuilder`
  - `transitionDuration`
  - `reverseTransitionDuration`

## Runtime access in widgets

```dart
final controller = context.unrouterAs<AppRoute>();
controller.go(const HomeRoute());
```

Also available:

- `context.unrouter` (untyped)
- `controller.stateListenable` for `ValueListenable<StateSnapshot<T>>`

## Fallback builders

`Unrouter` supports optional fallback UI:

- `unknown(BuildContext, Uri)`
- `blocked(BuildContext, Uri)`
- `loading(BuildContext, Uri)`
- `onError(BuildContext, Object, StackTrace)`

`resolveInitialRoute` defaults to `false` in Flutter adapter.

## Shell routing

Use `branch()` + `shell()` to compose branch-aware UI while sharing one
controller/runtime state.

## Example

```bash
cd pub/flutter_unrouter/example
flutter pub get
flutter run -d chrome
```

Example source:

- `example/lib/main.dart`
