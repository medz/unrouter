# Examples

This workspace keeps runnable demos under `examples/`.

## Flutter

- package: `examples/flutter_example`
- adapter: `flutter_unrouter`
- run:

```bash
cd examples/flutter_example
flutter pub get
flutter run -d chrome
```

## Nocterm

- package: `examples/nocterm_example`
- adapter: `nocterm_unrouter`
- run:

```bash
cd examples/nocterm_example
dart pub get
dart run
```

## Notes

- Each example package keeps its own source, tests, and pubspec.
- The per-example `README.md` files are symlinked to this shared document.
