## Unreleased

### Added

- Initial `jaspr_unrouter` adapter skeleton package.
- Added Jaspr component-based route definitions and a thin `Unrouter` adapter
  wrapper over core `unrouter`.
- Added `UnrouterRouter` runtime binding driven by core
  `UnrouterController`.
- Added BuildContext navigation helpers (`context.unrouter`,
  `context.unrouterAs<T>()`).
- Added `router.createController()` for pure-Dart runtime usage.
