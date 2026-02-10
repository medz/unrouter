# jaspr_unrouter

Jaspr adapter for `unrouter`.

## Install

```bash
dart pub add jaspr_unrouter
```

## Entrypoint

- `package:jaspr_unrouter/jaspr_unrouter.dart`

## What this package adds

- Jaspr `Unrouter` component runtime binding
- Jaspr component route builders
- `UnrouterScope` and `BuildContext` extensions
- `UnrouterLink` declarative link component
- Shell UI binding using core shell runtime (`ShellState`)

Route matching, guards, redirects, loader execution, and runtime controller
semantics come from `unrouter`.

## Quick start

```dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

void main() {
  runApp(
    Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home'),
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

## Declarative links

```dart
import 'package:jaspr/dom.dart';

UnrouterLink<HomeRoute>(
  route: const HomeRoute(),
  children: [span([text('Home')])],
)
```

## Example

```bash
cd pub/jaspr_unrouter/example
dart pub get
dart run lib/main.dart
```

The `example/` app is a complete storefront demo with polished UI, shell
branches, typed route parsing, data loaders, guard redirect/block behavior, and
typed push/pop result flow.
