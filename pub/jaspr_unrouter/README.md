# jaspr_unrouter

Jaspr adapter for `unrouter`.

## Install

```bash
dart pub add jaspr_unrouter
```

## Entrypoint

```dart
import 'package:jaspr_unrouter/jaspr_unrouter.dart';
```

## What this adapter adds

- `Unrouter<R>` as a Jaspr `StatefulComponent`
- Jaspr route records with component builders
- `UnrouterScope` and `BuildContext` helpers
- `UnrouterLink` for declarative typed navigation
- Shell composition helpers (`branch()` + `shell()`)

Core route semantics are provided by `unrouter`.

## Quick start

```dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/server.dart';
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
  Jaspr.initializeApp();

  runApp(
    Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('Home'),
        ),
      ],
    ),
  );
}
```

## Runtime access in components

```dart
final controller = context.unrouterAs<AppRoute>();
controller.go(const HomeRoute());
```

## Declarative links

```dart
UnrouterLink<HomeRoute>(
  route: const HomeRoute(),
  children: const <Component>[Component.text('Go home')],
)
```

## Fallback builders

`Unrouter` supports:

- `unknown(BuildContext, Uri)`
- `blocked(BuildContext, Uri)`
- `loading(BuildContext, Uri)`
- `onError(BuildContext, Object, StackTrace)`

`resolveInitialRoute` defaults to `true` in Jaspr adapter.

## Example

```bash
cd pub/jaspr_unrouter/example
dart pub get
dart run lib/main.dart
```

Example source:

- `example/lib/main.dart`
