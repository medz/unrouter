<p align="center">
  <img src="../../assets/brand.svg" width="120" alt="unrouter" />
</p>

<p align="center">
  <strong>Declarative routing toolkit for Flutter and Nocterm.</strong>
</p>

<p align="center">
  <a href="https://github.com/medz/unrouter/actions/workflows/ci.yml"><img src="https://github.com/medz/unrouter/actions/workflows/ci.yml/badge.svg" alt="Test"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/dart-%3E%3D3.10.0-0175C2?logo=dart&logoColor=white" alt="dart"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/flutter-stable-02569B?logo=flutter&logoColor=white" alt="flutter"></a>
  <a href="https://pub.dev/packages/unrouter"><img src="https://img.shields.io/pub/v/unrouter.svg" alt="pub"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license"></a>
</p>

`unrouter` is the primary package for the Unrouter family. It gives you one
dependency with Flutter and Nocterm entrypoints, plus shared core and history
APIs from the package root.

Start here if you want one package for Flutter, Nocterm, and the shared routing
building blocks.

## What You Get

- Declarative route trees
- Shared routing and history APIs from `package:unrouter/unrouter.dart`
- Named navigation, params, and query helpers
- Guards and redirects
- Nested route rendering
- Flutter and Nocterm entrypoints from one package
- A stable brand-level import path for app code

## Install

```yaml
dependencies:
  unrouter: <latest>
```

```bash
dart pub add unrouter
```

## Flutter Entry Point

```dart
import 'package:unrouter/flutter.dart';
```

Use this in Flutter apps.

## Other Entrypoints

```dart
import 'package:unrouter/nocterm.dart';
import 'package:unrouter/unrouter.dart';
```

- `package:unrouter/flutter.dart`
  Flutter routing APIs.
- `package:unrouter/nocterm.dart`
  Nocterm routing APIs, including history exports.
- `package:unrouter/unrouter.dart`
  Shared core and history APIs.

If you import more than one adapter library in the same file, use prefixes to
avoid symbol collisions such as `Inlet`, `Outlet`, and `createRouter`.

## Flutter Example

```dart
import 'package:flutter/material.dart';
import 'package:unrouter/flutter.dart';

final Unrouter router = createRouter(
  routes: [Inlet(path: '/', view: HomePage.new)],
);

void main() {
  runApp(MaterialApp.router(routerConfig: createRouterConfig(router)));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home'));
  }
}
```

## More Examples

- [Flutter example app](https://github.com/medz/unrouter/tree/main/examples/flutter_example)
  Flutter app with quickstart and advanced demos.
- [Nocterm example app](https://github.com/medz/unrouter/tree/main/examples/nocterm_example)
  Terminal app showing nested routes, named routes, and route state.

Run the Flutter example:

```bash
cd examples/flutter_example
flutter run -d chrome
```

Run the Nocterm example:

```bash
cd examples/nocterm_example
dart run
```
