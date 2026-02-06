# Devtools guide

Import devtools symbols explicitly:

```dart
import 'package:unrouter/devtools.dart';
import 'package:unrouter/machine.dart';
import 'package:unrouter/unrouter.dart';
```

## Recommended app debug entry

The example app exposes `/debug` as a dedicated diagnostics screen. This keeps
runtime diagnostics accessible without polluting product pages.

## Inspector widget

```dart
final redirectStore = UnrouterRedirectDiagnosticsStore();

UnrouterInspectorWidget<AppRoute>(
  inspector: context.unrouterAs<AppRoute>().inspector,
  redirectDiagnostics: redirectStore,
  timelineTail: 8,
  redirectTrailTail: 4,
);
```

## Bridge and panel

```dart
final bridge = UnrouterInspectorBridge<AppRoute>(
  inspector: context.unrouterAs<AppRoute>().inspector,
  redirectDiagnostics: redirectStore,
);

final panel = UnrouterInspectorPanelAdapter.fromBridge(bridge: bridge);
```

Render a DevTools-like panel:

```dart
UnrouterInspectorPanelWidget(
  panel: panel,
  onExportSelected: (payload) => debugPrint(payload),
)
```

## Replay and persistence

```dart
final replay = UnrouterInspectorReplayStore.fromBridge(bridge: bridge);
final controller = UnrouterInspectorReplayController(store: replay);
```

Persistence entrypoint:

```dart
final persistence = UnrouterInspectorReplayPersistence(
  adapter: UnrouterInspectorReplayMemoryStorageAdapter(),
);
await persistence.save(replay);
await persistence.restore(replay);
```

More storage adapter patterns:

- `doc/replay_persistence_examples.md`

## Compatibility checks

Replay compatibility validation helps catch schema drift in saved emissions:

```dart
final result = replay.validateCompatibility();
if (result.hasIssues) {
  debugPrint(result.toJson().toString());
}
```
