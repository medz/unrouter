## Unreleased

### Added

- Initial Flutter adapter package split from `unrouter`.
- Preserved Flutter-first API naming and behavior (`Unrouter`, `route`,
  `context.unrouter`, shell navigation).
- Added package-local Flutter example and widget test suite.
- Removed state-machine-oriented public API surface and kept controller API
  focused on runtime navigation/state.
- Removed timeline-related runtime APIs (`stateTimeline`,
  `clearStateTimeline`, `stateTimelineLimit`).
- Reworked `UnrouterController` to wrap the `unrouter` core runtime controller
  so route resolution/navigation behavior is shared instead of duplicated.
- Reworked shell restoration/branch stack runtime to use `unrouter` core
  `ShellCoordinator`, removing duplicated envelope/stack algorithms.
