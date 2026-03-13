# Upstream Upgrade Analysis

## Scope

- Target direct dependencies with unresolved major upgrades:
  - `ht`: `0.2.0` -> `0.3.0`
  - `roux`: `0.2.0` -> `0.5.0`
- Leave `oref` and `unstory` unchanged for this pass because `pub outdated`
  does not report blocked major upgrades for them.

## Current Usage

### `ht`

- Used only through `lib/src/url_search_params.dart`.
- `unrouter` relies on `URLSearchParams` construction, iteration, `get`,
  `append`, `delete`, `clone`, and `toString`.
- The `ht 0.3.0` breaking changes are broad, but the `URLSearchParams` surface
  used here appears intentionally preserved.

### `roux`

- Used only through `roux.Router<T>` creation and `match(...)`.
- `unrouter` currently compensates for older router limitations by:
  - flattening nested routes into a unique `RouteRecord` per full path
  - manually rejecting incompatible duplicate paths
  - manually expanding route-name wildcard params during reverse routing

## Risk Areas

- `roux 0.5.0` changes wildcard semantics:
  - `*` is now single-segment only
  - remainder matching moves to `**` / `**:name`
- Existing docs and tests still describe `/docs/*` as a catch-all path.
- If we upgrade blindly, route matching and reverse routing will diverge.

## Complexity Reduction Opportunity

- `roux 0.5.0` adds `DuplicatePolicy.append` and `matchAll(...)`.
- That should let `unrouter` retain stacked route records directly in the
  matcher instead of maintaining part of the duplicate-path compatibility logic
  itself.
- The first pass should favor reducing custom conflict-resolution code while
  preserving current nested-route behavior.
