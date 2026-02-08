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

controller.setHistoryStateComposer((request) {
  return {
    'uri': request.uri.toString(),
    'action': request.action.name,
    'userState': request.state,
  };
});

controller.setShellBranchResolvers(
  resolveTarget: (index, {required initialLocation}) {
    if (index == 0) return Uri(path: '/feed');
    if (index == 1) return Uri(path: '/settings');
    return null;
  },
  popTarget: () => Uri(path: '/feed'),
);

controller.dispose();
```

## Shell coordinator (platform-agnostic)

Use `ShellCoordinator` when building adapter packages or custom runtimes. It
provides branch stack tracking and `history.state` envelope composition without
depending on Flutter/Jaspr/Nocterm APIs.

```dart
final coordinator = ShellCoordinator(
  branches: [
    ShellBranchDescriptor(
      index: 0,
      initialLocation: Uri(path: '/feed'),
      routePatterns: ['/feed', '/feed/:id'],
    ),
  ],
);

coordinator.recordNavigation(
  branchIndex: 0,
  event: ShellNavigationEvent(
    uri: Uri(path: '/feed'),
    action: HistoryAction.replace,
    delta: null,
    historyIndex: 0,
  ),
);
```

## Flutter usage

For Flutter apps, use `flutter_unrouter` instead:

```bash
flutter pub add flutter_unrouter
```
