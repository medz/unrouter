# Unrouter Workspace

This repository now uses a Dart pub workspace.

## Packages

- `packages/unrouter`: backward-compatible Flutter package facade
- `packages/flutter_unrouter`: Flutter adapter package
- `packages/unrouter_core`: platform-agnostic routing core
- `packages/nocterm_unrouter`: Nocterm adapter package

## Examples

- `examples/flutter_example`: runnable Flutter demo for `flutter_unrouter`
- `examples/nocterm_example`: runnable terminal demo for `nocterm_unrouter`

## Common Commands

```bash
dart pub get
dart pub workspace list
```

Run tests from each package directory:

```bash
cd packages/unrouter && flutter analyze
cd packages/flutter_unrouter && flutter test
cd packages/unrouter_core && dart test
cd packages/nocterm_unrouter && dart test
cd examples/flutter_example && flutter test
cd examples/nocterm_example && dart test
```

The publishable `unrouter` package documentation lives in
[`packages/unrouter/README.md`](packages/unrouter/README.md).
