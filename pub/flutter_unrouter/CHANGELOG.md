## Unreleased

### Added

- Initial Flutter adapter package split from `unrouter`.
- Preserved Flutter-first API naming and behavior (`Unrouter`, `route`,
  `context.unrouter`, shell navigation).
- Added package-local Flutter example and widget test suite.
- Removed state-machine-oriented public API surface and kept controller API
  focused on runtime navigation/state.
- Removed timeline-related runtime APIs (`stateTimeline`,
  `clearStateTimeline`, `stateTimelineLimit`).
- Reworked `UnrouterController` to directly reuse the `unrouter` core runtime
  controller with Flutter listenable extension, removing adapter runtime
  wrapper duplication.
- Added `blocked` fallback builder on `Unrouter` to align fallback API naming
  with `jaspr_unrouter`.
- Removed adapter-local `RouteData` re-export shim file and referenced core
  `RouteData` directly across runtime/core modules.
- Reworked route definition records to inherit core `RouteDefinition` /
  `LoadedRouteDefinition` so parse/guard/redirect/loader semantics stay owned
  by `unrouter`.
- Reworked shell restoration/branch stack runtime to use `unrouter` core
  `ShellCoordinator`, removing duplicated envelope/stack algorithms.
- Removed adapter-local shell contract definitions (`ShellState`,
  `ShellRouteRecordHost`) and reused core contracts from `unrouter`.
- Reworked shell route wrapper implementation to extend core
  `ShellRouteRecordBinding`, reducing adapter-side forwarding duplication.
- Reworked `shell()` assembly to reuse core `buildShellRouteRecords`, removing
  adapter-local branch flattening/runtime wiring templates.
- Reworked shell route record casting to reuse core `requireShellRouteRecord`,
  removing adapter-local cast/validation duplication.
- Reworked runtime delegate resolution branching and controller-sync behavior to
  reuse core adapter runtime helpers (`resolveRouteResolution`,
  `syncControllerResolution`, `castRouteRecord`, `castShellRouteRecordHost`).
- Aligned pending-state builder signature with `jaspr_unrouter` by changing
  `loading` to `Widget Function(BuildContext context, Uri uri)`.
- Aligned blocked fallback flow with `jaspr_unrouter`: when `blocked` is not
  provided, runtime now falls back to `unknown` before default page.
- Removed adapter alias typedef wrappers and direct shim accessors
  (`RouteRecord.core`, `CoreUnrouter`, `typedef UnrouterController = ...`) so
  adapter internals use core types directly.
- Added shell runtime widget tests for branch switching/restoration and
  `popBranch` pending-result completion.

### Changed

- Synced to `unrouter` parser helper renames:
  - `RouteParserState` now exposes `params` and `query` (`TypedParams`);
  - removed `RouteParserState.queryParameters`;
  - route parsing now uses typed helpers on `state.params` / `state.query`
    (`required()/decode()/$int()/$double()/$enum()`).
