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
