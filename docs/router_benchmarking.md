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

You can raise/lower performance rounds and sample size with compile-time
defines:

```bash
cd bench
flutter test --tags performance \
  --dart-define=UNROUTER_BENCH_ROUNDS=48 \
  --dart-define=UNROUTER_BENCH_SAMPLES=7
```

Generate a structured benchmark report JSON:

```bash
cd bench
dart run tool/generate_report.dart
```

Generate a report with regression alerting against a baseline report (default
threshold `+15%`, alert-only):

```bash
cd bench
dart run tool/generate_report.dart \
  --output=results/current.json \
  --baseline=results/baseline.json
```

Fail-fast mode for local gates:

```bash
cd bench
dart run tool/generate_report.dart \
  --output=results/current.json \
  --baseline=results/baseline.json \
  --threshold-percent=10 \
  --fail-on-regression
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
- Structured report output is written under `bench/results/` and includes
  machine/environment metadata, multi-sample performance summaries
  (`min/mean/p50/p95/max`), and optional regression check results.
- This baseline favors correctness first. Performance output is informative and
  intended for trend tracking, not strict cross-package winner declarations.
- For richer coverage, add more scripts over time (redirect/guard, nested shell,
  browser-like back-forward, and long-lived restoration).
