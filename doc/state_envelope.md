# State envelope (removed)

Historical shell `history.state` envelope APIs have been removed from the
current runtime design.

Current shell runtime only keeps branch stack coordination in core:

- `ShellCoordinator`
- `ShellRouteRecordHost`
- `ShellState`

Adapters no longer expose envelope composer/restoration extension points.
