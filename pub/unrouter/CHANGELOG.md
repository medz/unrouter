## 0.10.0

### Changed

- Rebuilt the core runtime around a slimmer `UnrouterController` API focused on
  `go/goUri`, `push/pushUri`, `pop/back`, and shell branch operations.
- Removed machine-oriented and timeline-oriented runtime surfaces from the core
  package to keep `unrouter` platform-agnostic and composable.
- Reworked route parsing state to `RouteState` with typed `params`/`query`
  helpers (`required`, `decode`, `$int`, `$double`, `$enum`).
- Simplified shell APIs and internals by removing envelope/binding layers and
  consolidating on shared shell coordinator contracts.
- Aligned route record naming and structure (`route`, `dataRoute`,
  `RouteRecord`, `DataRouteRecord`) for cleaner adapter integration.
- Added a complete pure Dart example and replaced boundary-style checks with
  behavior-focused runtime tests.

### Fixed

- Improved shell branch stack restoration and route resolution consistency after
  runtime refactors.

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
