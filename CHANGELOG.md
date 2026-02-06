## Unreleased

### Changed

- Removed `package:unrouter/devtools.dart` and all built-in inspector/replay
  implementations to keep the package focused on core routing and machine APIs.
- Simplified docs, tests, and example app to match the slimmer public surface.
- Simplified machine API to command-first dispatch by removing declarative
  action/envelope layers and related schema contracts.

## 0.8.0

### Added

- Core typed router API with `Unrouter<R extends RouteData>`, `route<T>()`,
  and `RouteParserState`.
- Async routing hooks: `guards`, `redirect`, `routeWithLoader`, and cooperative
  cancellation with `RouteExecutionSignal`.
- Shell routing primitives (`shell()` / `branch()`) with branch-local stacks and
  browser-history restoration.
- Typed navigation results via `push<T>()` + `pop(result)`, including
  `completePendingResult` options for replace/branch-switch flows.
- Public machine API (`package:unrouter/machine.dart`) with typed commands,
  actions, and action envelopes.
- Public devtools API (`package:unrouter/devtools.dart`) with inspector,
  bridge, panel adapter/widget, replay, persistence, and replay diff tooling.
- Differential benchmark project under `bench/`, including
  `unrouter`/`go_router`/`zenrouter` parity checks and performance comparison.

### Changed

- `package:unrouter/unrouter.dart` is the core default entrypoint.
- Advanced APIs now require explicit imports:
  `package:unrouter/machine.dart` and `package:unrouter/devtools.dart`.
- Package moved to repository root and example app rebuilt around real
  typed-routing, shell, redirect/guard/loader, and `/debug` workflows.
- Benchmark workflow consolidated into `bench/main.dart` with environment-aware
  defaults, warmup controls, repeated performance runs, and terminal summary.
- Internal source layout reorganized into domain folders:
  `lib/src/core`, `lib/src/runtime`, `lib/src/devtools`, `lib/src/platform`.

### Fixed

- Redirect loop / max-hop diagnostics and safety handling.
- Shell branch-stack restoration correctness across router recreation and
  back/forward traversal.
- Deterministic machine/replay parity coverage for command/action streams and
  compatibility validation.
