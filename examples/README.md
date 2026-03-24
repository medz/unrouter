# Examples

Runnable apps for exploring Unrouter in real UI environments.

## Flutter Example

[`flutter_example`](flutter_example) shows how to use Unrouter in a Flutter
app with nested layouts, route trees, and a larger demo structure.

```bash
cd examples/flutter_example
flutter run -d chrome
```

## Nocterm Example

[`nocterm_example`](nocterm_example) shows how to use Unrouter in a Nocterm
terminal app with nested routes, named navigation, params, query values, and
back navigation.

```bash
cd examples/nocterm_example
dart run
```

Each example keeps its own source, tests, and `pubspec.yaml`. The per-example
`README.md` files are symlinked to this shared page.
