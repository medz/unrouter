# jaspr_unrouter

Jaspr adapter package for `unrouter`.

## Install

```bash
dart pub add jaspr_unrouter
```

## Entrypoints

- `package:jaspr_unrouter/jaspr_unrouter.dart`: Jaspr adapter API

## Current scope

- Reuses `unrouter` core route resolution/runtime semantics.
- Exposes Jaspr `Unrouter` component for mounting/runtime binding.
- Exposes `CoreUnrouter` for pure Dart/controller-only scenarios.
- Provides Jaspr-flavored route definitions (`route`, `routeWithLoader`) with
  component builders.
- Provides shell helpers (`branch`, `shell`, `ShellState`) aligned with
  `flutter_unrouter` branch navigation semantics.
- Provides `context.unrouter` / `context.unrouterAs<T>()` navigation helpers.
- Keeps adapter scope thin and does not duplicate core runtime algorithms.

## Runtime binding

```dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart';

final router = Unrouter<AppRoute>(
  routes: [
    route<HomeRoute>(
      path: '/',
      parse: (_) => const HomeRoute(),
      builder: (_, __) => const Component.text('home'),
    ),
  ],
);

runApp(router);
```

Navigation from a component:

```dart
context.unrouterAs<AppRoute>().push(const HomeRoute());
context.unrouterAs<AppRoute>().go(const HomeRoute());
context.unrouterAs<AppRoute>().back();
```

Declarative link:

```dart
import 'package:jaspr/dom.dart';

UnrouterLink<HomeRoute>(
  route: const HomeRoute(),
  children: [span([text('Home')])],
)
```

Pure Dart usage (without mounting component router):

```dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart';
import 'package:unstory/unstory.dart';

final coreRouter = CoreUnrouter<AppRoute>(
  routes: [
    route<HomeRoute>(
      path: '/',
      parse: (_) => const HomeRoute(),
      builder: (_, __) => const Component.text('home'),
    ),
  ],
);

final controller = UnrouterController<AppRoute>(
  router: coreRouter,
  history: MemoryHistory(),
);
await controller.idle;
print(controller.state.resolution); // matched / unmatched / ...
controller.dispose();
```

## Example

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

void main() async {
  final router = Unrouter<AppRoute>(
    routes: [
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (_, __) => const Component.text('home'),
      ),
    ],
  );

  final result = await router.coreRouter.resolve(Uri(path: '/'));
  print(result.isMatched);
}
```
