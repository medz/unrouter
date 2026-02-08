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
