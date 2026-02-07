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
4. Nested navigation script:
   - `go('/workspace/inbox')`
   - `push('/workspace/inbox/details/3')`
   - `pop(11)` and verify push result
   - `go('/workspace/archive')`
   - `push('/workspace/archive/details/5')`
   - `pop()` and verify nullable push result
5. Browser-like back-forward script:
   - `go('/users/1')`
   - `push('/users/2')` then `pop('back')`
   - `push('/users/2')` then `pop('forward')`
6. Long-lived restoration script:
   - Repeats mixed `go/push/pop` rounds and verifies stable checksums/final location

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

Recommended single-command run (behavior + performance + terminal summary):

```bash
cd bench
dart run main.dart
```

By default, benchmark parameters are auto-scaled from local CPU count. You can
override any value explicitly via CLI flags.

Use `--aggressive` to switch to a higher auto-profile tuned for maximum local
stress on capable machines.

Tune rounds/sample size/long-lived rounds:

```bash
cd bench
dart run main.dart \
  --rounds=48 \
  --samples=7 \
  --long-lived-rounds=64
```

Stability-focused performance comparison:

```bash
cd bench
dart run main.dart \
  --performance-only \
  --warmup-rounds=24 \
  --warmup-samples=2 \
  --performance-runs=5 \
  --rounds=48 \
  --samples=7
```

Behavior-only run:

```bash
cd bench
dart run main.dart --behavior-only
```

Performance-only run:

```bash
cd bench
dart run main.dart --performance-only
```

Debug mode (stream raw `flutter test` output):

```bash
cd bench
dart run main.dart --verbose
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
- Browser back/forward APIs are not fully portable across compared routers in
  widget tests. The benchmark uses a shared push/pop script as the parity
  baseline for browser-like round-trips.
- `bench/main.dart` runs both suites and prints a visual terminal summary
  directly, without writing JSON report files.
- For performance stability, use warmup (`--warmup-rounds`, `--warmup-samples`)
  and repeated-run median aggregation (`--performance-runs`).
- Repeated performance runs automatically rotate router execution order
  (`offset = runIndex - 1`) to reduce fixed-order bias from warm caches and
  scheduler state.
- Performance summary is rendered as a compact metric-by-router matrix with
  friendly units (`us`/`ms`/`s`) for terminal readability.
- Performance summary also includes run-indexed mean series per router, so
  cross-run variance can be inspected directly.
- This baseline favors correctness first. Performance output is informative and
  intended for trend tracking, not strict cross-package winner declarations.
- For richer coverage, add more scripts over time (redirect/guard, nested shell,
  browser-like back-forward, and long-lived restoration).
