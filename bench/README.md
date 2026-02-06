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

Tune rounds:

```bash
flutter test --tags performance --dart-define=UNROUTER_BENCH_ROUNDS=48
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
  --long-lived-rounds=64
```
