<p align="center">
  <img src="assets/brand.svg" width="120" alt="unrouter" />
</p>

<p align="center">
  <strong>Declarative, composable router for Flutter.</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/unrouter"><img src="https://img.shields.io/pub/v/unrouter.svg" alt="pub"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license"></a>
</p>

---

## Features

- 🧩 **Nested Routes** — Define route trees with `Inlet` and render child views via `Outlet`
- 🏷️ **Named Routes** — Navigate by name with type-safe params, query, and state
- 🛡️ **Middleware** — Async guard / intercept chain (auth, logging, latency simulation, etc.)
- 📦 **Route Meta** — Attach arbitrary metadata to each route, inherited by children
- 🔗 **Dynamic Params & Wildcards** — `:id` params and `*` catch-all segments
- 🔍 **Query Params** — First-class `URLSearchParams` support
- 📍 **History API** — `push`, `replace`, `back`, `forward`, `go(delta)` with full state tracking
- ⚡ **Reactive Hooks** — `useRouter`, `useLocation`, `useRouteParams`, `useQuery`, `useRouteMeta`, `useRouteState`, `useFromLocation`

## Quick Start

### Install

```yaml
dependencies:
  unrouter: <latest>
```

```bash
flutter pub add unrouter
```

### Define Routes

```dart
import 'package:flutter/material.dart' hide Router;
import 'package:unrouter/unrouter.dart';

final router = createRouter(
  routes: [
    Inlet(name: 'landing', path: '/', view: LandingView.new),
    Inlet(name: 'login', path: '/login', view: LoginView.new),
    Inlet(
      path: '/workspace',
      view: WorkspaceShellView.new,
      children: [
        Inlet(name: 'workspaceHome', path: '', view: DashboardView.new),
        Inlet(name: 'profile', path: 'users/:id', view: ProfileView.new),
        Inlet(name: 'search', path: 'search', view: SearchView.new),
      ],
    ),
    Inlet(name: 'docs', path: '/docs/*', view: DocsView.new),
  ],
);
```

`routes` supports multiple top-level `Inlet`s. Use a single parent `Inlet` with `Outlet` only when pages share the same shell layout.

### Bootstrap the App

```dart
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: createRouterConfig(router),
    );
  }
}
```

### Render Nested Views with `Outlet`

`Outlet` renders the matched child route inside the parent layout:

```dart
class ShellView extends StatelessWidget {
  const ShellView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App')),
      body: const Outlet(), // ← child route renders here
    );
  }
}
```

## Core Concepts

### Inlet — Route Definition

`Inlet` is the building block for the route tree. Each `Inlet` describes a path segment, a view builder, and optional children, middleware, meta, and a name.

```dart
Inlet(
  name: 'profile',           // Named route alias (optional)
  path: 'users/:id',         // URL pattern (supports :param and * wildcard)
  view: ProfileView.new,
  meta: const {'title': 'Profile', 'requiresAuth': true},
  middleware: [authGuard],
  children: [ /* nested Inlets */ ],
)
```

| Property     | Type                    | Description                             |
| ------------ | ----------------------- | --------------------------------------- |
| `path`       | `String`                | URL segment pattern. Defaults to `'/'`  |
| `view`       | `ViewBuilder`           | `() => Widget` factory                  |
| `name`       | `String?`               | Named alias for programmatic navigation |
| `meta`       | `Map<String, Object?>?` | Route metadata, merged with parent meta |
| `middleware` | `Iterable<Middleware>`  | Route-level middleware chain            |
| `children`   | `Iterable<Inlet>`       | Nested child routes                     |

### Outlet — Nested View Rendering

`Outlet` renders the matched child view inside its parent. Every level of nesting requires an `Outlet` in the parent's widget tree:

```
/                    → RootView (contains Outlet)
├── /                → HomeView
├── /users/:id       → ProfileView
└── /search          → SearchView
```

### Middleware

Middleware intercepts route navigation. Each middleware receives a `BuildContext` and a `next` callback. Call `next()` to proceed, or return a different widget to block/redirect.

```dart
final authGuard = defineMiddleware((context, next) async {
  final token = useQuery(context).get('token');
  if (token != 'valid') {
    return const UnauthorizedView(); // Block navigation
  }
  return next(); // Continue to the route
});

final logger = defineMiddleware((context, next) async {
  final location = useLocation(context);
  debugPrint('[router] ${location.uri}');
  return next();
});
```

Middleware is applied in order: **global → parent → child**. Middleware defined in `createRouter(middleware: [...])` runs for every route.

```dart
final router = createRouter(
  middleware: [logger],       // Global: runs on every navigation
  routes: [
    Inlet(
      view: Shell.new,
      children: [
        Inlet(
          path: 'admin',
          view: AdminView.new,
          middleware: [authGuard],  // Route-level: runs only for /admin
        ),
      ],
    ),
  ],
);
```

### Data Loader

`defineDataLoader` creates a reactive async data fetcher that integrates with [oref](https://pub.dev/packages/oref):

```dart
final loadUser = defineDataLoader<User>((context) async {
  final params = useRouteParams(context);
  final id = params.required('id');
  return await api.fetchUser(id);
});
```

### Named Navigation

Navigate by route name with type-safe params, query, and state:

```dart
final router = useRouter(context);

// By name
await router.push('profile', params: {'id': '42'});

// By name with query + state
await router.push(
  'search',
  query: URLSearchParams({'q': 'flutter', 'page': '1'}),
  state: {'from': 'home'},
);

// By absolute path
await router.push('/users/42?tab=posts');

// Replace (no new history entry)
await router.replace('home');
```

### Dynamic Params

Use `:param` for named segments and `*` for catch-all wildcards:

```dart
// Route: /users/:id
Inlet(name: 'profile', path: 'users/:id', view: ProfileView.new)

// Navigate
await router.push('profile', params: {'id': '42'});
// → /users/42

// Route: /docs/*
Inlet(name: 'docs', path: 'docs/*', view: DocsView.new)

// Navigate
await router.push('docs', params: {'wildcard': 'guide/getting-started'});
// → /docs/guide/getting-started
```

### Route Meta

Attach arbitrary metadata to routes. Meta is merged from parent to child:

```dart
Inlet(
  view: Shell.new,
  meta: const {'layout': 'shell'},
  children: [
    Inlet(
      path: 'admin',
      view: AdminView.new,
      meta: const {'title': 'Admin', 'requiresAuth': true},
      // Resolved meta: {'layout': 'shell', 'title': 'Admin', 'requiresAuth': true}
    ),
  ],
)
```

Read meta in your views:

```dart
final meta = useRouteMeta(context);
final title = meta['title'] as String?;
```

### History Control

```dart
final router = useRouter(context);

router.back();       // Go back one entry
router.forward();    // Go forward one entry
router.go(-2);       // Jump back 2 entries
router.go(1);        // Jump forward 1 entry
```

## Reactive Hooks

Access route state reactively inside widgets. These functions subscribe to fine-grained `InheritedModel` aspects, so widgets only rebuild when the specific data they depend on changes.

| Hook                        | Returns                | Description                         |
| --------------------------- | ---------------------- | ----------------------------------- |
| `useRouter(context)`        | `Router`               | The router instance                 |
| `useLocation(context)`      | `HistoryLocation`      | Current URI + state                 |
| `useRouteParams(context)`   | `RouteParams`          | Matched `:param` values             |
| `useQuery(context)`         | `URLSearchParams`      | Parsed query string                 |
| `useRouteMeta(context)`     | `Map<String, Object?>` | Merged route metadata               |
| `useRouteState<T>(context)` | `T`                    | Typed navigation state              |
| `useRouteURI(context)`      | `Uri`                  | Current route URI                   |
| `useFromLocation(context)`  | `HistoryLocation?`     | Previous location (for transitions) |

## API Reference

### `createRouter`

```dart
Router createRouter({
  required Iterable<Inlet> routes,
  Iterable<Middleware>? middleware,
  String base = '/',
  History? history,
  HistoryStrategy strategy = HistoryStrategy.browser,
})
```

Creates a `Router` instance. The `Router` interface exposes:

- `history` — Underlying `History` object
- `push(pathOrName, {params, query, state})` — Push a new entry
- `replace(pathOrName, {params, query, state})` — Replace current entry
- `back()` / `forward()` / `go(delta)` — History traversal
- Implements `Listenable` for change notifications

### `createRouterConfig`

```dart
RouterConfig<HistoryLocation> createRouterConfig(Router router)
```

Creates a `RouterConfig` to pass to `MaterialApp.router(routerConfig: ...)`.

### `defineMiddleware`

```dart
Middleware defineMiddleware(
  FutureOr<Widget> Function(BuildContext context, Next next) middleware,
)
```

### `defineDataLoader`

```dart
DataLoader<T> defineDataLoader<T>(
  DataFetcher<T> fetcher, {
  ValueGetter<T?>? defaults,
})
```

## Example

A full working example is available in the [`example/`](example/) directory. Run it with:

```bash
cd example
flutter run -d chrome
```

## License

[MIT](LICENSE) © [Seven Du](https://github.com/medz)
