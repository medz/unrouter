# Unrouter History State Envelope

This document defines the `history.state` envelope used by `unrouter` shell restoration.

## Scope

- This envelope is written when shell routing is active and navigation happens through `UnrouterController` APIs.
- It stores shell branch-stack restoration metadata while preserving user-provided `state`.

## Encoded Shape

Envelope keys:

- `__unrouter_meta__`: unrouter metadata map.
- `__unrouter_state__`: user state payload (may be `null`).

Metadata map keys:

- `v`: envelope version number.
- `shell`: shell restoration snapshot.

Current version:

- `v = 1`

Shell snapshot shape:

- `activeBranchIndex`: active shell branch index when encoded.
- `stacks`: list of branch stack entries.

Each branch stack entry:

- `branchIndex`: branch index.
- `index`: current selected entry index in the branch stack.
- `entries`: URI string list for the branch history.

## Example

```json
{
  "__unrouter_meta__": {
    "v": 1,
    "shell": {
      "activeBranchIndex": 1,
      "stacks": [
        {
          "branchIndex": 0,
          "index": 2,
          "entries": ["/a", "/a/detail", "/a/edit"]
        },
        {
          "branchIndex": 1,
          "index": 1,
          "entries": ["/b", "/b/detail"]
        }
      ]
    }
  },
  "__unrouter_state__": {
    "scrollTop": 240
  }
}
```

## Merge Rules

When composing new history state:

1. If a new `state` argument is provided, that value becomes `__unrouter_state__`.
2. If no new `state` argument is provided, existing `__unrouter_state__` is carried forward.
3. Shell snapshot metadata is refreshed from current shell runtime plus the target navigation URI/action.
4. If shell metadata is unavailable, raw user state is preserved as-is.

## Restoration Rules

1. On shell route build, `unrouter` attempts to parse this envelope from `history.state`.
2. If parse succeeds and `v` is supported, shell stacks are restored.
3. Branch indices outside current shell bounds are ignored.
4. Invalid or malformed stack entries are ignored.
5. If parse fails, routing continues without restoration fallback errors.

## Compatibility Strategy

- Envelope parsing is version-gated by `v`.
- Unknown versions are ignored (treated as non-envelope state).
- Older apps can continue using plain user state with no migration step.
- Future schema changes should bump `v` and keep old parsers tolerant.

## Stability Note

- The key names and shape above are currently intended for internal restoration behavior and debugging visibility.
- If you persist history snapshots externally, prefer tolerant parsing and avoid strict assumptions beyond `v`.
