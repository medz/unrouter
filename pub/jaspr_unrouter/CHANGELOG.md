## Unreleased

### Added

- Initial `jaspr_unrouter` adapter skeleton package.
- Added Jaspr component-based route definitions.
- Adapter now reuses core `Unrouter` and core `UnrouterController` directly.
- Added `UnrouterRouter` runtime binding driven by core
  `UnrouterController`.
- Added BuildContext navigation helpers (`context.unrouter`,
  `context.unrouterAs<T>()`).
- Added `UnrouterLink` declarative link component and `UnrouterLinkMode`.
