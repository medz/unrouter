# Unrouter Target Knowledge

This document defines the long-term routing target for `unrouter` and the development rules to keep iteration aligned.

## North Star

The ideal Flutter router is:

- URL-first
- strongly typed
- declarative state-machine driven
- async-native with cancellation
- nested and multi-stack friendly
- web-native and testable

In one line:

- Routing is not only page switching. It is a serializable, testable, composable application state layer.

## Design Principles

1. Single source of truth: URL, route state, and navigation stack must stay consistent.
2. Type safety first: avoid stringly-typed path/query/result flows.
3. Declarative first, imperative parity: state-driven navigation and command APIs should produce the same behavior.
4. Web-native behavior: deep links, refresh, back/forward, and shareable URLs should be predictable.
5. Nested composition: shell/tab/branch stacks should compose naturally.
6. Async as first-class: guard/redirect/loader must support cancellation and deterministic ordering.
7. Predictable back behavior: stack transitions should be explicit and testable.
8. Debuggable internals: route resolution and stack transitions should be observable.
9. Low boilerplate by default: ergonomic API first, codegen optional.
10. Progressive migration: allow coexistence with existing Navigator patterns.

## Current Capability Snapshot

Implemented:

- Generic typed router core: `Unrouter<R extends RouteData>`
- Layered public entrypoints for progressive disclosure:
  `package:unrouter/unrouter.dart` (default core entrypoint),
  `package:unrouter/machine.dart`,
  `package:unrouter/devtools.dart`
- Internal source layout grouped by domain under `lib/src/`:
  `core/`, `runtime/`, `devtools/`, `platform/`
- Typed navigation controller access: `context.unrouterAs<R>()`
- Typed navigation result channel: `push<T>() -> Future<T?>` + `pop(result)`
- Optional replace/go result-completion policy via `completePendingResult`
- Optional shell branch-switch result completion via `goBranch(..., completePendingResult: true)`
- Route-level page and transition customization hooks
- Redirect safety controls via `maxRedirectHops` and `redirectLoopPolicy`
- Redirect diagnostics callback for loop/hop violations
- Route-state introspection via `context.unrouter.state`, `stateListenable`,
  and `stateTimeline`
- Devtools-friendly inspection helper via `context.unrouter.inspector`
- Inspector visualization widget: `UnrouterInspectorWidget`
- Inspector filtering/search/export APIs (`debugTimeline` filters and JSON export)
- Inspector external integration bridge (`UnrouterInspectorBridge`) with stream
  and sink delivery
- DevTools panel adapter model (`UnrouterInspectorPanelAdapter`) fed by bridge
  stream with bounded buffering and entry selection controls
- Built-in DevTools-style panel widget (`UnrouterInspectorPanelWidget`) for
  entry list/detail visualization, machine event-group/payload-kind quick
  filtering, and quick export
- Panel machine event-group filter can sync back to bridge config via
  `onMachineEventGroupsChanged` + `UnrouterInspectorBridge.updateMachineEventGroups`
- Panel machine payload-kind filter can sync back to bridge config via
  `onMachinePayloadKindsChanged` + `UnrouterInspectorBridge.updateMachinePayloadKinds`
- Replay store (`UnrouterInspectorReplayStore`) for emission export/import and
  deterministic playback hooks
- Replay controller (`UnrouterInspectorReplayController`) with speed presets,
  scrub, bookmarks, and pause/resume
- Replay persistence adapters (`UnrouterInspectorReplayPersistence`) with
  schema migration chain support
- Replay session comparator (`UnrouterInspectorReplayComparator`) for sequence-
  and path-based diff analysis
- Panel replay UX with timeline zoom, bookmark-group rendering, side-by-side
  replay compare view, compare folding, diff-only timeline mode, and
  continuous diff clustering
- Panel compare cluster risk summary with one-click high-risk filtering and
  next-segment jump
- Long-lived mixed history restoration stress checkpoints for shell stacks
- Declarative state-machine routing draft documented in
  `docs/state_machine_draft.md`
- Controller navigation APIs now dispatch through an internal event-driven
  navigation machine scaffold
- Resolve/redirect/blocked lifecycle now runs through a controller-managed
  route machine runtime with transition records
- Inspector/bridge/replay debug reports include unified machine state plus
  typed machine transition timeline (`from`/`to` snapshots)
- Machine timeline filtering uses typed source/event schema
  (`UnrouterMachineSource`, `UnrouterMachineEvent`) with query matching
- Public machine command API via `context.unrouterMachineAs<R>()` and
  `UnrouterMachineCommand` + typed `dispatchTyped<T>(...)`
- Public declarative machine action draft API via `UnrouterMachineAction` and
  typed `dispatchAction<T>(...)`
- Action dispatch envelope API via `dispatchActionEnvelope<T>()` with explicit
  `accepted/rejected/deferred/completed` states and structured rejection
  failure payloads (`UnrouterMachineActionFailure`)
- Envelope payload metadata now includes `schemaVersion` + `eventVersion` +
  `producer`; rejected envelopes also include structured `actionFailure`
  mirrors, and deferred envelopes emit follow-up `settled` transitions when
  futures complete
- Machine action-envelope schema/compatibility contract is documented in
  `docs/machine_action_envelope_schema.md` and exposed via runtime compatibility
  helpers (`isSchemaVersionCompatible`, `isEventVersionCompatible`)
- Replay store can validate replay compatibility semantics across captured
  sessions (`validateCompatibility`), including action-envelope schema/event
  checks and controller lifecycle coverage checks
- Unified declarative navigate actions (`navigateUri` / `navigateRoute`) with
  explicit navigate mode (`go` or `replace`)
- Declarative action surface now includes explicit `replaceUri` / `replaceRoute`
  parity with command API
- Delegate route requests now enter runtime via machine command dispatch
  (`routeRequest`) so route and navigation share one command ingress
- Machine command dispatch is now strongly typed end-to-end (command result type
  is encoded on each command)
- Shell machine command surface includes `switchBranch` and `popBranch` with
  deterministic parity coverage
- Machine timeline entries now carry semantic event groups
  (`UnrouterMachineEventGroup`) and inspector filters can query by event group
- Public typed machine transition view is available via `entry.typed`,
  `machine.typedTimeline`, and inspector typed timeline export
  (`debugTypedMachineTimeline`) with typed payload projections for
  action-envelope, controller, navigation, and route-source transitions
- Controller lifecycle transitions now emit explicit machine events
  (`controllerRouteMachineConfigured`,
  `controllerHistoryStateComposerChanged`,
  `controllerShellResolversChanged`,
  `controllerDisposed`) with typed controller payload metadata
- Deterministic machine replay parity test coverage for identical command
  streams
- Deterministic shell/branch command-stream parity coverage
- Performance budget regression coverage for typed machine transition projection
  and replay action-envelope compatibility validation throughput
- Panel replay UX now includes action-envelope compatibility summary and
  next-issue jump control for rapid diagnostics navigation, plus severity/code
  quick filters with selected-issue and per-code counts
- Typed route definitions with parser helpers
- Async hooks: `guards`, `redirect`, `routeWithLoader`
- Cooperative cancellation with `RouteExecutionSignal`
- Shell/branch API with per-branch stacks, branch-local pop, and result
  completion on branch pop
- Shell branch-stack restoration snapshots persisted in `history.state`
- State envelope spec documented in `docs/state_envelope.md`
- API surface inventory and DX scorecard documented in
  `docs/api_surface_review.md`

In progress / next:

- Continue converging command/events surface toward fully declarative
  state-machine event types
- Continue API layering rollout with `unrouter.dart` as core-by-default plus
  explicit opt-in machine/devtools imports; see
  `docs/api_layering_strategy.md`

## Iteration Roadmap

### Phase A: Typed Core and Hook Engine

- Keep route matching, parsing, and hook execution deterministic
- Expand test matrix for async races and cancellation

### Phase B: Nested Multi-Stack Routing

- Stabilize shell/branch stack semantics
- Define branch back policy and restoration behavior

### Phase C: Navigation Ergonomics

- Add ergonomic presets for common transition patterns

### Phase D: Stability and DX

- Add richer inspection tooling on top of route snapshots
- Provide inspection/debug APIs and advanced test helpers

## Definition of Done for Routing Changes

Every routing feature change should include:

1. URL behavior expectations (direct open, refresh, back/forward).
2. Typed API contract and failure behavior.
3. Async/cancellation behavior if any async hook is involved.
4. Nested shell/branch implications if stack behavior changes.
5. Tests covering success path + at least one edge/error path.
6. Documentation updates in `README.md` and this file when the target model evolves.

## How to Use This Doc

- Before implementing a routing feature: map it to one or more principles above.
- During review: reject behavior that violates URL/state/stack consistency.
- After merge: update the capability snapshot and roadmap status.
