# Router Benchmarking

This document defines the benchmark baseline used to compare router behavior
and performance for shared navigation semantics.

The benchmark suite now lives in a dedicated project:

- `bench/`

## Goals

- Detect behavioral regressions in `unrouter` by running the same script across
  multiple routers.
- Keep a lightweight performance baseline for navigation operations that are
  semantically shared.
- Make it easy to add new router adapters (for example `zenrouter`).

## Current adapters

The benchmark adapters currently include:

- `unrouter`
- `go_router`
- `zenrouter`

## Behavior scripts

The behavior suite uses only shared semantics:

1. Shared navigation script:
   - `go('/users/1')`
   - `push('/settings')`
   - `pop(7)` and verify push result
   - `go('/users/2')`
   - `push('/settings')`
   - `pop()` and verify nullable push result
2. Redirect script:
   - `go('/legacy/9')` and expect canonical location `/users/9`
3. Guard redirect script:
   - `go('/protected')` and expect redirected location `/login`

Expected location checkpoints (shared semantics only):

- `/` (initial)
- `/users/1` (after `go('/users/1')`)
- `/users/1` (after `pop(7)`)
- `/users/2` (after `go('/users/2')`)
- `/users/2` (after `pop()`)

Expected push results for shared navigation script:

- first pop result: `7`
- second pop result: `null`

## Run

Run from `bench/`:

Behavior parity only:

```bash
cd bench
flutter test --tags behavior
```

Performance baseline only:

```bash
cd bench
flutter test --tags performance
```

You can raise/lower performance rounds with a compile-time define:

```bash
cd bench
flutter test --tags performance --dart-define=UNROUTER_BENCH_ROUNDS=48
```

## Add a new adapter

1. Implement `RouterBenchHarness` in `bench/test/src/router_bench_harness.dart`.
2. Add the adapter to `createHarnesses()`.
3. Ensure the adapter can run the shared script with matching semantics.
4. If the router adds unique semantics, keep those checks in a dedicated test;
   do not pollute the shared differential script.

## Notes

- `push()` immediate location updates are intentionally not asserted in the
  shared script because different routers expose this timing differently.
- CI policy:
  `behavior` runs on push/pull requests in benchmark workflow.
  `performance` runs on schedule/manual dispatch only.
- This baseline favors correctness first. Performance output is informative and
  intended for trend tracking, not strict cross-package winner declarations.
- For richer coverage, add more scripts over time (redirect/guard, nested shell,
  browser-like back-forward, and long-lived restoration).
