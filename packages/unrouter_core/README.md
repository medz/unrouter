# Unrouter Core

[![Test](https://github.com/medz/unrouter/actions/workflows/test.yml/badge.svg)](https://github.com/medz/unrouter/actions/workflows/test.yml)
[![pub](https://img.shields.io/pub/v/unrouter_core.svg)](https://pub.dev/packages/unrouter_core)
![dart](https://img.shields.io/badge/dart-%3E%3D3.10.0-0175C2?logo=dart&logoColor=white)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Core routing primitives for matching, navigation, guards, params, query
helpers, and route metadata.

## Install

```bash
dart pub add unrouter_core
```

## Quick Start

```dart
import 'package:unrouter_core/unrouter_core.dart';
import 'package:unstory/unstory.dart';

final router = createRouter<String>(
  history: MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/'))]),
  routes: const [
    RouteNode<String>(path: '/', view: homeView),
    RouteNode<String>(path: '/users/:id', name: 'user', view: userView),
  ],
);

String homeView() => 'home';
String userView() => 'user';
```

Use this package when you are building on top of the routing engine itself.

This package does not render UI. For Flutter and Nocterm packages, see
[flutter_unrouter](https://pub.dev/packages/flutter_unrouter) and
[nocterm_unrouter](https://pub.dev/packages/nocterm_unrouter).
