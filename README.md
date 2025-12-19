# unrouter

[![pub](https://img.shields.io/pub/v/unrouter.svg)](https://pub.dev/packages/unrouter)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A declarative Flutter router that feels like the browser’s `history` and SwiftUI’s NavigationStack philosophy.

## Features

- **Declarative route tree** (`Inlet`) with static and dynamic configuration
- **Dynamic component-scoped routing** via the `Routes` widget
- **Nested routes + layouts** (`Outlet` for pre-defined routes, `Routes` for dynamic routes)
- **URL patterns**: static segments, params (`:id`), optionals (`?`), wildcard (`*`)
- **Browser-style navigation**: `push`, `replace`, `back`, `forward`, `go(delta)`
- **Web URL strategies**: `UrlStrategy.browser` and `UrlStrategy.hash`
- **Relative navigation** (e.g. `Uri.parse('edit')` → `/users/123/edit`)
- **Flexible routing modes**: static-only, dynamic-only, or hybrid (static + dynamic fallback)

## Install

Add to `pubspec.yaml`:

```yaml
dependencies:
  unrouter: ^0.2.0
```

## Quick start

### Static routing (traditional approach)

```dart
import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

final router = Unrouter(
  strategy: .browser,
  routes: const [
    // Index
    Inlet(factory: HomePage.new),

    // Leaf
    Inlet(path: 'about', factory: AboutPage.new),

    // Layout (path == '', children not empty)
    Inlet(
      factory: AuthLayout.new,
      children: [
        Inlet(path: 'login', factory: LoginPage.new),
        Inlet(path: 'register', factory: RegisterPage.new),
      ],
    ),

    // Nested (path != '', children not empty)
    Inlet(
      path: 'users',
      factory: UsersLayout.new,
      children: [
        Inlet(factory: UsersIndexPage.new),
        Inlet(path: ':id', factory: UserDetailPage.new),
      ],
    ),

    // Fallback (keep it last)
    Inlet(path: '*', factory: NotFoundPage.new),
  ],
);

void main() => runApp(MaterialApp.router(routerConfig: router));
```

### Dynamic routing (component-scoped approach)

Define routes directly in your component tree using the `Routes` widget:

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Unrouter(
      strategy: .browser,
      child: Routes([
        Inlet(factory: HomePage.new),
        Inlet(path: 'about', factory: AboutPage.new),
        Inlet(path: 'dashboard', factory: DashboardPage.new),
      ]),
    );
  }
}
```

### Nested dynamic routing

Components can define their own child routes:

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Dashboard'),
        Routes([  // Nested routes defined in component
          Inlet(factory: DashboardHome.new),
          Inlet(path: 'analytics', factory: Analytics.new),
          Inlet(path: 'settings', factory: Settings.new),
        ]),
      ],
    );
  }
}
```

### Hybrid routing (static + dynamic fallback)

Combine static routes with dynamic fallback:

```dart
final router = Unrouter(
  strategy: .browser,
  routes: const [
    // Static routes matched first
    Inlet(path: 'admin', factory: AdminPage.new),
    Inlet(path: 'settings', factory: SettingsPage.new),
  ],
  child: Routes([  // Dynamic fallback when static routes don't match
    Inlet(factory: HomePage.new),
    Inlet(path: 'about', factory: AboutPage.new),
  ]),
);
```

## Layouts and nested routes

### With static routes (using `Outlet`)

Layout and nested routes defined in the static `routes` tree must render an `Outlet` to show their matched child:

```dart
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Outlet());
  }
}
```

### With dynamic routes (using `Routes`)

Define child routes directly in the component using the `Routes` widget:

```dart
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: Routes([
        Inlet(factory: ProductsList.new),
        Inlet(path: ':id', factory: ProductDetail.new),
        Inlet(path: 'new', factory: NewProduct.new),
      ]),
    );
  }
}
```

## Reading location and params

```dart
final state = RouterStateProvider.of(context);
final uri = state.location.uri;
final params = state.params; // merged params up to this level
final extra = state.location.state; // history entry state (if any)
```

## Navigation

From a shared router instance:

```dart
router.navigate(.parse('/about'));
router.navigate(.parse('/login'), replace: true);
router.back();
```

From any widget:

```dart
final nav = Navigate.of(context);
nav(.parse('/users/123'));
nav(.parse('edit')); // relative -> /users/123/edit
```

## API overview

- `Unrouter`: a `RouterConfig<RouteInformation>` (drop into `MaterialApp.router` or use as a widget)
- `Inlet`: route definition (index/layout/leaf/nested)
- `Outlet`: renders the next matched child route (for static pre-defined routes)
- `Routes`: dynamic route matching widget (for component-scoped routes)
- `Navigate.of(context)`: access navigation without a global router
- `RouterStateProvider`: read `RouteInformation` + merged params
- `History` / `MemoryHistory`: injectable history (great for tests)

## Routing approaches

`unrouter` supports three routing approaches:

### 1. Static routing (traditional)
All routes defined upfront in a centralized configuration:
```dart
Unrouter(routes: [...])
```

### 2. Dynamic routing (component-scoped)
Routes defined within components using `Routes` widget:
```dart
Unrouter(child: Routes([...]))
```

### 3. Hybrid routing (static + dynamic)
Static routes matched first, dynamic fallback:
```dart
Unrouter(
  routes: [...],     // Matched first
  child: Routes([...]), // Fallback
)
```

The `Routes` widget enables React Router-style component-scoped routing, where routes are defined close to the components that use them, enabling better code organization and lazy loading.

## Web URL strategy

- `strategy: .browser` uses path URLs like `/about` (requires server rewrites to `index.html`).
- `strategy: .hash` uses hash URLs like `/#/about` (works without server rewrites).

On non-web platforms, `Unrouter` falls back to an in-memory history implementation.

## Route patterns

Supported pattern syntax:

- Static: `about`, `users/profile`
- Params: `users/:id`, `:userId`
- Optional: `:lang?/about`, `users/:id/edit?`
- Wildcard: `files/*`, `*`

## Testing

`MemoryHistory` makes routing tests easy:

```dart
final router = Unrouter(
  routes: const [
    Inlet(factory: HomePage.new),
    Inlet(path: 'about', factory: AboutPage.new),
  ],
  history: MemoryHistory(
    initialEntries: [RouteInformation(uri: Uri.parse('/about'))],
  ),
);
```

## Example

See `example/` for a complete Flutter app.

## Contributing

- Run tests: `flutter test`
- Open a PR with a clear description and a focused diff

## License

MIT — see [`LICENSE`](LICENSE).
