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
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license"></a>
</p>

---

## Features

- 🧩 **Nested Routes** — Define route trees with `Inlet` and render child views via `Outlet`
- 🏷️ **Named Routes** — Navigate by route name with params, query, and state
- 🛡️ **Guards** — Navigation-time guards for allow/block/redirect decisions
- 📦 **Route Meta** — Attach arbitrary metadata to each route, inherited by children
- 🔗 **Dynamic Params & Wildcards** — `:id` params and `*` catch-all segments
- 🔍 **Query Params** — First-class `URLSearchParams` support
- 📍 **History API** — `push`, `replace`, `pop`, `back`, `forward`, `go(delta)`
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
import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

final authGuard = defineGuard((context) async {
  final token = context.query.get('token');
  if (token == 'valid') {
    return const GuardResult.allow();
  }
  return GuardResult.redirect('login');
});

final router = createRouter(
  guards: [authGuard],
  maxRedirectDepth: 8,
  routes: [
    Inlet(name: 'landing', path: '/', view: LandingView.new),
    Inlet(name: 'login', path: '/login', view: LoginView.new),
    Inlet(
      path: '/workspace',
      view: WorkspaceLayoutView.new,
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

`routes` supports multiple top-level `Inlet`s. Use a single parent `Inlet` with `Outlet` only when views share the same layout.
For concise route definitions, prefer constructor tear-offs such as `MyView.new`.

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

```dart
class LayoutView extends StatelessWidget {
  const LayoutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App')),
      body: const Outlet(),
    );
  }
}
```

## Core Concepts

### Inlet — Route Definition

`Inlet` is the route-tree building block. Each `Inlet` describes a path segment, a view builder, optional children, guards, meta, and an optional route name.

```dart
Inlet(
  name: 'profile',
  path: 'users/:id',
  view: ProfileView.new,
  meta: const {'title': 'Profile', 'requiresAuth': true},
  guards: [authGuard],
  children: [/* nested Inlets */],
)
```

| Property | Type | Description |
| --- | --- | --- |
| `path` | `String` | URI path segment pattern. Defaults to `'/'` |
| `view` | `ViewBuilder` | `() => Widget` factory, typically `MyView.new` |
| `name` | `String?` | Route name alias for navigation APIs |
| `meta` | `Map<String, Object?>?` | Route metadata, merged with parent meta |
| `guards` | `Iterable<Guard>` | Route-level guard chain |
| `children` | `Iterable<Inlet>` | Nested child routes |

### Guard

A guard runs **before navigation is committed** and returns one of three outcomes:

- `GuardResult.allow()`
- `GuardResult.block()`
- `GuardResult.redirect(pathOrName, {params, query, state})`

```dart
final adminGuard = defineGuard((context) async {
  final isAdmin = context.query.get('role') == 'admin';
  if (isAdmin) {
    return const GuardResult.allow();
  }
  return GuardResult.redirect(
    'login',
    query: URLSearchParams({'from': 'admin'}),
  );
});
```

Guard order is: **global → parent → child**.

- Redirects are re-validated by guards.
- Redirect commits use `replace`.
- Redirect depth is capped by `maxRedirectDepth` (default `8`) to prevent infinite loops.

### GuardContext

`GuardContext` provides navigation details:

- `from` / `to` (`HistoryLocation`)
- `action` (`HistoryAction.push`, `.replace`, `.pop`)
- `params` (`RouteParams`)
- `query` (`URLSearchParams`)
- `meta` (`Map<String, Object?>`)
- `state` (`Object?`)

### Named Navigation

`push/replace(pathOrName)` resolves in this order:

1. Try route name first
2. If missing, fallback to absolute path

```dart
final router = useRouter(context);

await router.push('profile', params: {'id': '42'});
await router.push('/users/42?tab=posts');
await router.replace('landing');
```

### Query Merging

If both the input string and `query` argument contain query params, they are merged and explicit `query` entries override same-name keys.

```dart
await router.push(
  '/search?q=old&page=1',
  query: URLSearchParams({'q': 'flutter'}),
);
// => /search?q=flutter&page=1
```

### Link Component

`Link` is a lightweight widget that triggers navigation.

```dart
Link(
  to: 'profile',
  params: const {'id': '42'},
  child: const Text('Open Profile'),
)
```

Supported props:

- `to`
- `params`
- `query`
- `state`
- `replace`
- `enabled`
- `onTap`
- `child`

### Outlet — Nested View Rendering

`Outlet` renders the matched child view inside its parent. Every level of nesting requires an `Outlet` in the parent widget tree.

### Route Meta

Meta is merged from parent to child routes.

```dart
Inlet(
  view: Layout.new,
  meta: const {'layout': 'dashboard'},
  children: [
    Inlet(
      path: 'admin',
      view: AdminView.new,
      meta: const {'title': 'Admin', 'requiresAuth': true},
    ),
  ],
)
```

Read meta in a widget:

```dart
final meta = useRouteMeta(context);
```

### History Control

```dart
final router = useRouter(context);

await router.pop();
router.back();
router.forward();
router.go(-2);
router.go(1);
```

## Reactive Hooks

| Hook | Returns | Description |
| --- | --- | --- |
| `useRouter(context)` | `Unrouter` | Router instance |
| `useLocation(context)` | `HistoryLocation` | Current location (`uri + state`) |
| `useRouteParams(context)` | `RouteParams` | Matched `:param` values |
| `useQuery(context)` | `URLSearchParams` | Parsed query string |
| `useRouteMeta(context)` | `Map<String, Object?>` | Merged route metadata |
| `useRouteState<T>(context)` | `T` | Typed navigation state |
| `useRouteURI(context)` | `Uri` | Current route URI |
| `useFromLocation(context)` | `HistoryLocation?` | Previous location |

## API Reference

### `createRouter`

```dart
Unrouter createRouter({
  required Iterable<Inlet> routes,
  Iterable<Guard>? guards,
  String base = '/',
  int maxRedirectDepth = 8,
  History? history,
  HistoryStrategy strategy = HistoryStrategy.browser,
})
```

### `createRouterConfig`

```dart
RouterConfig<HistoryLocation> createRouterConfig(Unrouter router)
```

### `defineGuard`

```dart
Guard defineGuard(Guard guard)
```

### `defineDataLoader`

```dart
DataLoader<T> defineDataLoader<T>(
  DataFetcher<T> fetcher, {
  ValueGetter<T?>? defaults,
})
```

## License

[MIT](LICENSE) © [Seven Du](https://github.com/medz)
