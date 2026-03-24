<p align="center">
  <img src="assets/brand.svg" width="120" alt="unrouter" />
</p>

<p align="center">
  <strong>Facade package for Unrouter core and platform adapters.</strong>
</p>

<p align="center">
  <a href="https://github.com/medz/unrouter/actions/workflows/test.yml"><img src="https://github.com/medz/unrouter/actions/workflows/test.yml/badge.svg" alt="Test"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/dart-%3E%3D3.10.0-0175C2?logo=dart&logoColor=white" alt="dart"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/flutter-stable-02569B?logo=flutter&logoColor=white" alt="flutter"></a>
  <a href="https://pub.dev/packages/unrouter"><img src="https://img.shields.io/pub/v/unrouter.svg" alt="pub"></a>
  <a href="../../LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license"></a>
</p>

---

## Features

- Re-exported `flutter_unrouter` entrypoint
- Re-exported `nocterm_unrouter` entrypoint
- Re-exported `unrouter_core` entrypoint
- Legacy `package:unrouter/unrouter.dart` support for existing Flutter users

## Install

```yaml
dependencies:
  unrouter: <latest>
```

```bash
dart pub add unrouter
```

## Entrypoints

```dart
import 'package:unrouter/flutter.dart';
import 'package:unrouter/nocterm.dart';
import 'package:unrouter/core.dart';
```

- `package:unrouter/unrouter.dart`: legacy Flutter-compatible export
- `package:unrouter/flutter.dart`: Flutter adapter proxy
- `package:unrouter/nocterm.dart`: Nocterm adapter proxy
- `package:unrouter/core.dart`: platform-agnostic routing core proxy

If you import more than one adapter library in the same file, use prefixes to
avoid symbol collisions such as `Inlet`, `Outlet`, and `createRouter`.

## Example

The runnable Flutter example lives in the repository at
[`examples/flutter_example/`](../../examples/flutter_example).

```bash
cd examples/flutter_example
flutter pub get
flutter run -d chrome
```

The runnable Nocterm example lives at
[`examples/nocterm_example/`](../../examples/nocterm_example).

```bash
cd examples/nocterm_example
dart pub get
dart run
```
