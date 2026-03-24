<p align="center">
  <img src="assets/brand.svg" width="120" alt="unrouter" />
</p>

<p align="center">
  <strong>⍨ Declarative, composable router for Dart/Flutter ecosystem apps.</strong>
</p>

## What's Unrouter

Unrouter provides nested route trees, named navigation, guards, route params,
query helpers, shared history APIs, and adapter-specific rendering for both
widget apps and terminal UIs.

## Packages

| Package                                                   | Version                                                                                                | Best for                         | Notes                                                                                    |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | -------------------------------- | ---------------------------------------------------------------------------------------- |
| [`unrouter`](packages/unrouter/README.md)                 | [![pub](https://img.shields.io/pub/v/unrouter.svg)](https://pub.dev/packages/unrouter)                 | Most apps                        | Main package that exposes `flutter.dart`, `nocterm.dart`, and shared core/history APIs. |
| [`flutter_unrouter`](packages/flutter_unrouter/README.md) | [![pub](https://img.shields.io/pub/v/flutter_unrouter.svg)](https://pub.dev/packages/flutter_unrouter) | Direct Flutter integration       | `MaterialApp.router`, `Outlet`, `Link`, and route hooks.                                 |
| [`nocterm_unrouter`](packages/nocterm_unrouter/README.md) | [![pub](https://img.shields.io/pub/v/nocterm_unrouter.svg)](https://pub.dev/packages/nocterm_unrouter) | Terminal apps built with Nocterm | Nested routing with `RouterView` and `Outlet`.                                           |
| [`unrouter_core`](packages/unrouter_core/README.md)       | [![pub](https://img.shields.io/pub/v/unrouter_core.svg)](https://pub.dev/packages/unrouter_core)       | Shared routing logic             | Matching, guards, params, query helpers, and history APIs.                               |

## Which Package Should I Use?

- Start with `unrouter` if you want the main package and the simplest public entrypoint.
- Use `flutter_unrouter` if you only need the Flutter adapter.
- Use `nocterm_unrouter` if you are building a Nocterm app.
- Use `unrouter_core` if you are integrating the routing engine into another renderer.

## Quick Start

Install the main package:

```bash
dart pub add unrouter
```

Use the Flutter entrypoint from the main package:

```dart
import 'package:unrouter/flutter.dart';
```

Use the Nocterm entrypoint in terminal apps:

```dart
import 'package:unrouter/nocterm.dart';
```

Use the shared core and history APIs directly when you are building on top of
the routing engine:

```dart
import 'package:unrouter/unrouter.dart';
```

## Examples

- [`examples/flutter_example`](examples/flutter_example): Flutter app showing
  nested routes, layouts, and advanced routing patterns.
- [`examples/nocterm_example`](examples/nocterm_example): Terminal app showing
  nested docs routes, named routes, params, query values, and back navigation.

Run an example:

```bash
cd examples/flutter_example
flutter run -d chrome
```

```bash
cd examples/nocterm_example
dart run
```
