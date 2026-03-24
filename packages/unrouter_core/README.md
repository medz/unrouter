# unrouter_core

Shared routing primitives for building Unrouter adapters.

`unrouter_core` is the platform-agnostic layer behind the Flutter and Nocterm
adapters. It provides route matching, history-backed navigation, guards, named
routes, route params, query helpers, and merged route metadata.

Use this package when you are integrating Unrouter into another renderer or
building infrastructure on top of the routing engine itself.

## Features

- Generic `RouteNode<V>` declarations
- History-backed `createRouter` for custom renderers
- Named route navigation and alias resolution
- Global and per-route guards
- Route params and URL search param helpers
- Parent-to-child metadata merging

## Usage

```dart
import 'package:unrouter_core/unrouter_core.dart';
import 'package:unstory/unstory.dart';

final Unrouter<String> router = createRouter<String>(
  history: MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/'))]),
  routes: const [
    RouteNode<String>(path: '/', view: _homeView),
    RouteNode<String>(path: '/users/:id', name: 'user', view: _userView),
  ],
);

String _homeView() => 'home';
String _userView() => 'user';
```

The core package does not render views. Adapters such as Flutter and Nocterm
decide how the matched view chain is turned into UI.
