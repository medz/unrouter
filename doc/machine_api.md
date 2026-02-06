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

## Dispatch commands

```dart
machine.dispatch<void>(UnrouterMachineCommand.goUri(Uri(path: '/')));
final pushed = machine.dispatch<Future<Object?>>(
  UnrouterMachineCommand.pushUri(Uri(path: '/users/42')),
);
final canBack = machine.dispatch<bool>(UnrouterMachineCommand.back());
```

## Inspect machine state and transitions

```dart
final machineState = machine.state;
final rawTimeline = machine.timeline;
final typedTimeline = machine.timeline
    .map((entry) => entry.typed)
    .toList(growable: false);
```

Typed transitions classify payload shape by kind:

- `navigation`
- `route`
- `controller`
- `generic`
