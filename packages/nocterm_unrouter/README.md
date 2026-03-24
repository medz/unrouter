# Nocterm Unrouter

[![Test](https://github.com/medz/unrouter/actions/workflows/ci.yml/badge.svg)](https://github.com/medz/unrouter/actions/workflows/ci.yml)
[![pub](https://img.shields.io/pub/v/nocterm_unrouter.svg)](https://pub.dev/packages/nocterm_unrouter)
![dart](https://img.shields.io/badge/dart-%3E%3D3.10.0-0175C2?logo=dart&logoColor=white)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Routing for Nocterm apps with nested layouts, guards, params, query state, and
named navigation.

## Install

```bash
dart pub add nocterm_unrouter
```

## Quick Start

```dart
import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
import 'package:unstory/unstory.dart';

final router = createRouter(
  history: MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/'))]),
  routes: const [
    Inlet(path: '/', view: HomeView.new),
    Inlet(
      path: '/docs',
      view: DocsPage.new,
      children: [Inlet(path: 'intro', view: IntroPage.new)],
    ),
  ],
);

Future<void> main() async {
  await runApp(NoctermApp(child: RouterView(router: router)));
}

class HomeView extends StatelessComponent {
  const HomeView({super.key});

  @override
  Component build(BuildContext context) {
    return const Text('Home');
  }
}

class DocsPage extends StatelessComponent {
  const DocsPage({super.key});

  @override
  Component build(BuildContext context) {
    return const Column(children: [Text('Docs'), Expanded(child: Outlet())]);
  }
}

class IntroPage extends StatelessComponent {
  const IntroPage({super.key});

  @override
  Component build(BuildContext context) {
    return const Text('Intro');
  }
}
```

Use this package when you want terminal screens to follow the same route-tree
model as the Flutter package.

## Learn More

- [Nocterm example](https://github.com/medz/unrouter/tree/main/examples/nocterm_example)
- [unrouter](https://pub.dev/packages/unrouter) if you want the all-in-one package
