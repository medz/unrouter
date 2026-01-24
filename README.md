<p align="center">
  <img src="assets/brand.svg" width="120" alt="unrouter" />
  <h1 align="center">Unrouter</h1>
  <p align="center">
    <strong>The flexible Flutter router that adapts to your architecture</strong>
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/unrouter"><img src="https://img.shields.io/pub/v/unrouter.svg" alt="pub"></a>
  <a href="https://github.com/medz/unrouter/actions/workflows/tests.yml"><img src="https://github.com/medz/unrouter/actions/workflows/tests.yml/badge.svg" alt="tests"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license"></a>
</p>

---

## Overview

Unrouter is a production-ready Flutter router that supports declarative,
widget-scoped, and hybrid routing. It provides browser-style history,
async guards, route blockers, and Navigator 1.0 compatibility while keeping
route definitions flexible and readable.

Highlights:
- Declarative routes with `Inlet`, widget-scoped routes with `Routes`, or both
- Browser-style navigation (push/replace/back/forward/go)
- Async guards and route blockers (allow/cancel/redirect)
- Nested layouts with `Outlet` and infinite depth
- Named routes with URI generation
- Optional file-based routing CLI (`init/scan/generate/watch`)
- Web URL strategies (browser/hash) and history state

https://github.com/user-attachments/assets/e4f2d9d1-3fe2-4050-8b5b-1e1171027ba2

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  unrouter: ^0.5.1
```

Or run:

```bash
flutter pub add unrouter
```

## Quick start

### Minimal setup

```dart
import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

void main() => runApp(
  Unrouter(
    routes: const [
      Inlet(name: 'home', factory: HomePage.new),
      Inlet(name: 'about', path: 'about', factory: AboutPage.new),
    ],
  ),
);
```

### With MaterialApp

```dart
final router = Unrouter(
  strategy: .browser,
  routes: const [
    Inlet(factory: HomePage.new),
    Inlet(path: 'about', factory: AboutPage.new),
    Inlet(
      path: 'users',
      factory: UsersLayout.new,
      children: [
        Inlet(factory: UsersIndexPage.new),
        Inlet(path: ':id', factory: UserDetailPage.new),
      ],
    ),
    Inlet(path: '*', factory: NotFoundPage.new),
  ],
);

void main() => runApp(MaterialApp.router(routerConfig: router));
```

### Navigate

```dart
context.navigate(path: '/about');
context.navigate(name: 'userDetail', params: {'id': '123'});
context.navigate.back();

context.navigate(path: 'edit');         // /users/123/edit
context.navigate(path: './edit');       // /users/123/edit
context.navigate(path: '../settings');  // /users/settings
```

## Core concepts

### Unrouter

`Unrouter` is a `RouterConfig` you can pass to `MaterialApp.router` or use as a
standalone widget. Provide either `routes`, `child`, or both.

### Inlet

An `Inlet` defines a route segment and optional children.

```dart
Inlet(
  name: 'userDetail',
  path: 'users/:id',
  factory: UserDetailPage.new,
)
```

### Routes and Outlet

`Routes` enables widget-scoped routing. `Outlet` renders matched child routes.

```dart
class UsersLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        UsersToolbar(),
        Expanded(child: Outlet()),
      ],
    );
  }
}
```

## Routing approaches

### Declarative

```dart
Unrouter(
  routes: const [
    Inlet(path: 'admin', factory: AdminPage.new),
  ],
)
```

### Widget-scoped

```dart
Routes([
  Inlet(factory: HomePage.new),
  Inlet(path: 'settings', factory: SettingsPage.new),
])
```

### Hybrid

```dart
Unrouter(
  routes: const [
    Inlet(path: 'admin', factory: AdminPage.new),
  ],
  child: Routes([
    Inlet(factory: HomePage.new),
  ]),
)
```

## Route patterns

Supported path tokens:
- Static segments: `about`
- Named params: `users/:id`
- Optional segments: `:id?`
- Wildcards: `*` (catch-all)

```dart
Inlet(path: 'users/:id', factory: UserDetailPage.new);
Inlet(path: 'blog/:slug?', factory: BlogPage.new);
Inlet(path: '*', factory: NotFoundPage.new);
```

Named routes let you generate URIs and navigate by name:

```dart
Inlet(name: 'userDetail', path: 'users/:id', factory: UserDetailPage.new);
```

## Layouts and nested routing

### Layout routes (path == '')

```dart
Inlet(
  factory: AuthLayout.new,
  children: [
    Inlet(path: 'login', factory: LoginPage.new),
    Inlet(path: 'register', factory: RegisterPage.new),
  ],
)
```

### Nested routes (path + children)

```dart
Inlet(
  path: 'users',
  factory: UsersLayout.new,
  children: [
    Inlet(factory: UsersIndexPage.new),
    Inlet(path: ':id', factory: UserDetailPage.new),
  ],
)
```

## Navigation API

### Navigate by name or path

```dart
context.navigate(
  name: 'userDetail',
  params: {'id': '123'},
  query: {'tab': 'posts'},
  fragment: 'latest',
);

context.navigate(path: '/about', replace: true);
```

### Generate a URI

```dart
final uri = context.navigate.route(
  name: 'userDetail',
  params: {'id': '123'},
  query: {'tab': 'posts'},
);
```

### History controls

```dart
context.navigate.back();
context.navigate.forward();
context.navigate.go(-2);
```

Navigation calls return `Future<Navigation>` so you can detect allow/cancel/redirect.

## File-based routing (CLI)

Unrouter ships a CLI to scan a pages directory and generate a routes file.

### 1) Create config (optional)

Create `unrouter.config.dart` in your project root (the CLI scans upward from
current working directory). The CLI reads this file with the analyzer and does
not execute it.

```dart
// unrouter.config.dart
const pagesDir = 'lib/pages';
const output = 'lib/routes.dart';
```

Notes:
- Both values are optional.
- Paths can be absolute or relative to `unrouter.config.dart`.
- CLI flags (`--pages`, `--output`) override the config file.
- If no config file is found, the CLI uses the nearest `pubspec.yaml` as the root.

### 2) File to route conventions

- `index.dart` maps to the directory root.
- `[id].dart` maps to a named parameter (`:id`).
- `[...path].dart` maps to a wildcard (`*`).
- Folder segments map to path segments, and `index.dart` becomes the parent path.

Examples:

```text
lib/pages/index.dart                  -> /
lib/pages/about.dart                  -> /about
lib/pages/users/index.dart            -> /users
lib/pages/users/[id].dart             -> /users/:id
lib/pages/docs/[...path].dart         -> /docs/*
```

If a path segment has both a file and children, the children are generated as
nested routes. For example:

```text
lib/pages/users/[id].dart
lib/pages/users/[id]/settings.dart
```

Generates a nested tree equivalent to:

```dart
Inlet(
  path: 'users/:id',
  factory: UserDetailPage.new,
  children: [
    Inlet(path: 'settings', factory: UserSettingsPage.new),
  ],
);
```

### 3) Add metadata (optional)

You can add page-level metadata to influence generated routes:

```dart
// lib/pages/users/[id].dart
import 'package:unrouter/unrouter.dart';

Future<GuardResult> authGuard(GuardContext context) async {
  return GuardResult.allow;
}

const route = RouteMeta(
  name: 'userDetail',
  guards: const [authGuard],
);
```

If `name` or `guards` are not literals, the generator falls back to
`route.name` / `route.guards` when building `Inlet`s.

### 4) Use the generated routes

```dart
import 'package:unrouter/unrouter.dart';
import 'routes.dart';

final router = Unrouter(
  routes: routes,
);
```

The generator picks the widget class for a page file by:
1) Prefer class names ending in `Page` or `Screen`.
2) Otherwise, use the first class that extends a `Widget` type.

### 5) Generate routes

- `unrouter generate` (one-time build)
- `unrouter watch` (rebuild on changes)

Use `--verbose` on `generate` to print a detailed route table.

### CLI options

Global options (all commands):
- `-p, --pages`  Pages directory (default: `lib/pages`)
- `-o, --output` Generated file path (default: `lib/routes.dart`)
- `--no-color`   Disable ANSI colors (also respects `NO_COLOR`)
- `-h, --help`   Show usage

Command options:
- `scan`: `-q, --quiet`, `--json`
- `init`: `-f, --force`, `-q, --quiet`
- `generate`: `-v, --verbose`, `-q, --quiet`, `--json`
- `watch`: `-q, --quiet`

## Guards

Guards run from root to leaf and can allow, cancel, or redirect navigation.

```dart
Future<GuardResult> authGuard(GuardContext context) async {
  if (!auth.isSignedIn) {
    return GuardResult.redirect(name: 'login');
  }
  return GuardResult.allow;
}

Unrouter(
  guards: [authGuard],
  routes: const [
    Inlet(path: 'login', factory: LoginPage.new),
    Inlet(path: 'admin', factory: AdminPage.new),
  ],
)
```

## Route blockers

Use `RouteBlocker` to intercept back/pop events and confirm navigation.

```dart
RouteBlocker(
  onWillPop: (context) async => !await confirmLeave(),
  child: Routes([
    Inlet(factory: EditPage.new),
  ]),
)
```

## Link widget

`Link` renders a tappable widget that navigates on click/tap and supports
named routes, paths, params, query, and fragment.

```dart
Link(
  name: 'userDetail',
  params: const {'id': '123'},
  child: const Text('View profile'),
)
```

## Route animations

Access per-route animation controllers:

```dart
final animation = context.routeAnimation();
```

## Navigator 1.0 compatibility

Enable the embedded Navigator 1.0 for dialogs, bottom sheets, and other
Navigator APIs:

```dart
Unrouter(
  enableNavigator1: true,
  routes: const [...],
)
```

## Web URL strategy

```dart
Unrouter(
  strategy: .browser, // or .hash
  routes: const [...],
)
```

Use hash strategy when you cannot configure server rewrites.

## State restoration

```dart
MaterialApp.router(
  routerConfig: router,
  restorationScopeId: 'unrouter',
)
```

## Testing

```bash
flutter test
```

## Example app

```bash
cd example
flutter run
```

## Contributing

```bash
git clone https://github.com/medz/unrouter.git
cd unrouter
flutter pub get
```

```bash
dart format .
flutter analyze
flutter test
```

Follow `flutter_lints` and keep changes focused.

## License

MIT License - see [LICENSE](LICENSE) for details.

<p align="right">
  Built with ❤️ by <a href="https://github.com/medz">Seven Du</a>
</p>
