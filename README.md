# Unrouter Workspace

This repository now uses a Dart pub workspace.

## Packages

- `packages/unrouter`: backward-compatible Flutter package facade
- `packages/flutter_unrouter`: Flutter adapter package
- `packages/unrouter_core`: platform-agnostic routing core
- `packages/nocterm_unrouter`: Nocterm adapter package

## Common Commands

```bash
dart pub workspace list
dart pub get
```

Run tests from each package directory:

```bash
cd packages/unrouter && flutter test
cd packages/flutter_unrouter && flutter test
cd packages/unrouter_core && dart test
cd packages/nocterm_unrouter && dart test
```

The publishable `unrouter` package documentation lives in
[`packages/unrouter/README.md`](packages/unrouter/README.md).
