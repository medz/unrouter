<p align="center">
  <img src="assets/brand.svg" width="120" alt="unrouter" />
</p>

<p align="center">
  <strong>Declarative, composable router for Flutter.</strong>
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

- Nested routes with `Inlet` and `Outlet`
- Named routes with params, query, and state
- Guards with allow, block, and redirect outcomes
- Route meta inheritance
- Dynamic params and wildcards
- First-class query params support
- Browser and memory history support
- Reactive route hooks for Flutter widgets

## Install

```yaml
dependencies:
  unrouter: <latest>
```

```bash
flutter pub add unrouter
```

## Example

The package example lives in [`example/`](example).

```bash
cd example
flutter pub get
flutter run -d chrome
```
