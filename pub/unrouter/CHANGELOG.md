## Unreleased

### Changed

- Split repository into `pub workspace` packages.
- `unrouter` is now platform-agnostic and depends only on Dart SDK.
- Added pure Dart `UnrouterController` runtime with `go/replace/push/pop/back`
  APIs and redirect handling.
- Added `UnrouterController.cast<S>()` to share one runtime controller across
  typed route views.
- Added `UnrouterHistoryStateComposer` and shell branch resolver APIs
  (`setShellBranchResolvers`, `switchBranch`, `popBranch`) to
  `UnrouterController` so adapter packages no longer need to reimplement
  navigation-side state composition.
- Added `UnrouterController.resolution` to expose the current typed
  `RouteResolution`.
- Added platform-agnostic shell coordination APIs
  (`ShellCoordinator`, state envelope codec, restoration snapshot, branch
  descriptors) for adapter reuse.
- Promoted shell runtime contracts (`ShellState`, `ShellRouteRecordHost`) to
  core API so adapters can share one shell state model.
- Added `ShellRouteRecordBinding` base class so adapter packages can reuse
  shell record forwarding logic instead of duplicating it.
- Added architecture guard tests to keep `unrouter` free from Flutter imports.
- Removed timeline-related runtime APIs (`UnrouterStateTimelineEntry`,
  `stateTimeline`, `clearStateTimeline`, `stateTimelineLimit`).
- Removed Flutter-only runtime APIs from `unrouter`; those APIs moved to
  `flutter_unrouter`.
- Removed legacy state-machine internals and kept only platform-agnostic route
  resolution plus runtime state snapshot types in `unrouter`.
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
