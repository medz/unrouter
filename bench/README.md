# Bench

Differential router benchmark suite for `unrouter`, `go_router`, and `zenrouter`.

## Run

Behavior parity:

```bash
flutter test --tags behavior
```

Performance baseline:

```bash
flutter test --tags performance
```

Tune rounds and sample count:

```bash
flutter test --tags performance \
  --dart-define=UNROUTER_BENCH_ROUNDS=48 \
  --dart-define=UNROUTER_BENCH_SAMPLES=7
```

Generate a structured JSON report:

```bash
dart run tool/generate_report.dart
```

Custom report output and rounds:

```bash
dart run tool/generate_report.dart \
  --output=results/manual_report.json \
  --rounds=48 \
  --samples=7 \
  --long-lived-rounds=64
```

Regression alert against a baseline report (`+15%` default threshold):

```bash
dart run tool/generate_report.dart \
  --output=results/current.json \
  --baseline=results/baseline.json
```

Tighten threshold or fail on regression:

```bash
dart run tool/generate_report.dart \
  --output=results/current.json \
  --baseline=results/baseline.json \
  --threshold-percent=10 \
  --fail-on-regression
```
