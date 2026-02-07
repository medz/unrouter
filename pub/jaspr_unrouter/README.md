# jaspr_unrouter

Jaspr adapter skeleton package for `unrouter`.

## Install

```bash
dart pub add jaspr_unrouter
```

## Entrypoints

- `package:jaspr_unrouter/jaspr_unrouter.dart`: Jaspr adapter API

## Current scope

- Reuses `unrouter` core route resolution/runtime semantics.
- Provides Jaspr-flavored route definitions (`route`, `routeWithLoader`) with
  component builders.
- Keeps adapter scope thin and does not duplicate core runtime algorithms.

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

  final result = await router.resolve(Uri(path: '/'));
  print(result.isMatched);
}
```
