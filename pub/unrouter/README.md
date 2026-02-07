# unrouter

Platform-agnostic URL-first typed router core for Dart.

## Install

```bash
dart pub add unrouter
```

## Entrypoints

- `package:unrouter/unrouter.dart`: core routing API
- `package:unrouter/machine.dart`: machine diagnostics API

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

## Flutter usage

For Flutter apps, use `flutter_unrouter` instead:

```bash
flutter pub add flutter_unrouter
```
