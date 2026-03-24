# nocterm_unrouter

Declarative nested routing for terminal apps built with Nocterm.

`nocterm_unrouter` adapts `unrouter_core` to Nocterm components. It keeps
Unrouter as the source of truth for page navigation while rendering the matched
route chain with `RouterView` and nested `Outlet` scopes.

If you want a single public dependency, use
[unrouter](https://pub.dev/packages/unrouter) and import `package:unrouter/nocterm.dart`.

## Features

- Declare terminal route trees with `Inlet`
- Render nested layouts with `Outlet`
- Navigate by path or route name
- Read params, query values, and state from route scope
- Use guards and redirects from the shared core
- Keep routing logic independent from Nocterm overlays and dialogs

## Usage

Import the adapter directly:

```dart
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
```

Or use the umbrella package:

```dart
import 'package:unrouter/nocterm.dart';
```

## Minimal Example

```dart
import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
import 'package:unstory/unstory.dart';

final Unrouter router = createRouter(
  history: MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/'))]),
  routes: const [
    Inlet(path: '/', view: HomeView.new),
    Inlet(
      path: '/docs',
      view: DocsLayout.new,
      children: [Inlet(path: 'intro', view: DocsIntroView.new)],
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

class DocsLayout extends StatelessComponent {
  const DocsLayout({super.key});

  @override
  Component build(BuildContext context) {
    return const Column(children: [Text('Docs'), Expanded(child: Outlet())]);
  }
}

class DocsIntroView extends StatelessComponent {
  const DocsIntroView({super.key});

  @override
  Component build(BuildContext context) {
    return const Text('Intro');
  }
}
```

## Example App

See the
[Nocterm example app](https://github.com/medz/unrouter/tree/main/examples/nocterm_example)
for a runnable terminal demo.
