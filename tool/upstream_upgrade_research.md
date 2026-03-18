# Upstream Upgrade Research

## Sources

- `~/.pub-cache/hosted/pub.dev/roux-0.5.0/CHANGELOG.md`
- `~/.pub-cache/hosted/pub.dev/roux-0.5.0/README.md`
- `~/.pub-cache/hosted/pub.dev/ht-0.3.0/CHANGELOG.md`
- `~/.pub-cache/hosted/pub.dev/ht-0.3.0/README.md`

## Findings

### `roux 0.5.0`

- `*` now matches exactly one segment.
- Remainder matching now requires `**` or `**:name`.
- `matchAll(...)` returns matches ordered from less specific to more specific.
- Duplicate route retention is configurable; `DuplicatePolicy.append` keeps all
  registrations in insertion order.
- Parameter-name drift is still rejected even when duplicates are appended.

### `ht 0.3.0`

- The package moved to host-backed implementations for fetch-style primitives.
- `URLSearchParams` remains available and still supports the operations used by
  `unrouter`.
- The broad request/response breaking changes do not appear to affect this
  repository directly.

## Implementation Direction

- Update wildcard route patterns in tests and docs from `*` to `**:wildcard`.
- Upgrade `roux` and adopt `DuplicatePolicy.append` for the route matcher.
- Replace manual duplicate-route compatibility checks with a simpler
  route-flattening model that lets the router retain path stacks for lookup.
- Keep alias routing as a separate matcher because route names still need direct
  reverse lookup semantics.
