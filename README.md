# unrouter

A URL-first Flutter router with typed route objects.

Project target knowledge lives in `docs/target_knowledge.md`.
Declarative state-machine draft lives in `docs/state_machine_draft.md`.
Machine action-envelope schema contract lives in
`docs/machine_action_envelope_schema.md`.

## Features

- Typed route objects via `RouteData`
- Path matching powered by `roux`
- Browser-style history powered by `unstory`
- Context navigation API: `go`, `push`, `replace`, `back`, `forward`, `href`
- Typed push results via `push<T>()` and `pop(result)`
- Route-level `Page` and transition customization
- Redirect loop/hop safety controls
- Route-state introspection snapshot/subscription API
- Devtools-friendly inspector helpers
- Built-in inspector widget for debug overlays
- DevTools panel adapter model fed by bridge stream
- Built-in inspector panel widget for DevTools-like diagnostics UI
- Replay store for emission export/import/playback workflows
- Replay controller for speed/scrub/bookmark/pause-resume controls
- Replay persistence adapters with schema migration hooks
- Replay session diff tooling for sequence/path comparison
- Side-by-side replay compare view in panel widget
- Replay panel compare folding and diff-only timeline filter
- Replay panel diff clustering by continuous sequence segments
- Replay panel cluster risk summary and high-risk quick actions
- Replay panel machine event-group quick filter controls
- Replay panel machine payload-kind quick filter controls
- Inspector/bridge/replay reports include machine transition timeline
- Machine timeline uses typed `source/event` schema with unified `from/to` state snapshots
- Public machine dispatch API (`UnrouterMachineCommand` + typed `dispatchTyped<T>()`)
- Declarative machine action draft API (`UnrouterMachineAction` + `dispatchAction<T>()`)
- Unified declarative navigate actions via `navigateUri` / `navigateRoute` with `mode` (`go` or `replace`)
- Machine action envelope API (`dispatchActionEnvelope<T>()`) with `accepted/rejected/deferred/completed` states and structured failure metadata
- Typed machine transition event view (`UnrouterMachineTypedTransition`) via `entry.typed` / `machine.typedTimeline` with typed payloads for controller/actionEnvelope, navigation, and route sources
- Machine timeline semantic event grouping (`UnrouterMachineEventGroup`) with inspector filtering support
- Replay compatibility validation covers action-envelope schema/event and controller lifecycle coverage
- Performance budget regression tests for machine transition projection and replay compatibility validation
- Declarative state-machine evolution draft and compatibility mapping
- Parser helpers for strongly typed path/query values
- Async route hooks: `guards`, `redirect`, and `routeWithLoader`
- Cooperative cancellation for async hooks via `RouteExecutionSignal`
- Shell + branch routing with per-branch stacks

## Installation

```bash
flutter pub add unrouter
```

## API entrypoints

- `package:unrouter/unrouter.dart`: default core routing API for most apps.
- `package:unrouter/machine.dart`: advanced machine command/action API.
- `package:unrouter/devtools.dart`: inspector, panel, and replay tooling.

`machine.dart` and `devtools.dart` do not re-export core symbols.
Import `unrouter.dart` explicitly when you need core routing APIs.

## Example

```bash
cd example
flutter pub get
flutter run -d chrome
```

After launch, open `/debug` (or tap the bug icon in app bar) to access the
inspector/bridge/panel/replay diagnostics entry.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  final router = Unrouter<AppRoute>(
    machineTimelineLimit: 512,
    routes: [
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (context, route) => const HomePage(),
      ),
      route<UserRoute>(
        path: '/users/:id',
        parse: (state) => UserRoute(
          id: state.pathInt('id'),
          tab: state.queryEnum('tab', UserTab.values, fallback: UserTab.posts),
        ),
        builder: (context, route) => UserPage(route: route),
      ),
    ],
    unknown: (context, uri) => NotFoundPage(uri: uri),
  );

  runApp(MaterialApp.router(routerConfig: router));
}

enum UserTab { posts, likes }

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id, this.tab = UserTab.posts});

  final int id;
  final UserTab tab;

  @override
  Uri toUri() => Uri(
        path: '/users/$id',
        queryParameters: {'tab': tab.name},
      );
}
```

## Navigate from widgets

For core navigation APIs, import `package:unrouter/unrouter.dart`.  
For machine APIs in this section, also import `package:unrouter/machine.dart`.

```dart
context.unrouter.go(const HomeRoute());
context.unrouter.push(const UserRoute(id: 42));
context.unrouter.replace(const UserRoute(id: 7));
context.unrouter.back();

final int? picked = await context.unrouter.push<int>(const UserRoute(id: 42));
context.unrouter.pop(7);
context.unrouter.replace(
  const UserRoute(id: 7),
  completePendingResult: true,
  result: 7,
);

final href = context.unrouter.href(const UserRoute(id: 42));
final currentUri = context.unrouter.uri;
final currentRoute = context.unrouter.route;

final typed = context.unrouterAs<AppRoute>();
typed.push(const UserRoute(id: 42));
final AppRoute? currentTypedRoute = typed.route;

final machine = context.unrouterMachineAs<AppRoute>();
final pushResult = machine.dispatchTyped<Future<Object?>>(
  UnrouterMachineCommand.pushUri(Uri(path: '/users/42')),
);
final popped = machine.dispatchTyped<bool>(UnrouterMachineCommand.back());
final switched = machine.dispatchTyped<bool>(
  UnrouterMachineCommand.switchBranch(1),
);
final poppedBranch = machine.dispatchTyped<bool>(
  UnrouterMachineCommand.popBranch(),
);
debugPrint('machine popped=$popped pushResult=$pushResult');
final machineState = machine.state;
final machineTimeline = machine.timeline;
final typedMachineTimeline = machine.typedTimeline;

final latestTypedEnvelope = typedMachineTimeline
    .where((entry) => entry.event == UnrouterMachineEvent.actionEnvelope)
    .last;
if (latestTypedEnvelope.payload is UnrouterMachineActionEnvelopeTypedPayload) {
  final payload =
      latestTypedEnvelope.payload as UnrouterMachineActionEnvelopeTypedPayload;
  debugPrint(
    'typed envelope state=${payload.actionState?.name} '
    'schemaOk=${payload.isSchemaCompatible} '
    'eventOk=${payload.isEventCompatible}',
  );
}

final typedNavigation = typedMachineTimeline.firstWhere(
  (entry) => entry.payload.kind == UnrouterMachineTypedPayloadKind.navigation,
);
debugPrint('typed navigation payload=${typedNavigation.payload.toJson()}');

final typedRoute = typedMachineTimeline.firstWhere(
  (entry) => entry.payload.kind == UnrouterMachineTypedPayloadKind.route,
);
debugPrint('typed route payload=${typedRoute.payload.toJson()}');

final typedController = typedMachineTimeline.firstWhere(
  (entry) => entry.payload.kind == UnrouterMachineTypedPayloadKind.controller,
);
debugPrint('typed controller payload=${typedController.payload.toJson()}');
if (typedController.payload is UnrouterMachineControllerTypedPayload) {
  final payload =
      typedController.payload as UnrouterMachineControllerTypedPayload;
  debugPrint(
    'controller event=${typedController.event.name} '
    'enabled=${payload.enabled} '
    'maxRedirectHops=${payload.maxRedirectHops}',
  );
}

final actionPush = machine.dispatchAction<Future<int?>>(
  UnrouterMachineAction.pushRoute<UserRoute, int>(const UserRoute(id: 7)),
);
final actionSwitched = machine.dispatchAction<bool>(
  UnrouterMachineAction.switchBranch(1),
);
machine.dispatchAction<void>(
  UnrouterMachineAction.replaceRoute(const UserRoute(id: 9)),
);
machine.dispatchAction<void>(
  UnrouterMachineAction.navigateRoute(
    const UserRoute(id: 10),
    mode: UnrouterMachineNavigateMode.replace,
  ),
);
final actionPopped = machine.dispatchAction<bool>(
  UnrouterMachineAction.pop(7),
);
debugPrint('$actionPush $actionSwitched $actionPopped');

final actionEnvelope = machine.dispatchActionEnvelope<Future<int?>>(
  UnrouterMachineAction.pushRoute<UserRoute, int>(const UserRoute(id: 8)),
);
if (actionEnvelope.isDeferred) {
  final value = await actionEnvelope.value;
  debugPrint('action deferred result=$value');
}
if (actionEnvelope.isRejected) {
  final failure = actionEnvelope.failure;
  debugPrint(
    'action rejected code=${failure?.code.name} '
    'category=${failure?.category.name} '
    'reason=${failure?.message}',
  );
}

final snapshot = context.unrouterAs<AppRoute>().state;
debugPrint(
  'resolution=${snapshot.resolution.name} '
  'path=${snapshot.routePath} '
  'action=${snapshot.lastAction.name} '
  'index=${snapshot.historyIndex}',
);

final listenable = context.unrouterAs<AppRoute>().stateListenable;
listenable.addListener(() {
  final next = listenable.value;
  debugPrint('state changed: ${next.resolution.name} ${next.routePath}');
});

final timeline = context.unrouterAs<AppRoute>().stateTimeline;
debugPrint('timeline entries: ${timeline.length}');

final inspector = context.unrouterAs<AppRoute>().inspector;
debugPrint('report: ${inspector.debugReport(timelineTail: 5)}');
debugPrint('machine state: ${inspector.debugMachineState()}');

final filtered = inspector.debugTimeline(
  query: '/users/',
  resolutions: {UnrouterResolutionState.matched},
);
debugPrint('filtered timeline: $filtered');

final machineFiltered = inspector.debugMachineTimeline(
  sources: {UnrouterMachineSource.route},
  events: {UnrouterMachineEvent.commit},
  eventGroups: {UnrouterMachineEventGroup.routeResolution},
  query: '/users/42',
);
debugPrint('filtered machine timeline: $machineFiltered');

final typedMachineFiltered = inspector.debugTypedMachineTimeline(
  events: {UnrouterMachineEvent.actionEnvelope},
  query: '/users/42',
);
debugPrint('typed machine timeline: $typedMachineFiltered');

final exportedJson = inspector.exportDebugReportJson(
  timelineTail: 20,
  machineTimelineTail: 30,
  machineSources: {
    UnrouterMachineSource.route,
    UnrouterMachineSource.navigation,
  },
  machineEvents: {
    UnrouterMachineEvent.commit,
    UnrouterMachineEvent.pushUri,
  },
  machineEventGroups: {UnrouterMachineEventGroup.routeResolution},
  machineQuery: '/users/42',
  query: '/users/',
);
debugPrint('export json: $exportedJson');
```

## Inspector widget

Import `package:unrouter/devtools.dart` for inspector/replay tooling.

```dart
final redirectStore = UnrouterRedirectDiagnosticsStore();

final router = Unrouter<AppRoute>(
  onRedirectDiagnostics: redirectStore.onDiagnostics,
  routes: [...],
);

// Inside any route widget:
UnrouterInspectorWidget<AppRoute>(
  inspector: context.unrouterAs<AppRoute>().inspector,
  redirectDiagnostics: redirectStore,
  timelineTail: 8,
  redirectTrailTail: 4,
  timelineQuery: '/users/',
  onExport: (json) => debugPrint('inspector export: $json'),
);
```

## Inspector bridge (stream/sink)

```dart
final bridge = UnrouterInspectorBridge<AppRoute>(
  inspector: context.unrouterAs<AppRoute>().inspector,
  redirectDiagnostics: redirectStore,
  config: const UnrouterInspectorBridgeConfig(
    timelineTail: 20,
    redirectTrailTail: 10,
    machineTimelineTail: 30,
    machineSources: {UnrouterMachineSource.route},
    machineEvents: {UnrouterMachineEvent.commit},
    machineEventGroups: {UnrouterMachineEventGroup.routeResolution},
    machineQuery: '/users/42',
    query: '/users/',
  ),
  sinks: [
    UnrouterInspectorJsonSink((payload) {
      debugPrint('unrouter-inspector $payload');
    }),
  ],
);

final subscription = bridge.stream.listen((event) {
  debugPrint('reason=${event.reason.name} report=${event.report}');
});
```

## DevTools panel adapter

```dart
final panel = UnrouterInspectorPanelAdapter.fromBridge(
  bridge: bridge,
  config: const UnrouterInspectorPanelAdapterConfig(
    maxEntries: 300,
    autoSelectLatest: true,
  ),
);

ValueListenableBuilder<UnrouterInspectorPanelState>(
  valueListenable: panel,
  builder: (_, state, __) {
    final selected = state.selectedEntry;
    return Text(
      'entries=${state.entries.length}/${state.maxEntries} '
      'selected=${selected?.routePath ?? '-'} '
      'dropped=${state.droppedCount}',
    );
  },
);

panel.selectPrevious();
panel.selectNext();
panel.clear();
```

## DevTools panel widget

```dart
UnrouterInspectorPanelWidget(
  panel: panel,
  query: '/users/',
  reasons: {UnrouterInspectorEmissionReason.stateChanged},
  initialMachineEventGroups: {UnrouterMachineEventGroup.routeResolution},
  initialMachinePayloadKinds: {
    UnrouterMachineTypedPayloadKind.route,
    UnrouterMachineTypedPayloadKind.actionEnvelope,
  },
  onMachineEventGroupsChanged: (groups) {
    bridge.updateMachineEventGroups(groups);
  },
  onMachinePayloadKindsChanged: (kinds) {
    bridge.updateMachinePayloadKinds(kinds);
  },
  onExportSelected: (payload) {
    debugPrint('selected emission json: $payload');
  },
);
```

## Replay store

```dart
final replay = UnrouterInspectorReplayStore.fromBridge(bridge: bridge);

final snapshotJson = replay.exportJson(pretty: true);
replay.clear(resetCounters: true);
replay.importJson(snapshotJson);

await replay.replay(
  step: const Duration(milliseconds: 80),
  fromSequence: 1,
  onEmission: (event) {
    debugPrint("replay ${event.reason.name} ${event.report['uri']}");
  },
);

final compatibility = replay.validateCompatibility();
if (compatibility.hasIssues) {
  debugPrint('replay compatibility issues: ${compatibility.toJson()}');
}
```

## Replay controller + persistence

```dart
final replayController = UnrouterInspectorReplayController(
  store: replay,
  config: const UnrouterInspectorReplayControllerConfig(
    step: Duration(milliseconds: 60),
  ),
);

replayController.scrubTo(10);
replayController.addBookmark(label: 'checkout');
replayController.cycleSpeedPreset();
await replayController.play();
replayController.pause();
replayController.resume();

final storage = UnrouterInspectorReplayMemoryStorageAdapter();
final persistence = UnrouterInspectorReplayPersistence(adapter: storage);
await persistence.save(replay);
await persistence.restore(replay);
```

Replay session comparison (sequence/path):

```dart
final diffBySequence = replay.compareWith(
  baselineReplay,
  mode: UnrouterInspectorReplayCompareMode.sequence,
);
final diffByPath = replay.compareWith(
  baselineReplay,
  mode: UnrouterInspectorReplayCompareMode.path,
);
```

`shared_preferences` and file callback templates are documented in
`docs/replay_persistence_examples.md`.

Panel widget can bind replay controls directly:

```dart
UnrouterInspectorPanelWidget(
  panel: panel,
  replayController: replayController,
  replayDiff: diffBySequence,
  compareRowLimit: 40,
  initialCompareCollapsed: false,
  initialCompareClustersCollapsed: false,
  initialTimelineDiffOnly: false,
  compareBaselineLabel: 'baseline',
  compareCurrentLabel: 'current',
);
```

When `replayDiff` is provided, the panel renders a side-by-side compare table for
baseline/current entries. Tapping a compare row selects and scrubs to that
current session sequence when available. Compare rows can be folded, and
timeline markers can be switched to diff-only mode. Diff rows are clustered
by continuous sequence segments and each cluster can be collapsed independently.
The compare header also shows high-risk cluster stats, with one-click controls
to filter high-risk segments and jump to the next high-risk cluster.
The panel also provides one-click machine event-group filters (`all`,
`lifecycle`, `navigation`, `shell`, `routeResolution`) that narrow visible
entries by `machineTimelineTail.eventGroup`. Use
`onMachineEventGroupsChanged` + `bridge.updateMachineEventGroups(...)` to sync
panel filter selections back to bridge-level data-source filtering.
The panel also supports machine payload-kind quick filters (`all`,
`actionEnvelope`, `navigation`, `route`, `controller`, `generic`) to narrow
entries by typed payload semantics inferred from machine timeline records.
When replay controls are bound, the panel also shows action-envelope
compatibility summary (`issues/errors/warnings`) and a one-click
`replay-issue-next` action to jump cursor/selection to the next issue sequence.
Validation quick filters are available by severity (`error`/`warning`) and
issue code, with selected-issue counts and per-code count breakdown.
Calling `dispatchActionEnvelope(...)` also emits `actionEnvelope` transitions in
machine timeline payloads so inspector/bridge/replay can trace action result
states. Envelope payloads include `schemaVersion`, `eventVersion`, and
`producer` metadata so tools can evolve parsers with backward compatibility.
Rejected envelopes carry a structured `failure` object
(`code`/`message`/`category`/`retryable`/`metadata`) in both envelope JSON and
timeline payload (`actionFailure`), while legacy `rejectCode`/`rejectReason`
remain available for compatibility.
For deferred actions, a follow-up `actionEnvelope` transition is emitted with
`actionEnvelopePhase=settled` when the future completes.
Compatibility checks are available via
`UnrouterMachineActionEnvelope.isSchemaVersionCompatible(...)`,
`UnrouterMachineActionEnvelope.isEventVersionCompatible(...)`, and
`UnrouterInspectorReplayStore.validateCompatibility()`
(`validateActionEnvelopeCompatibility()` remains as a compatibility alias).

## Page and transition customization

```dart
route<UserRoute>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.pathInt('id')),
  transitionDuration: const Duration(milliseconds: 240),
  transitionBuilder: (context, animation, secondary, child) {
    return FadeTransition(opacity: animation, child: child);
  },
  builder: (_, route) => UserPage(route: route),
);

route<ProfileRoute>(
  path: '/profile',
  parse: (_) => const ProfileRoute(),
  pageBuilder: (state) {
    return MaterialPage<void>(
      key: state.key,
      name: state.name,
      child: ProfileShell(child: state.child),
    );
  },
  builder: (_, route) => const ProfilePage(),
);
```

## Guards and redirects

```dart
route<PrivateRoute>(
  path: '/private',
  parse: (_) => const PrivateRoute(),
  guards: [
    (context) async {
      final signedIn = await auth.isSignedIn();
      if (signedIn) {
        return RouteGuardResult.allow();
      }
      return RouteGuardResult.redirect(Uri(path: '/login'));
    },
  ],
  builder: (context, route) => const PrivatePage(),
);

route<LegacyRoute>(
  path: '/legacy',
  parse: (_) => const LegacyRoute(),
  redirect: (_) => Uri(path: '/new-home'),
  builder: (context, route) => const Placeholder(),
);
```

Configure redirect safety limits on the router:

```dart
final router = Unrouter<AppRoute>(
  maxRedirectHops: 8,
  redirectLoopPolicy: RedirectLoopPolicy.error,
  onRedirectDiagnostics: (event) {
    debugPrint(
      'redirect ${event.reason.name} '
      '${event.hop}/${event.maxHops}: '
      '${event.trail.map((uri) => uri.toString()).join(' -> ')}',
    );
  },
  routes: [...],
);
```

## Async loaders

```dart
routeWithLoader<UserRoute, User>(
  path: '/users/:id',
  parse: (state) => UserRoute(id: state.pathInt('id')),
  loader: (context) async {
    final user = await api.fetchUser(context.route.id);
    context.signal.throwIfCancelled();
    return user;
  },
  builder: (context, route, user) => UserPage(user: user),
);
```

Use `Unrouter.loading` to render a global loading widget before first route resolve:

```dart
final router = Unrouter<AppRoute>(
  loading: (_) => const Center(child: CircularProgressIndicator()),
  routes: [...],
);
```

Use `context.signal.isCancelled` or `context.signal.throwIfCancelled()` inside
guards/loaders for cooperative cancellation.

## Shell and branches

```dart
final router = Unrouter<AppRoute>(
  routes: [
    ...shell<AppRoute>(
      branches: [
        branch<AppRoute>(
          initialLocation: Uri(path: '/feed'),
          routes: [
            route<FeedRoute>(
              path: '/feed',
              parse: (_) => const FeedRoute(),
              builder: (_, _) => const FeedPage(),
            ),
            route<PostRoute>(
              path: '/feed/posts/:id',
              parse: (state) => PostRoute(id: state.pathInt('id')),
              builder: (_, route) => PostPage(id: route.id),
            ),
          ],
        ),
        branch<AppRoute>(
          initialLocation: Uri(path: '/settings'),
          routes: [
            route<SettingsRoute>(
              path: '/settings',
              parse: (_) => const SettingsRoute(),
              builder: (_, _) => const SettingsPage(),
            ),
          ],
        ),
      ],
      builder: (context, shell, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.activeBranchIndex,
            onDestinationSelected: (index) => shell.goBranch(index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    ),
  ],
);
```

`shell.goBranch(index)` restores the branch's current stack top.
Use `shell.goBranch(index, initialLocation: true)` to reset the branch to its
configured `initialLocation`.
Use `shell.goBranch(index, completePendingResult: true, result: value)` when
branch switching should also complete the current pending push result.
Use `shell.canPopBranch` / `shell.popBranch()` to pop inside the active branch
stack.
Use `shell.popBranch(result)` to complete the active pushed route with a typed
result.
The same shell semantics are available from machine dispatch via
`UnrouterMachineCommand.switchBranch(...)` and
`UnrouterMachineCommand.popBranch(...)`.
Shell branch stacks are also serialized into `history.state` so recreating the
router from a saved `HistoryLocation` restores per-branch stacks.
State envelope format and compatibility rules are documented in
`docs/state_envelope.md`.

## Parser helpers

`RouteParserState` provides:

- `path`, `pathOrNull`, `pathInt`
- `query`, `queryOrNull`, `queryInt`, `queryIntOrNull`, `queryEnum`
