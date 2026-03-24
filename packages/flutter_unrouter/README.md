# Flutter Unrouter

[![Test](https://github.com/medz/unrouter/actions/workflows/ci.yml/badge.svg)](https://github.com/medz/unrouter/actions/workflows/ci.yml)
[![pub](https://img.shields.io/pub/v/flutter_unrouter.svg)](https://pub.dev/packages/flutter_unrouter)
![dart](https://img.shields.io/badge/dart-%3E%3D3.10.0-0175C2?logo=dart&logoColor=white)
![flutter](https://img.shields.io/badge/flutter-stable-02569B?logo=flutter&logoColor=white)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Routing for Flutter apps with nested screens, guards, params, query state, and
named navigation.

## Install

```bash
dart pub add flutter_unrouter
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';

final router = createRouter(
  routes: [
    Inlet(path: '/', view: HomePage.new),
    Inlet(
      path: '/settings',
      view: SettingsPage.new,
      children: [Inlet(path: 'profile', view: ProfilePage.new)],
    ),
  ],
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Outlet());
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile'));
  }
}
```

Use this package when you want one route tree to drive both navigation and
nested UI.

## Learn More

- [Flutter example](https://github.com/medz/unrouter/tree/main/examples/flutter_example)
- [unrouter](https://pub.dev/packages/unrouter) if you want the all-in-one package
