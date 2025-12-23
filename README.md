<p align="center">
  <img src="assets/brand.svg" width="120" alt="unrouter" />
  <h1 align="center">Unrouter</h1>
</p>

[![pub](https://img.shields.io/pub/v/unrouter.svg)](https://pub.dev/packages/unrouter)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Flutter router that gives you routing flexibility: define routes centrally, scope them to widgets, or mix both - with browser-style history navigation.

## Documentation

All sections below are collapsible. Expand the chapters you need.

- [Features](#features)
- [Install](#install)
- [Quick start](#quick-start)
- [Routing approaches](#routing-approaches)
- [Layouts and nested routing](#layouts-and-nested-routing)
- [Route patterns and matching](#route-patterns-and-matching)
- [Navigation and history](#navigation-and-history)
- [Navigation guards](#navigation-guards)
- [Route blockers](#route-blockers)
- [Navigator 1.0 compatibility](#navigator-10-compatibility)
- [State and params](#state-and-params)
- [Link widget](#link-widget)
- [Web URL strategy](#web-url-strategy)
- [Testing](#testing)
- [API overview](#api-overview)
- [Example app](#example-app)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

<a id="features"></a>
<details open>
<summary><strong>Features</strong></summary>

- Declarative routes via `Unrouter(routes: ...)`
- Widget-scoped routes via the `Routes` widget
- Hybrid routing (declarative first, widget-scoped fallback)
- Nested routes + layouts (`Outlet` for declarative routes, `Routes` for widget-scoped)
- URL patterns: static, params (`:id`), optionals (`?`), wildcard (`*`)
- Browser-style navigation: push/replace/back/forward/go
- Async navigation results via `Navigation` (awaitable)
- Navigation guards with allow/cancel/redirect
- Route blockers for back/pop confirmation
- Navigator 1.0 compatibility for overlays and imperative APIs (`enableNavigator1`, default `true`)
- Web URL strategies: `UrlStrategy.browser` and `UrlStrategy.hash`
- Relative navigation with dot segment normalization (`./`, `../`)

</details>

<a id="install"></a>
<details open>
<summary><strong>Install</strong></summary>

Add to `pubspec.yaml`:

```yaml
dependencies:
  unrouter: ^0.5.0
```

</details>

<a id="quick-start"></a>
<details open>
<summary><strong>Quick start</strong></summary>

Declarative routing setup:

```dart
import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

final router = Unrouter(
  strategy: .browser,
  routes: const [
    Inlet(factory: HomePage.new),
    Inlet(path: 'about', factory: AboutPage.new),
    Inlet(
      factory: AuthLayout.new,
      children: [
        Inlet(path: 'login', factory: LoginPage.new),
        Inlet(path: 'register', factory: RegisterPage.new),
      ],
    ),
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

Use `Unrouter` directly as an entry widget (no `MaterialApp` required):

```dart
void main() => runApp(router);
```

</details>

<a id="routing-approaches"></a>
<details>
<summary><strong>Routing approaches</strong></summary>

### Declarative routing (central config)

```dart
Unrouter(routes: [
  Inlet(factory: HomePage.new),
  Inlet(path: 'about', factory: AboutPage.new),
])
```

### Widget-scoped routing (component-level)

```dart
Unrouter(child: Routes([
  Inlet(factory: HomePage.new),
  Inlet(path: 'about', factory: AboutPage.new),
]))
```

### Hybrid routing (declarative first, widget-scoped fallback)

```dart
Unrouter(
  routes: [Inlet(path: 'admin', factory: AdminPage.new)],
  child: Routes([Inlet(factory: HomePage.new)]),
)
```

Hybrid routing also enables partial matches where a declarative route handles
the prefix and a nested `Routes` widget handles the rest.

</details>

<a id="layouts-and-nested-routing"></a>
<details>
<summary><strong>Layouts and nested routing</strong></summary>

### Declarative layouts use `Outlet`

Layout and nested routes defined in `Unrouter.routes` must render an `Outlet`
to show matched children. Layout routes (`path == ''` with children) do not
consume a path segment.

```dart
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Outlet());
  }
}
```

### Widget-scoped nesting uses `Routes`

```dart
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Routes([
        Inlet(factory: ProductsList.new),
        Inlet(path: ':id', factory: ProductDetail.new),
        Inlet(path: 'new', factory: NewProduct.new),
      ]),
    );
  }
}
```

### State preservation

`unrouter` keeps matched pages in an `IndexedStack`. Leaf routes are keyed by
history index, while layout/nested routes are cached by route identity to keep
their state when switching between children. Prefer `const` routes to maximize
reuse.

</details>

<a id="route-patterns-and-matching"></a>
<details>
<summary><strong>Route patterns and matching</strong></summary>

### Pattern syntax

- Static: `about`, `users/profile`
- Params: `users/:id`, `:userId`
- Optional: `:lang?/about`, `users/:id/edit?`
- Wildcard: `files/*`, `*`

### Route kinds

- Index: `path == ''` and `children.isEmpty`
- Layout: `path == ''` and `children.isNotEmpty` (does not consume segments)
- Leaf: `path != ''` and `children.isEmpty`
- Nested: `path != ''` and `children.isNotEmpty`

### Partial matching

`Routes` performs greedy matching and allows partial matches so nested
component routes can continue to match the remaining path.

</details>

<a id="navigation-and-history"></a>
<details>
<summary><strong>Navigation and history</strong></summary>

### Imperative navigation (shared router instance)

```dart
router.navigate(.parse('/about'));
router.navigate(.parse('/login'), replace: true);
router.navigate.back();
router.navigate.forward();
router.navigate.go(-1);
```

### Navigation results

All navigation methods return `Future<Navigation>`. You can ignore the result
or await it when you need to know what happened.

```dart
final result = await router.navigate(.parse('/about'));
if (result case NavigationRedirected()) {
  // handle redirects
}
```

### Navigation from any widget

```dart
context.navigate(.parse('/users/123'));
context.navigate(.parse('edit'));        // /users/123/edit
context.navigate(.parse('./edit'));      // /users/123/edit
context.navigate(.parse('../settings')); // /users/123/settings
```

### Context extensions

```dart
context.navigate(.parse('/about'));
final router = context.router;
```

### Relative navigation

Relative paths append to the current location and normalize dot segments.
Query and fragment come from the provided URI and do not inherit.

### Building paths

`unrouter` uses `Uri` as the first-class navigation input. You can build paths
directly with templates or `Uri` helpers:

```dart
final id = '123';
final uri = Uri.parse('/users/$id');
final withQuery = Uri(path: '/users/$id', queryParameters: {'tab': 'profile'});
context.navigate(withQuery);
```

</details>

<a id="navigation-guards"></a>
<details>
<summary><strong>Navigation guards</strong></summary>

Guards let you intercept navigation and decide whether to allow, cancel, or
redirect.

```dart
final router = Unrouter(
  routes: const [Inlet(factory: HomePage.new)],
  guards: [
    (context) {
      if (!auth.isSignedIn) {
        return GuardResult.redirect(Uri.parse('/login'));
      }
      return GuardResult.allow;
    },
  ],
);
```

You can also attach guards to specific declarative routes:

```dart
final routes = [
  Inlet(
    path: 'admin',
    guards: [
      (context) => GuardResult.redirect(Uri.parse('/login')),
    ],
    factory: AdminPage.new,
  ),
];
```

Guards run in order: global guards first, then matched route guards from root
to leaf. The first non-allow result (cancel/redirect) short-circuits.

Guards receive a `GuardContext`:
- `to`: target `RouteInformation`
- `from`: previous `RouteInformation`
- `replace`: whether the navigation is a replace
- `redirectCount`: number of redirects so far

You can return a `Future<GuardResult>` for async checks, and configure
`maxRedirects` to prevent redirect loops.

</details>

<a id="route-blockers"></a>
<details>
<summary><strong>Route blockers</strong></summary>

Route blockers intercept back/pop navigation (history `go(-1)` / `back`) and
let you confirm before leaving the current route. They run from child to parent.

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RouteBlocker(
      onWillPop: (ctx) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        return result == true;
      },
      onBlocked: (ctx) {
        // Optional: record analytics or show a toast.
      },
      child: const SettingsForm(),
    );
  }
}
```

Notes:
- Blockers only apply to history back/pop (`navigate.back()` / `navigate.go(-1)`).
- `navigate.go(0)` also triggers blockers.
- `forward` does not trigger blockers.
- `Navigator.pop` is still handled by Flutter's `WillPopScope/PopScope`.

</details>

<a id="route-animations"></a>
<details>
<summary><strong>Route animations</strong></summary>

`unrouter` provides a per-route `AnimationController` you can use to animate
incoming/outgoing pages without relying on Navigator 1.0.

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animation = context.routeAnimation(
      duration: const Duration(milliseconds: 300),
    );
    return FadeTransition(
      opacity: animation,
      child: const Text('Profile'),
    );
  }
}
```

The controller runs forward on push/replace and reverse on pop. Pages that
don't call `routeAnimation` behave as they do today.
The default duration is 300ms unless you provide one.

</details>

<a id="navigator-10-compatibility"></a>
<details>
<summary><strong>Navigator 1.0 compatibility</strong></summary>

By default, `Unrouter` embeds a `Navigator` so APIs like `showDialog`,
`showModalBottomSheet`, `showGeneralDialog`, `showMenu`, and
`Navigator.push/pop/popUntil` work as expected.

```dart
final router = Unrouter(
  enableNavigator1: true, // default
  routes: const [Inlet(factory: HomePage.new)],
);
```

Set `enableNavigator1: false` to keep the Navigator 2.0-only behavior.

</details>

<a id="state-and-params"></a>
<details>
<summary><strong>State and params</strong></summary>

```dart
final state = context.routeState;
final uri = state.location.uri;
final params = state.params;        // merged params up to this level
final extra = state.location.state; // history entry state (if any)
```

You can also read fine-grained fields (with narrower rebuild scopes):

```dart
final location = context.location;
final matched = context.matchedRoutes;
final params = context.params;
final level = context.routeLevel;
final index = context.historyIndex;
final action = context.historyAction;
```

`RouteState.action` tells you whether the current navigation was a push,
replace, or pop, and `historyIndex` can be used to reason about stacked pages.

</details>

<a id="link-widget"></a>
<details>
<summary><strong>Link widget</strong></summary>

Basic link:

```dart
Link(
  to: Uri.parse('/about'),
  child: const Text('About'),
)
```

Custom link with builder:

```dart
Link(
  to: Uri.parse('/products/1'),
  state: {'source': 'home'},
  builder: (context, location, navigate) {
    return GestureDetector(
      onTap: () => navigate(),
      onLongPress: () => navigate(replace: true),
      child: Text('Product 1'),
    );
  },
)
```

</details>

<a id="web-url-strategy"></a>
<details>
<summary><strong>Web URL strategy</strong></summary>

- `strategy: .browser` uses path URLs like `/about` (requires server rewrites).
- `strategy: .hash` uses hash URLs like `/#/about` (no rewrites required).

`UrlStrategy` only applies to Flutter web. On native platforms
(Android/iOS/macOS/Windows/Linux), `Unrouter` uses `MemoryHistory` by default.
If you pass a custom `history`, `strategy` is ignored.

</details>

<a id="testing"></a>
<details>
<summary><strong>Testing</strong></summary>

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

Run tests:

```bash
flutter test
```

</details>

<a id="api-overview"></a>
<details>
<summary><strong>API overview</strong></summary>

- `Unrouter`: widget + `RouterConfig<RouteInformation>` (use directly or pass to `MaterialApp.router`)
- `Inlet`: route definition (index/layout/leaf/nested)
- `Outlet`: renders the next matched child route (declarative routes)
- `Routes`: widget-scoped route matcher
- `Navigate`: navigation interface (`context.navigate`)
- `Navigation`: async result returned by navigation methods
- `Guard` / `GuardResult`: navigation interception and redirects
- `RouteState`: current route state (read via `context.routeState`)
- `History` / `MemoryHistory`: injectable history (great for tests)
- `Link`: declarative navigation widget

</details>

<a id="example-app"></a>
<details>
<summary><strong>Example app</strong></summary>

See `example/` for a complete Flutter app showcasing routing patterns and
Navigator 1.0 APIs.

```bash
cd example
flutter run
```

</details>

<a id="troubleshooting"></a>
<details>
<summary><strong>Troubleshooting</strong></summary>

- `context.navigate` throws: ensure your widget is under an `Unrouter` router
  (either `MaterialApp.router(routerConfig: Unrouter(...))` or `runApp(Unrouter(...))`).
- `Routes` renders nothing: it must be a descendant of `Unrouter`.
- `showDialog` not working: keep `enableNavigator1: true` (default).
- Web 404 on refresh: use `strategy: .hash` or configure server rewrites.

</details>

<a id="contributing"></a>
<details>
<summary><strong>Contributing</strong></summary>

- Format: `dart format .`
- Tests: `flutter test`
- Open a PR with a clear description and a focused diff

</details>

<a id="license"></a>
<details>
<summary><strong>License</strong></summary>

MIT - see `LICENSE`.

</details>
