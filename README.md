# Unrouter

Declarative routing for Flutter and Nocterm, built on a shared Dart core.

Unrouter provides nested route trees, named navigation, guards, route params,
query helpers, and adapter-specific rendering for both widget apps and terminal
UIs.

## Packages

| Package | Best for | Notes |
| --- | --- | --- |
| [`unrouter`](packages/unrouter/README.md) | Most apps | Primary brand package with the default Flutter import plus Nocterm and core entrypoints. |
| [`flutter_unrouter`](packages/flutter_unrouter/README.md) | Direct Flutter integration | `MaterialApp.router`, `Outlet`, `Link`, and route hooks. |
| [`nocterm_unrouter`](packages/nocterm_unrouter/README.md) | Terminal apps built with Nocterm | Nested routing with `UnrouterHost` and `Outlet`. |
| [`unrouter_core`](packages/unrouter_core/README.md) | Shared routing logic | Matching, guards, params, query helpers, and history APIs. |

## Which Package Should I Use?

- Start with `unrouter` if you want the default brand package and the simplest public entrypoint.
- Use `flutter_unrouter` if you only need the Flutter adapter.
- Use `nocterm_unrouter` if you are building a Nocterm app.
- Use `unrouter_core` if you are integrating the routing engine into another
  renderer.

## Quick Start

Install the umbrella package:

```bash
dart pub add unrouter
```

Flutter apps can keep using the legacy-compatible import:

```dart
import 'package:unrouter/unrouter.dart';
```

Or choose a more specific entrypoint:

```dart
import 'package:unrouter/flutter.dart';
import 'package:unrouter/nocterm.dart';
import 'package:unrouter/core.dart';
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

## Repository

This repository is organized as a Dart pub workspace. The main package page for
users lives at [`packages/unrouter/README.md`](packages/unrouter/README.md).
