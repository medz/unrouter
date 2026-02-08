# Runtime controller guide

`UnrouterController` is the shared runtime navigation/state API.

- Core: `package:unrouter/unrouter.dart`
- Flutter adapter: reuses core controller and adds Flutter listenable helpers
- Jaspr adapter: reuses core controller via component binding

## Create controller (core)

```dart
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

final controller = UnrouterController<AppRoute>(
  router: router,
  history: MemoryHistory(),
);
```

## Navigation methods

- `go(route, {state})`
- `goUri(uri, {state})`
- `push<T>(route, {state})`
- `pushUri<T>(uri, {state})`
- `pop([result])`
- `back()`
- `switchBranch(index, ...)`
- `popBranch([result])`

Removed legacy methods (`replace*`, `forward`, `goDelta`, `popToUri`) are not
part of current public API.

## Runtime/state methods

- `state` (`StateSnapshot`)
- `resolution` (`RouteResolution`)
- `states` (`Stream<StateSnapshot>`)
- `idle` (`Future<void>`)
- `route`
- `uri`
- `href(route)`
- `sync(uri, {state})`
- `cast<S>()`
- `dispose()`

## Flutter usage

```dart
final controller = context.unrouterAs<AppRoute>();
controller.go(const HomeRoute());
```

`flutter_unrouter` also exposes `stateListenable` via extension for widget
integration.

## Shell behavior boundary

Shell navigation state is coordinated in core (`ShellCoordinator` and
`ShellRouteRecordHost`). Adapters only connect UI events to controller methods.
