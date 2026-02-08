## Unreleased

### Added

- Initial `jaspr_unrouter` adapter skeleton package.
- Added Jaspr component-based route definitions.
- Adapter now reuses core `UnrouterController` directly.
- Added Jaspr `Unrouter` component as the primary runtime binding API.
- Added BuildContext navigation helpers (`context.unrouter`,
  `context.unrouterAs<T>()`).
- Added `UnrouterLink` declarative link component and `UnrouterLinkMode`.
- Removed adapter-local shell contract definitions (`ShellState`,
  `ShellRouteRecordHost`) and reused core contracts from `unrouter`.
- Reworked shell route wrapper implementation to directly implement
  `ShellRouteRecordHost` and compose `ShellCoordinator`.
- Reworked `shell()` assembly to reuse core `buildShellRouteRecords`, removing
  adapter-local branch flattening/runtime wiring templates.
- Reworked shell route record casting to reuse core `requireShellRouteRecord`,
  removing adapter-local cast/validation duplication.
- Reworked runtime resolution branching and controller-sync behavior to reuse
  core adapter runtime helpers (`resolveRouteResolution`,
  `syncControllerResolution`, `castRouteRecord`, `castShellRouteRecordHost`).
- Aligned runtime defaults with `flutter_unrouter`: `resolveInitialRoute`
  now defaults to `false`.
- Aligned default error handling with `flutter_unrouter`: when `onError` is
  not provided, errors are rethrown with stack trace.
- Removed redundant adapter typedef indirection in route definition/runtime
  API and switched to direct core type usage.
- Removed adapter-local `RouteData` re-export shim file; adapter now references
  core `RouteData` directly.

### Changed

- Synced to `unrouter` parser helper renames:
  - `RouteParserState` now exposes `params` and `query` (`TypedParams`);
  - removed `RouteParserState.queryParameters`;
  - route parsing now uses typed helpers on `state.params` / `state.query`
    (`required()/decode()/$int()/$double()/$enum()`).
- Synced shell API slimming from `unrouter`:
  - removed `name` parameters from adapter `branch()` / `shell()`;
  - shell-wrapped route records now keep route-level `name` values directly
    (no shell-name prefixing).
- Simplified route-record contracts:
  - adapter `RouteRecord` now extends core `RouteRecord` and only adds
    Jaspr rendering methods;
  - shell wrapper records now extend adapter `RouteRecord` instead of
    re-declaring core route semantics.
