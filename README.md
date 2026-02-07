# unrouter workspace

This repository is a `pub workspace` with two packages:

- `pub/unrouter`: platform-agnostic router core (Dart SDK only)
- `pub/flutter_unrouter`: Flutter adapter package

## Workspace commands

```bash
dart pub workspace list
dart pub get
```

## Package checks

```bash
(cd pub/unrouter && dart test)
flutter test pub/flutter_unrouter/test
```
