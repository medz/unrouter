# Runtime controller guide

`UnrouterController` is the runtime navigation/state API.

- In pure Dart, it comes from `package:unrouter/unrouter.dart`.
- In Flutter, it comes from `package:flutter_unrouter/flutter_unrouter.dart`.

The primary method names are aligned across both packages.

## Pure Dart usage

```dart
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

final controller = UnrouterController<AppRoute>(
  router: router,
  history: MemoryHistory(),
);

await controller.idle;
controller.go(const HomeRoute());
final value = await controller.push<int>(const DetailRoute(id: 42));
controller.pop(7);
```

## Flutter usage

```dart
final controller = context.unrouterAs<AppRoute>();
controller.go(const HomeRoute());
```

`flutter_unrouter` reuses `unrouter` core runtime controller internally, then
adds Flutter-only binding behavior (delegate/scope/context extension/shell UI
integration).

## Shared APIs

Navigation:

- `go`, `goUri`
- `replace`, `replaceUri`
- `push`, `pushUri`
- `pop`, `popToUri`, `back`, `forward`, `goDelta`

State:

- `uri`, `route`, `historyState`
- `state`
- `resolution`
- `stateListenable`
- `states`
- `idle`

Utility:

- `href`, `hrefUri`
- `dispatchRouteRequest`
- `publishState`
- `dispose`

## Flutter-only extensions

The Flutter adapter adds shell-specific methods:

- `switchBranch`
- `popBranch`
- `setHistoryStateComposer` / `clearHistoryStateComposer`
- `setShellBranchResolvers` / `clearShellBranchResolvers`

These are intentionally adapter-local because they depend on Flutter shell
navigation lifecycle.

## Shell coordination boundary

- Shell stack algorithms, restoration snapshot, and `history.state` envelope
  codec are core concerns and live in `unrouter` (`ShellCoordinator`).
- `flutter_unrouter` only maps Flutter shell UI events to that core
  coordinator.
