# Machine API guide

Import machine symbols explicitly:

```dart
import 'package:unrouter/machine.dart';
import 'package:unrouter/unrouter.dart';
```

## Access machine from context

```dart
final machine = context.unrouterMachineAs<AppRoute>();
```

## Dispatch typed commands

```dart
machine.dispatchTyped<void>(UnrouterMachineCommand.goUri(Uri(path: '/')));
final pushed = machine.dispatchTyped<Future<Object?>>(
  UnrouterMachineCommand.pushUri(Uri(path: '/users/42')),
);
final canBack = machine.dispatchTyped<bool>(UnrouterMachineCommand.back());
```

## Inspect machine state and transitions

```dart
final machineState = machine.state;
final rawTimeline = machine.timeline;
final typedTimeline = machine.typedTimeline;
```

Typed transitions classify payload shape by kind:

- `navigation`
- `route`
- `controller`
- `generic`
