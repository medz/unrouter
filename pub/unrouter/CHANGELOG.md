## Unreleased

### Changed

- Split repository into `pub workspace` packages.
- `unrouter` is now platform-agnostic and depends only on Dart SDK.
- Added pure Dart `UnrouterController` runtime with `go/push/pop/back` APIs
  and redirect handling.
- Added `UnrouterController.cast<S>()` to share one runtime controller across
  typed route views.
- `UnrouterController` no longer exposes history composer and shell resolver
  injection APIs. Shell branch switching is resolved directly from the active
  shell record (`ShellRouteRecordHost`), keeping the core runtime API smaller.
- `UnrouterController` navigation API is further reduced by removing duplicated
  or low-value commands (`replace`, `replaceUri`, `popToUri`, `forward`,
  `goDelta`). Core runtime now keeps `go/goUri`, `push/pushUri`, `pop/back`,
  and shell branch actions.
- Renamed controller sync entrypoint from `dispatchRouteRequest` to `sync`.
- `StateSnapshot` now includes `historyState`, and shell adapters consume
  navigation metadata from snapshot values instead of separate controller
  getters.
- Added `UnrouterController.resolution` to expose the current typed
  `RouteResolution`.
- Added platform-agnostic shell coordination runtime for adapter reuse.
- Promoted shell runtime contracts (`ShellState`, `ShellRouteRecordHost`) to
  core API so adapters can share one shell state model.
- Added `buildShellRouteRecords` helper so adapters can reuse branch flattening
  and shell runtime wiring with only adapter-specific wrapping logic.
- Added `requireShellRouteRecord` helper so adapters can share shell record cast
  validation/error handling instead of duplicating it.
- Route records now expose a unified loader hook (`runLoader`), so shell
  wrappers can forward loader execution without depending on concrete route
  definition types.
- Fixed route resolution for shell-wrapped data routes: loader data is now
  produced correctly instead of being dropped as `null`.
- Added adapter runtime helpers (`resolveRouteResolution`,
  `syncControllerResolution`, `castRouteRecord`, `castShellRouteRecordHost`)
  so platform packages can share resolution dispatch and runtime synchronization.
- Added architecture guard tests to keep `unrouter` free from Flutter imports.
- Simplified shell runtime APIs:
  - removed `name` from core `ShellBranch` / `branch()` and removed shell-name
    prefixing in `buildShellRouteRecords`;
  - `ShellState` now exposes method-based actions (`goBranch`, `popBranch`,
    `canPopBranch`) instead of raw callback fields;
  - `ShellRouteRecordHost.popBranch()` no longer accepts an unused `result`
    parameter.
- Removed shell history-state envelope/restoration APIs and kept only
  branch-stack coordination in `ShellCoordinator`.
- Removed `ShellRuntimeBinding`; shell wrappers now share one
  `ShellCoordinator` directly.
- Removed `ShellRouteRecordBinding`; adapters now implement
  `ShellRouteRecordHost` directly and compose `ShellCoordinator`.
- Simplified route parser API by introducing typed param views:
  - parser state now uses `RouteState` with `params` and `query`
    (`TypedParams`);
  - raw query access now goes through `RouteState.location.uri.queryParameters`;
  - use `required()/decode()/$int()/$double()/$enum()` helpers on
    `state.params` / `state.query`.
- Removed timeline-related runtime APIs (`UnrouterStateTimelineEntry`,
  `stateTimeline`, `clearStateTimeline`, `stateTimelineLimit`).
- Removed Flutter-only runtime APIs from `unrouter`; those APIs moved to
  `flutter_unrouter`.
- Removed legacy state-machine internals and kept only platform-agnostic route
  resolution plus runtime state snapshot types in `unrouter`.
- Replaced Flutter example and tests with pure Dart equivalents.
- Expanded core pure Dart example into a full end-to-end scenario covering
  typed params/query parsing, redirect/guard/block flows, loader routes,
  controller navigation, state stream observation, and redirect diagnostics.

## 0.9.0

### Changed

- Removed `package:unrouter/devtools.dart` and all built-in inspector/replay
  implementations to keep the package focused on core routing and machine APIs.
- Simplified docs, tests, and example app to match the slimmer public surface.
- Simplified machine API to command-first dispatch by removing declarative
  action/envelope layers and related schema contracts.
- Tightened machine/controller public surface: merged dispatch entrypoint into
  `machine.dispatch<T>()`, removed `typedTimeline`, removed public
  `routeRequest` command, and stopped exporting controller lifecycle/composer
  APIs from `package:unrouter/unrouter.dart`.
