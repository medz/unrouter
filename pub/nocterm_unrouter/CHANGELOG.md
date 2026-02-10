## 0.1.0

### Added

- Initial Nocterm adapter package for `unrouter`.
- Inherited core `Unrouter` directly and kept adapter runtime thin.
- Added a complete keyboard-first example with shell branches, guards,
  redirects, loaders, and typed navigation flows.
- Added functional runtime tests for scope/controller access, navigation
  behavior, fallback rendering, and lifecycle updates.
- Default runtime error handling that renders a fallback error component when
  `onError` is not provided.
