# Unrouter Declarative State-Machine Draft

This draft defines a target model for evolving `unrouter` toward a fully declarative routing state machine while preserving compatibility with today's typed API.

## Objective

Move from "imperative commands that mutate navigation" to "events reduced by a deterministic state machine", where URL, route state, and stack state are outputs of a single transition function.

## Current checkpoint

- `UnrouterController` command APIs are dispatched through an internal navigation dispatch adapter.
- The adapter is backed by an event-driven navigation machine scaffold that executes command events and records transition snapshots.
- Route resolution flow now runs through a controller-managed internal route machine runtime that records resolve/redirect/blocked/commit transitions.
- Machine transition records now use typed source/event schema (`UnrouterMachineSource` / `UnrouterMachineEvent`) and unified `from`/`to` `UnrouterMachineState` snapshots.
- Inspector bridge reports now carry machine transition tails with typed filtering and include current unified machine state.
- Route and navigation transition recording now converges into a shared reducer pipeline (`_UnrouterMachineReducer`) as the single transition write path.
- Delegate route requests now dispatch through machine command ingress (`routeRequest`) before resolve execution.
- Public dispatch surface is available via strongly typed `UnrouterMachineCommand`, `context.unrouterMachineAs<R>()`, and typed `dispatchTyped<T>()`.
- Declarative action draft surface is available via `UnrouterMachineAction` and `dispatchAction<T>()`, mapped onto the same typed command runtime.
- Action dispatch envelope (`dispatchActionEnvelope<T>()`) now exposes explicit result states (`accepted`, `rejected`, `deferred`, `completed`) for richer declarative handling.
- Envelope rejections now expose structured failure descriptors (`code`/`message`/`category`/`retryable`/`metadata`), while legacy reject fields remain for compatibility.
- Envelope payloads now carry `schemaVersion`/`eventVersion`/`producer` metadata with runtime compatibility helpers; deferred envelopes append a follow-up `settled` transition when async results resolve.
- Replay store now includes replay compatibility validation for captured machine
  timelines (action-envelope schema/event checks + controller lifecycle
  coverage checks).
- Machine transition entries now expose a typed public event view
  (`UnrouterMachineTypedTransition`) with typed action-envelope payload parsing
  (`UnrouterMachineActionEnvelopeTypedPayload`).
- Typed transition payload projection now also covers controller-source,
  navigation-source, and route-source machine transitions.
- Controller runtime configuration/lifecycle transitions now surface explicit
  lifecycle events (`controllerRouteMachineConfigured`,
  `controllerHistoryStateComposerChanged`,
  `controllerShellResolversChanged`,
  `controllerDisposed`) for inspector/replay observability.
- Declarative action shape now includes explicit `replaceUri` / `replaceRoute` helpers for command-surface parity.
- Declarative navigation now has a unified shape: `navigateUri` / `navigateRoute` with a `mode` (`go` or `replace`) to reduce command-style branching at call sites.
- Shell semantics now have machine commands (`switchBranch` / `popBranch`) with deterministic command-stream parity coverage.
- Machine transition records now include semantic event groups (`UnrouterMachineEventGroup`) and inspector filters can scope by group.
- Deterministic replay parity test validates identical command streams yield identical transition streams.
- Performance budget regression tests guard typed transition projection and replay compatibility validation throughput.

## Core Model

### Router graph

- `RouteNode`: typed route definition with parser, matcher, and optional async hooks.
- `ShellNode`: branch container with independent per-branch stack memory.
- `Graph`: immutable route graph compiled from `route()` / `shell()` definitions.

### Runtime state

- `RouterMachineState`:
  - `location`: current URI.
  - `resolution`: matched/redirect/blocked/error metadata.
  - `shell`: active branch and branch stacks.
  - `pending`: in-flight transition metadata (if any).
  - `history`: last action/index metadata for web parity.

### Events

- `NavigateToUri(uri, replace|push)`
- `NavigateToRoute(route, replace|push)`
- `Pop(result?)`
- `Go(delta)`
- `BranchSwitch(index, initialLocation?)`
- `RestoreFromHistoryState(state)`
- `TransitionCompleted(token, outcome)`
- `TransitionCancelled(token)`

## Transition Pipeline

Each event is reduced through one deterministic pipeline:

1. Parse intent into candidate location.
2. Match route graph.
3. Execute async hooks in strict order: `redirect -> guards -> loader`.
4. Produce a transition outcome:
   - `commit(location, pageState, historyState)`
   - `redirect(newLocation)`
   - `blocked`
   - `error`
5. Emit observable transition record for inspector/replay.

Cancellation is cooperative and token-based. A newer transition invalidates older pending tokens.

## Declarative Surface (Draft API Shape)

```dart
final machine = context.unrouterMachineAs<AppRoute>();

machine.dispatchAction<void>(
  UnrouterMachineAction.navigateToRoute(const UserRoute(id: 42)),
);
machine.dispatchAction<void>(
  UnrouterMachineAction.replaceRoute(const UserRoute(id: 43)),
);
machine.dispatchAction<bool>(UnrouterMachineAction.switchBranch(1));
machine.dispatchAction<bool>(UnrouterMachineAction.pop());

final envelope = machine.dispatchActionEnvelope<Future<int?>>(
  UnrouterMachineAction.pushRoute<UserRoute, int>(const UserRoute(id: 42)),
);
if (envelope.isDeferred) {
  final result = await envelope.value;
  debugPrint('push completed with $result');
}

final snapshot = machine.state; // UnrouterMachineState
final timeline = machine.timeline; // deterministic transition records
```

## Compatibility Mapping

The current controller API can be treated as event helpers:

- `go(route)` -> `NavigateToRoute(route, replace: true)`
- `replace(route)` -> `NavigateToRoute(route, replace: true)`
- `push(route)` -> `NavigateToRoute(route, push: true)`
- `back()` / `forward()` -> `Go(-1)` / `Go(+1)`
- `shell.goBranch(i)` -> `BranchSwitch(i)`
- `shell.popBranch()` -> `Pop()` in active branch context

This keeps migration incremental: existing apps can use today's API while runtime internals converge on event reduction.

## Integration Requirements

- History state envelope remains the persistence boundary for shell stacks.
- Inspector/replay must consume transition records directly from machine output.
- Typed route data remains mandatory at graph boundaries.
- Unknown/error routes remain explicit machine outcomes.

## Milestones

1. Establish machine state/event data structures as internal model.
2. Route existing controller methods through machine dispatch.
3. Switch resolver/hook execution to tokenized transition jobs.
4. Unify inspector timeline with machine transition records.
5. Expose optional advanced declarative API on top of stable runtime.
