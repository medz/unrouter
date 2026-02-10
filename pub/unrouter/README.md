# unrouter

[![pub package](https://img.shields.io/pub/v/unrouter.svg)](https://pub.dev/packages/unrouter)
[![pub points](https://img.shields.io/pub/points/unrouter)](https://pub.dev/packages/unrouter/score)
[![CI](https://github.com/medz/unrouter/actions/workflows/tests.yml/badge.svg)](https://github.com/medz/unrouter/actions/workflows/tests.yml)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.10.0-0175C2.svg)](https://dart.dev)

Platform-agnostic, URL-first typed router core for Dart.

## Install

```bash
dart pub add unrouter
```

## Entrypoint

```dart
import 'package:unrouter/unrouter.dart';
```

## Core model

- `RouteData`: typed route object with `toUri()`.
- `route<T>()`: typed route definition (parse + optional guards/redirect).
- `dataRoute<T, L>()`: typed route definition with async loader data.
- `RouteState`: parser input with typed helpers for params/query.
- `UnrouterController<T>`: pure Dart runtime controller for navigation/state.

## Quick start

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

final class ProductRoute extends AppRoute {
  const ProductRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/products/$id');
}

Future<void> main() async {
  final router = Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
      dataRoute<ProductRoute, String>(
        path: '/products/:id',
        parse: (state) => ProductRoute(id: state.params.$int('id')),
        loader: (context) async => 'loaded:${context.route.id}',
      ),
    ],
  );

  final resolution = await router.resolve(Uri(path: '/products/42'));
  print(resolution.isMatched); // true
  print(resolution.loaderData); // loaded:42
}
```

## Parser helpers (`RouteState`)

Use typed helpers on both `params` and `query`:

- `required(key)`
- `decode<T>(key, parser)`
- `$num(key)`
- `$int(key)`
- `$double(key)`
- `$enum(key, values)`

Example:

```dart
parse: (state) {
  final id = state.params.$int('id');
  final includeDraft = state.query.containsKey('draft') &&
      state.query.decode<bool>('draft', (raw) {
          if (raw == '1') return true;
          if (raw == '0') return false;
          return null;
        }) == true;

  if (includeDraft) {
    // custom branch for query-driven parsing
  }

  return ProductRoute(id: id);
}
```

## Runtime controller (pure Dart)

```dart
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

final controller = UnrouterController<AppRoute>(
  router: router,
  history: MemoryHistory(
    initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/'))],
    initialIndex: 0,
  ),
);

await controller.idle;
controller.go(const HomeRoute());
final pendingQty = controller.push<int>(const ProductRoute(id: 42));

// In real UI flows, pop is called from the pushed route.
Future<void>.microtask(() {
  controller.pop<int>(2);
});

final qty = await pendingQty;

print(qty); // 2
controller.dispose();
```

Main APIs:

- Navigation: `go/goUri`, `push/pushUri`, `pop`, `back`
- Shell actions: `switchBranch`, `popBranch`
- State: `state`, `states`, `resolution`, `idle`
- Utility: `href`, `cast<S>()`, `sync`

## Redirect safety

Core supports:

- `maxRedirectHops`
- `redirectLoopPolicy`
- `onRedirectDiagnostics`

This keeps redirect chains observable and bounded.

## Example

A complete pure Dart scenario is available at:

- `example/bin/main.dart`
