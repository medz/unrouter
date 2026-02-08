## Unreleased

### Added

- Initial `jaspr_unrouter` adapter skeleton package.
- Added Jaspr component-based route definitions.
- Adapter now reuses core `UnrouterController` directly.
- Added Jaspr `Unrouter` component as the primary runtime binding API.
- Added `CoreUnrouter` alias for pure Dart/controller-only scenarios.
- Added BuildContext navigation helpers (`context.unrouter`,
  `context.unrouterAs<T>()`).
- Added `UnrouterLink` declarative link component and `UnrouterLinkMode`.
- Removed redundant core typedef indirection in route definition API and
  switched to direct core type aliases.
- Removed adapter-local `RouteData` re-export shim file; adapter now references
  core `RouteData` directly.
