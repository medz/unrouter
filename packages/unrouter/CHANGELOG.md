# Changelog

## 0.14.0

### Highlights

Picks up breaking changes from `unrouter_core` 0.2.0, the new `useRouter`
helper in `nocterm_unrouter` 0.3.0, and the internal `flutter_unrouter` 0.2.1
refactor.

### Breaking Changes

- `RouteNode.meta` and `RouteRecord.meta` are now non-nullable (`Map<String, Object?>`
  defaulting to `const {}`). See `unrouter_core` 0.2.0 migration notes.
- `Unrouter.matcher` and `Unrouter.aliases` expose `roux.Router<T>` which no
  longer has `.match()`. Use `.find()` instead.

### What's New

- `useRouter(context)` is now available in the `nocterm.dart` entrypoint.

### Migration Notes

- Replace direct calls to `router.matcher.match(path)` with `.find(path)`.
- Remove `?? const {}` guards on `meta` fields — the value is always non-null.

## v0.13.0

**Migration guide**: See Migration note below.

### Highlights

Unrouter 0.13.0 turns the main package into the primary brand-level entrypoint
for the whole project. The package root now exposes shared core and history
APIs, while `package:unrouter/flutter.dart` and `package:unrouter/nocterm.dart`
provide the framework-specific adapters. This release also moves runnable demos
into workspace examples and aligns the published package with the new
multi-package layout.

### Breaking Changes

- `package:unrouter/unrouter.dart` now exports shared `unrouter_core` and
  history APIs instead of the old Flutter-specific router surface.
- Flutter apps must import `package:unrouter/flutter.dart` for `Inlet`,
  `Outlet`, `Link`, `createRouter`, and `createRouterConfig`.
- Nocterm apps must import `package:unrouter/nocterm.dart` for terminal router
  APIs such as `RouterView`, `Inlet`, and `Outlet`.
- The package no longer ships the old single-package implementation from
  `0.12.x`; framework APIs now come from the published adapter packages.

### What's New

#### Main-package entrypoints

- Added `package:unrouter/flutter.dart` for Flutter adapter exports.
- Added `package:unrouter/nocterm.dart` for Nocterm adapter exports.
- Kept `package:unrouter/unrouter.dart` as the shared core and history entrypoint.

#### Workspace examples and package layout

- Moved runnable Flutter and Nocterm demos into top-level workspace examples.
- Split the codebase into publishable packages for `unrouter_core`,
  `flutter_unrouter`, and `nocterm_unrouter` while keeping `unrouter` as the
  main package users install first.

#### Adapter alignment

- Updated the main package to depend on `flutter_unrouter ^0.2.0`,
  `nocterm_unrouter ^0.2.0`, and `unrouter_core ^0.1.0`.

### Migration note

- Flutter apps upgrading from `0.12.x` should replace:

  ```dart
  import 'package:unrouter/unrouter.dart';
  ```

  with:

  ```dart
  import 'package:unrouter/flutter.dart';
  ```

- Nocterm apps should import:

  ```dart
  import 'package:unrouter/nocterm.dart';
  ```

- Use `package:unrouter/unrouter.dart` only when you want shared routing and
  history APIs without a renderer-specific adapter.
- If you import multiple entrypoints in one file, use prefixes to avoid symbol
  collisions for `Inlet`, `Outlet`, `Unrouter`, and `createRouter`.

### Full Changelog

- https://github.com/medz/unrouter/compare/v0.12.0...unrouter-v0.13.0

## v0.12.0

**Migration guide**: Not required.

### Highlights

Unrouter 0.12.0 refined wildcard routing semantics to match upstream matching
behavior and added support for named remainder wildcards in reverse routing.

### Breaking Changes

- None.

### What's New

#### Wildcard routing

- Upgraded route matching to `roux ^0.5.0` and query parameter utilities to
  `ht ^0.3.0`.
- Added support for named remainder wildcards such as `**:wildcard` in reverse
  routing.

#### Fixes and tests

- Aligned reverse-routing wildcard generation with upstream `roux` semantics so
  `*` remains single-segment while `**` and `**:name` support remainder paths.
- Added validation for empty wildcard parameter names in reverse routing
  patterns.
- Added coverage for single-segment wildcard validation, remainder wildcard
  expansion, and index child routes that share the parent path.

### Migration note

- No migration is required for this release.

## v0.11.0

**Migration guide**: Not required.

### Highlights

Unrouter 0.11.0 introduced the unified Flutter routing surface with nested
views, guards, route state hooks, and runnable examples.

### Breaking Changes

- None.

### What's New

#### Flutter routing API

- Added the unified routing API with guards, data loaders, named routes,
  `Outlet`-based nested views, and declarative `Link` navigation.
- Added route scope hooks for location, params, query, and typed route state
  access.
- Added Flutter router integration and runnable Quickstart and Advanced demos.

#### Docs and tests

- Revamped the package README with Quick Start, Core Concepts, and API
  guidance.
- Added comprehensive unit and widget coverage for guards, `Outlet`,
  `URLSearchParams`, and routing flows.
- Added CI workflow for Flutter analysis and tests.

### Migration note

- No migration is required for this release.
