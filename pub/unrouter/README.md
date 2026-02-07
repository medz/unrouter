# unrouter

Platform-agnostic URL-first typed router core for Dart.

## Install

```bash
dart pub add unrouter
```

## Entrypoints

- `package:unrouter/unrouter.dart`: core routing API

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

void main() async {
  final router = Unrouter<AppRoute>(
    routes: [
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
      ),
    ],
  );

  final result = await router.resolve(Uri(path: '/'));
  if (result.isMatched) {
    print(result.route.runtimeType);
  }
}
```

## Runtime controller (pure Dart)

```dart
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

final router = Unrouter<AppRoute>(
  routes: [
    route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
  ],
);

final controller = UnrouterController<AppRoute>(
  router: router,
  history: MemoryHistory(),
);

await controller.idle;
print(controller.state.resolution); // matched
controller.dispose();
```

## Flutter usage

For Flutter apps, use `flutter_unrouter` instead:

```bash
flutter pub add flutter_unrouter
```
