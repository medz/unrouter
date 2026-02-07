## Unreleased

### Changed

- Split repository into `pub workspace` packages.
- `unrouter` is now platform-agnostic and depends only on Dart SDK.
- Removed Flutter-only runtime APIs from `unrouter`; those APIs moved to
  `flutter_unrouter`.
- Added `unrouter_machine` dependency for machine-kernel abstractions.
- Replaced Flutter example and tests with pure Dart equivalents.

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
