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
  controller via type alias + Flutter listenable extension, removing adapter
  runtime wrapper duplication.
- Exposed `CoreUnrouter` alias for pure Dart/core router scenarios and aligned
  `Unrouter.resolve` to optional `signal` parameter (default
  `RouteNeverCancelledSignal`) for adapter parity.
- Added `blocked` fallback builder on `Unrouter` to align fallback API naming
  with `jaspr_unrouter`.
- Removed adapter-local `RouteData` re-export shim file and referenced core
  `RouteData` directly across runtime/core modules.
- Reworked route definition records to inherit core `RouteDefinition` /
  `LoadedRouteDefinition` so parse/guard/redirect/loader semantics stay owned
  by `unrouter`.
- Reworked shell restoration/branch stack runtime to use `unrouter` core
  `ShellCoordinator`, removing duplicated envelope/stack algorithms.
- Added shell runtime widget tests for branch switching/restoration and
  `popBranch` pending-result completion.
