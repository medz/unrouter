# Bench

Differential router benchmark suite for `unrouter`, `go_router`, and `zenrouter`.

## Run

Run the full benchmark (behavior + performance) and print a terminal summary:

```bash
dart run main.dart
```

Tune rounds, samples, and long-lived behavior rounds:

```bash
dart run main.dart \
  --rounds=48 \
  --samples=7 \
  --long-lived-rounds=64
```

Stability-focused performance run (warmup + repeated suite aggregation):

```bash
dart run main.dart \
  --performance-only \
  --warmup-rounds=24 \
  --warmup-samples=2 \
  --performance-runs=5 \
  --rounds=48 \
  --samples=7
```

Performance output now uses a compact metric-by-router matrix with friendly
time units (`us`/`ms`/`s`) to keep common terminal widths readable.

Run only behavior parity:

```bash
dart run main.dart --behavior-only
```

Run only performance baseline:

```bash
dart run main.dart --performance-only
```

Show raw `flutter test` output while running:

```bash
dart run main.dart --verbose
```

You can still run raw suites directly if needed:

```bash
flutter test --tags behavior
flutter test --tags performance
```
