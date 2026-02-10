## Unreleased

### Added

- Initial `nocterm_unrouter` adapter package.
- Added Nocterm component-based route definitions.
- Added Nocterm `Unrouter` component as the runtime binding API.
- Added `UnrouterScope` and BuildContext navigation helpers
  (`context.unrouter`, `context.unrouterAs<T>()`).
- Added shell route support by reusing core shell runtime contracts
  (`ShellState`, `ShellRouteRecordHost`, `ShellCoordinator`).

### Changed

- `Unrouter` now extends core `Unrouter` and implements Nocterm
  `StatefulComponent`, removing adapter-local core forwarding state.
- Adapter runtime uses core `UnrouterController` directly.
- Adapter shell assembly reuses core `buildShellRouteRecords` and
  `requireShellRouteRecord`.
