# nocterm_unrouter

Nocterm adapter for `unrouter`.

## Install

```bash
dart pub add nocterm_unrouter
```

## Entrypoint

- `package:nocterm_unrouter/nocterm_unrouter.dart`

## What this package adds

- Nocterm `Unrouter` component runtime binding
- Nocterm component route builders
- `UnrouterScope` and `BuildContext` extensions
- Shell UI binding using core shell runtime (`ShellState`)

Route matching, guards, redirects, loader execution, and runtime controller
semantics come from `unrouter`.

## Quick start

```dart
import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

Future<void> main() async {
  await runApp(
    Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Text('home'),
        ),
      ],
    ),
  );
}
```

## Route records

Adapter route record surface:

- `RouteDefinition<T>` for non-loader routes
- `DataRouteDefinition<T, L>` for loader routes
- `RouteRecord<T>` as adapter record contract

`dataRoute<T, L>()` returns `DataRouteDefinition<T, L>`.

## Runtime access in components

```dart
final controller = context.unrouterAs<AppRoute>();
controller.go(const HomeRoute());
controller.push<void>(const HomeRoute());
controller.back();
```
