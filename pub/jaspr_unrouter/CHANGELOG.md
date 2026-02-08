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
- Reworked shell route wrapper implementation to extend core
  `ShellRouteRecordBinding`, reducing adapter-side forwarding duplication.
- Reworked `shell()` assembly to reuse core `buildShellRouteRecords`, removing
  adapter-local branch flattening/runtime wiring templates.
- Removed redundant adapter typedef indirection in route definition/runtime
  API and switched to direct core type usage.
- Removed adapter-local `RouteData` re-export shim file; adapter now references
  core `RouteData` directly.
