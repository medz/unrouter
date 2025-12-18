# unrouter

[![pub](https://img.shields.io/pub/v/unrouter.svg)](https://pub.dev/packages/unrouter)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A declarative Flutter router that feels like the browser’s `history` and SwiftUI’s NavigationStack philosophy.

## Features

- Declarative route tree (`Inlet`)
- Nested routes + layouts (`Outlet`)
- URL patterns: static segments, params (`:id`), optionals (`?`), wildcard (`*`)
- Browser-style navigation: `push`, `replace`, `back`, `forward`, `go(delta)`
- Web URL strategies: `UrlStrategy.browser` and `UrlStrategy.hash`
- Relative navigation (e.g. `Uri.parse('edit')` → `/users/123/edit`)

## Install

Add to `pubspec.yaml`:

```yaml
dependencies:
  unrouter: ^0.1.0
```

## Quick start

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

## Layouts and nested routes

Layout and nested routes must render an `Outlet` to show their matched child.

```dart
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Outlet());
  }
}
```

## Reading location and params

```dart
final state = RouterStateProvider.of(context);
final uri = state.info.uri;
final params = state.params; // merged params up to this level
final extra = state.info.state; // history entry state (if any)
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

- `Unrouter`: a `RouterConfig<RouteInformation>` (drop into `MaterialApp.router`)
- `Inlet`: route definition (index/layout/leaf/nested)
- `Outlet`: renders the next matched child route
- `Navigate.of(context)`: access navigation without a global router
- `RouterStateProvider`: read `RouteInformation` + merged params
- `History` / `MemoryHistory`: injectable history (great for tests)

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
