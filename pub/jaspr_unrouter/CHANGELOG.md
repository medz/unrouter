## Unreleased

### Added

- Initial `jaspr_unrouter` adapter skeleton package.
- Added Jaspr component-based route definitions and a thin `Unrouter` adapter
  wrapper over core `unrouter`.
- Added `UnrouterRouter` runtime binding over `jaspr_router`.
- Added BuildContext navigation helpers (`context.unrouter`,
  `context.unrouterAs<T>()`).
