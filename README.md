# Unrouter

[![CI](https://github.com/medz/unrouter/actions/workflows/tests.yml/badge.svg)](https://github.com/medz/unrouter/actions/workflows/tests.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/medz/unrouter/blob/main/LICENSE)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.10.0-0175C2.svg)](https://dart.dev)
[![pub workspace](https://img.shields.io/badge/pub%20workspace-4%20packages-6f42c1.svg)](https://dart.dev/tools/pub/workspaces)

`unrouter` is a typed, URL-first routing ecosystem for Dart runtimes..

## Packages

| Package                | Role                                                         |
| ---------------------- | ------------------------------------------------------------ |
| `pub/unrouter`         | Platform-agnostic core router and runtime controller.        |
| `pub/flutter_unrouter` | Flutter adapter (`RouterConfig`, pages, shell UI binding).   |
| `pub/jaspr_unrouter`   | Jaspr adapter (`StatefulComponent` router + `UnrouterLink`). |
| `pub/nocterm_unrouter` | Nocterm adapter for terminal/TUI navigation.                 |

## Architecture

- Core (`unrouter`) owns route matching, typed parsing, guards, redirects,
  loaders, and runtime state.
- Adapters map core resolution to framework UI trees and provide
  framework-specific helpers.
- Shell routing coordination is shared by core and reused by all adapters.

## Workspace setup

```bash
dart pub get
dart pub workspace list
```

## Verify all packages

```bash
./tool/workspace_check.sh
```

Manual checks:

```bash
(cd pub/unrouter && dart analyze && dart test)
(cd pub/flutter_unrouter && flutter analyze && flutter test)
(cd pub/jaspr_unrouter && dart analyze && dart test)
(cd pub/nocterm_unrouter && dart analyze && dart test)
```

## Run examples

```bash
# Core (pure Dart)
cd pub/unrouter/example && dart run bin/main.dart

# Flutter
cd pub/flutter_unrouter/example && flutter run -d chrome

# Jaspr
cd pub/jaspr_unrouter/example && dart run lib/main.dart

# Nocterm
cd pub/nocterm_unrouter/example && dart run bin/main.dart
```

## Package docs

- `pub/unrouter/README.md`
- `pub/flutter_unrouter/README.md`
- `pub/jaspr_unrouter/README.md`
- `pub/nocterm_unrouter/README.md`
