# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## 0.12.0

Changes since `v0.11.0`, based on PR [#37](https://github.com/medz/unrouter/pull/37).

### New Features

- Upgraded route matching to `roux ^0.5.0` and query parameter utilities to `ht ^0.3.0`.
- Added support for named remainder wildcards such as `**:wildcard` in reverse routing.

### Fixes

- Aligned reverse-routing wildcard generation with upstream `roux` semantics so `*` remains single-segment while `**` and `**:name` support remainder paths.
- Added validation for empty wildcard parameter names in reverse routing patterns.

### Documentation

- Updated wildcard examples and upgrade notes to reflect the `*` versus `**` semantic split introduced upstream.

### Tests

- Added coverage for single-segment wildcard validation, remainder wildcard expansion, and index child routes that share the parent path.

## 0.11.0

Changes since `unrouter-v0.10.0` (2026-02-11), based on PR [#36](https://github.com/medz/unrouter/pull/36).

### New Features

- Unified routing API: guards, data loaders, named routes, `Outlet`-based nested views, and declarative `Link` navigation.
- Added route scope hooks for location, params, query, and typed route state access.
- Added Flutter router integration and runnable examples (`Quickstart` and `Advanced`).

### Documentation

- Revamped `README.md` with centered brand header, badges, Quick Start, Core Concepts, and a consolidated API reference.

### Tests

- Added comprehensive unit/widget coverage for guards, `Outlet`, `URLSearchParams`, and routing flows.

### Chores

- Added CI workflow for Flutter analysis and tests.
