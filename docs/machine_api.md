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

## Dispatch declarative actions

```dart
machine.dispatchAction<void>(
  UnrouterMachineAction.navigateRoute(
    const UserRoute(id: 7),
    mode: UnrouterMachineNavigateMode.replace,
  ),
);
```

## Use action envelopes

Action envelopes expose explicit state for command outcomes:

- `accepted`
- `rejected`
- `deferred`
- `completed`

```dart
final envelope = machine.dispatchActionEnvelope<Future<int?>>(
  UnrouterMachineAction.pushRoute<UserRoute, int>(const UserRoute(id: 8)),
);

if (envelope.isDeferred) {
  final value = await envelope.value;
  debugPrint('deferred value: $value');
}

if (envelope.isRejected) {
  debugPrint('reject code: ${envelope.rejectCode}');
  debugPrint('reject failure: ${envelope.failure?.toJson()}');
}
```

## Inspect machine state and transitions

```dart
final machineState = machine.state;
final rawTimeline = machine.timeline;
final typedTimeline = machine.typedTimeline;
```

Typed transitions classify payload shape by kind:

- `actionEnvelope`
- `navigation`
- `route`
- `controller`
- `generic`

See `docs/machine_action_envelope_schema.md` for schema compatibility details.
