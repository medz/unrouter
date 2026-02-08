# unrouter workspace

This repository is a `pub workspace` with three packages:

- `pub/unrouter`: platform-agnostic router core (Dart SDK only)
- `pub/flutter_unrouter`: Flutter adapter package
- `pub/jaspr_unrouter`: Jaspr adapter package

## Workspace commands

```bash
dart pub workspace list
dart pub get
```

## Package checks

```bash
(cd pub/unrouter && dart test)
flutter test pub/flutter_unrouter/test
(cd pub/jaspr_unrouter && dart test)
```
