# flutter_unrouter

Declarative nested routing for Flutter, powered by the shared Unrouter core.

`flutter_unrouter` adds a Flutter renderer on top of `unrouter_core`, with
`MaterialApp.router` integration, nested `Outlet` rendering, route-scoped
hooks, navigation guards, named routes, and query helpers.

If you want a single public dependency, use
[unrouter](https://pub.dev/packages/unrouter) and import `package:unrouter/unrouter.dart`
or `package:unrouter/flutter.dart`.

## Features

- Declare route trees with `Inlet`
- Render nested layouts with `Outlet`
- Navigate by path or route name
- Use guards for redirects and access control
- Read params, query values, state, and metadata from route scope
- Integrate with Flutter's `Router` API through `createRouterConfig`

## Usage

Import the adapter directly:

```dart
import 'package:flutter_unrouter/flutter_unrouter.dart';
```

Or use the umbrella package:

```dart
import 'package:unrouter/unrouter.dart';
```

## Minimal Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';

final Unrouter router = createRouter(
  routes: [
    Inlet(path: '/', view: HomePage.new),
    Inlet(
      path: '/settings',
      view: SettingsLayout.new,
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

class SettingsLayout extends StatelessWidget {
  const SettingsLayout({super.key});

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

## Example App

See the
[Flutter example app](https://github.com/medz/unrouter/tree/main/examples/flutter_example)
for a runnable demo with quickstart and advanced examples.
