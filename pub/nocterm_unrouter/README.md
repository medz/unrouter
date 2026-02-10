# nocterm_unrouter

Nocterm adapter for `unrouter`.

## Install

```bash
dart pub add nocterm_unrouter
```

## Entrypoint

```dart
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
```

## What this adapter adds

- `Unrouter<R>` as a Nocterm `StatefulComponent`
- Nocterm route records with component builders
- `UnrouterScope` and `BuildContext` helpers
- Shell composition helpers (`branch()` + `shell()`)

Core route semantics are provided by `unrouter`.

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
    NoctermApp(
      title: 'Demo',
      child: Unrouter<AppRoute>(
        routes: <RouteRecord<AppRoute>>[
          route<HomeRoute>(
            path: '/',
            parse: (_) => const HomeRoute(),
            builder: (_, __) => const Text('Home'),
          ),
        ],
      ),
    ),
  );
}
```

## Runtime access in components

```dart
final controller = context.unrouterAs<AppRoute>();
controller.go(const HomeRoute());
```

## Fallback builders

`Unrouter` supports:

- `unknown(BuildContext, Uri)`
- `blocked(BuildContext, Uri)`
- `loading(BuildContext, Uri)`
- `onError(BuildContext, Object, StackTrace)`

`resolveInitialRoute` defaults to `true` in Nocterm adapter.

## Keyboard-first shell apps

Nocterm adapter works well with `Focusable` and key bindings to drive
`controller.go`, `controller.back`, `shellState.goBranch`, and
`shellState.popBranch`.

## Example

```bash
cd pub/nocterm_unrouter/example
dart pub get
dart run bin/main.dart
```

Example source:

- `example/bin/main.dart`
