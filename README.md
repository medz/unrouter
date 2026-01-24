<p align="center">
  <img src="assets/brand.svg" width="120" alt="unrouter" />
  <h1 align="center">Unrouter</h1>
  <p align="center">
    <strong>The flexible Flutter router that adapts to your architecture</strong>
  </p>
</p>

<p align="center">
  <a href="https://pub.dev/packages/unrouter"><img src="https://img.shields.io/pub/v/unrouter.svg" alt="pub"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license"></a>
</p>

---

## Why Unrouter?

Unrouter is a **production-ready Flutter router** that gives you the freedom to choose how you define routes - **centrally, locally, or both** - while providing enterprise-grade features like browser-style history navigation, async guards, and seamless Navigator 1.0 compatibility.

**🎯 Built for real-world applications**
- ✅ **Routing flexibility**: Define routes centrally with `Inlet`, scope them to widgets with `Routes`, or mix both approaches
- ✅ **Web-first architecture**: Complete History abstraction with browser/hash URL strategies and state preservation
- ✅ **Type-safe navigation**: URI-based navigation with compile-time route matching
- ✅ **Zero boilerplate**: No code generation, no build runners - just clean, maintainable code
- ✅ **Navigator 1.0 compatible**: Works seamlessly with dialogs, bottom sheets, and existing Flutter APIs

**🚀 Battle-tested features**
- Declarative and imperative routing with hybrid support
- Nested routes, layouts, and infinite nesting depth
- Browser-style navigation (push/replace/back/forward/go)
- Async navigation results with `Navigation` futures
- Navigation guards with allow/cancel/redirect
- Route blockers for back/pop confirmation
- Relative navigation with dot segment normalization (`./ ../`)
- Per-route animations without Navigator 1.0 dependency
- Web URL strategies (browser/hash)
- Complete state restoration support

---

https://github.com/user-attachments/assets/e4f2d9d1-3fe2-4050-8b5b-1e1171027ba2

---

## Table of Contents

All sections below are collapsible. Expand the chapters you need.

- [Installation](#installation)
- [Quick start](#quick-start)
- [Why choose Unrouter?](#why-choose-unrouter)
- [Routing approaches](#routing-approaches)
- [File-based routing (CLI)](#file-based-routing)
- [Layouts and nested routing](#layouts-and-nested-routing)
- [Route patterns and matching](#route-patterns-and-matching)
- [Navigation and history](#navigation-and-history)
- [Navigation guards](#navigation-guards)
- [Route blockers](#route-blockers)
- [Route animations](#route-animations)
- [Navigator 1.0 compatibility](#navigator-10-compatibility)
- [State and params](#state-and-params)
- [Link widget](#link-widget)
- [Web URL strategy](#web-url-strategy)
- [State restoration](#state-restoration)
- [Testing](#testing)
- [API overview](#api-overview)
- [Comparison with other routers](#comparison-with-other-routers)
- [Example app](#example-app)
- [Migration guide](#migration-guide)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

<a id="installation"></a>
<details open>
<summary><strong>Installation</strong></summary>

Add to `pubspec.yaml`:

```yaml
dependencies:
  unrouter: ^0.5.1
```

Or run:

```bash
flutter pub add unrouter
```

No build runners or code generation required.

</details>

---

<a id="quick-start"></a>
<details open>
<summary><strong>Quick start</strong></summary>

### Minimal setup (3 lines)

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
// Anywhere in your widget tree
context.navigate(path: '/about');
context.navigate(path: '/users/123');
context.navigate.back();

// Relative navigation
context.navigate(path: 'edit');         // /users/123/edit
context.navigate(path: './edit');       // /users/123/edit
context.navigate(path: '../settings');  // /users/settings
```

</details>

---

<a id="why-choose-unrouter"></a>
<details open>
<summary><strong>Why choose Unrouter?</strong></summary>

### 🎨 Routing flexibility

Unlike routers that force you into a single routing paradigm, Unrouter lets you choose what works best for each part of your app:

- **Declarative routing**: Define routes centrally in `Unrouter.routes` for full application structure
- **Widget-scoped routing**: Use `Routes` widget for component-level routes and prototyping
- **Hybrid routing**: Mix both approaches - perfect for incremental adoption or progressive routing

```dart
// Declarative routes for main structure
Unrouter(
  routes: const [
    Inlet(path: 'admin', factory: AdminPage.new),
  ],
  // Widget-scoped routes for dynamic pages
  child: Routes([
    Inlet(factory: HomePage.new),
  ]),
)
```

### 🌐 Superior web support

Unrouter provides the most complete web routing implementation in Flutter:

- **History abstraction**: Full browser history API (`push/replace/back/forward/go`) with state support
- **URL strategies**: Both browser (`/about`) and hash (`/#/about`) modes
- **State preservation**: Attach arbitrary state to history entries
- **Deep linking**: Full support for browser forward/back buttons
- **Server rewrites**: Hash mode requires zero server configuration

```dart
// Browser-style navigation
router.navigate(path: '/about');
router.navigate.back();
router.navigate.forward();
router.navigate.go(-2);  // Go back 2 entries
```

### 🔒 Type-safe without code generation

URI-based navigation with compile-time safety and zero build steps:

```dart
final id = '123';
final uri = Uri(path: '/users/$id', queryParameters: {'tab': 'profile'});
context.navigate(path: uri.toString());

// Or with params and patterns
context.navigate(path: '/users/:id', params: {'id': id});
```

### 🎯 Zero boilerplate

No annotations, no code generation, no build runners. Just pure Dart code:

```dart
// That's it. Really.
Inlet(path: 'users/:id', factory: UserDetailPage.new)
```

### 🔌 Navigator 1.0 compatible

Works seamlessly with existing Flutter APIs (enabled by default):

```dart
showDialog(context: context, builder: (context) => AlertDialog(...));
showModalBottomSheet(context: context, builder: (context) => ...);
Navigator.of(context).push(MaterialPageRoute(...));
```

</details>

---

<a id="routing-approaches"></a>
<details open>
<summary><strong>Routing approaches</strong></summary>

Unrouter supports three routing patterns. Choose what fits your architecture.

### 1. Declarative routing (recommended for production)

Define all routes centrally in `Unrouter.routes`:

```dart
Unrouter(
  routes: const [
    Inlet(factory: HomePage.new),
    Inlet(path: 'about', factory: AboutPage.new),
    Inlet(
      path: 'products',
      factory: ProductsLayout.new,
      children: [
        Inlet(factory: ProductsList.new),
        Inlet(path: ':id', factory: ProductDetail.new),
      ],
    ),
  ],
)
```

**Benefits**:
- Full application structure visible at a glance
- Easy to manage guards and redirects
- Perfect for large applications

### 2. Widget-scoped routing (perfect for PoC)

Use the `Routes` widget to define routes locally in components:

```dart
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Routes(const [
        Inlet(factory: ProductsList.new),
        Inlet(path: ':id', factory: ProductDetail.new),
        Inlet(path: 'new', factory: NewProduct.new),
      ]),
    );
  }
}
```

**Benefits**:
- Routes defined next to the components that use them
- Great for prototyping and temporary pages
- No need to touch central route configuration

### 3. Hybrid routing (best of both worlds)

Combine declarative and widget-scoped routing:

```dart
Unrouter(
  routes: const [
    Inlet(path: 'admin', factory: AdminPage.new),
    // This declarative route uses Routes widget internally
    Inlet(path: 'products', factory: ProductsPage.new),
  ],
  // Fallback to widget-scoped routes
  child: Routes([
    Inlet(factory: HomePage.new),
  ]),
)
```

**Benefits**:
- Main routes centralized, component routes localized
- Incremental adoption path
- Progressive routing for complex UIs

### Which approach to use?

| Scenario | Recommended Approach |
|----------|---------------------|
| Production applications | Declarative routing |
| Prototyping/PoC | Widget-scoped routing |
| Large apps with many features | Hybrid routing |
| Component libraries | Widget-scoped routing |
| Temporary verification pages | Widget-scoped routing |

</details>

---

<a id="file-based-routing"></a>
<details open>
<summary><strong>File-based routing (CLI)</strong></summary>

Create a `unrouter.config.dart` file in your project root (the CLI scans
upward from the current working directory to find it). The CLI reads this file
without executing it.

```dart
// unrouter.config.dart
const pagesDir = 'lib/pages';
const output = 'lib/routes.g.dart';
```

Notes:
- Both values are optional.
- Paths can be absolute or relative to `unrouter.config.dart`.
- CLI flags (`--pages`, `--output`) override the config file.
- You can scaffold the config with `unrouter init`.

</details>

---

<a id="layouts-and-nested-routing"></a>
<details open>
<summary><strong>Layouts and nested routing</strong></summary>

Unrouter supports unlimited nesting depth with two route types: **layout routes** and **nested routes**.

### Layout routes (path-less wrappers)

Layout routes have `path == ''` with children. They wrap child routes without consuming a path segment:

```dart
Inlet(
  factory: AuthLayout.new,  // No path - wraps children
  children: [
    Inlet(path: 'login', factory: LoginPage.new),      // Matches /login
    Inlet(path: 'register', factory: RegisterPage.new), // Matches /register
  ],
)
```

**Layout implementation**:

```dart
class AuthLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(...),
        child: const Outlet(),  // Child routes render here
      ),
    );
  }
}
```

### Nested routes (path + children)

Nested routes have `path != ''` with children. They consume a path segment and render children:

```dart
Inlet(
  path: 'users',
  factory: UsersLayout.new,
  children: [
    Inlet(factory: UsersIndexPage.new),        // Matches /users
    Inlet(path: ':id', factory: UserDetailPage.new),  // Matches /users/123
  ],
)
```

**Nested route implementation**:

```dart
class UsersLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: const Outlet(),  // Index or detail page renders here
    );
  }
}
```

### Widget-scoped nesting

Use `Routes` widget for component-level nesting:

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(),
          Expanded(
            child: Routes(const [
              Inlet(factory: OverviewPanel.new),
              Inlet(path: 'analytics', factory: AnalyticsPanel.new),
              Inlet(path: 'settings', factory: SettingsPanel.new),
            ]),
          ),
        ],
      ),
    );
  }
}
```

### Infinite nesting depth

Routes can nest as deeply as needed:

```dart
Inlet(
  path: 'settings',
  factory: SettingsLayout.new,
  children: [
    Inlet(
      path: 'account',
      factory: AccountLayout.new,
      children: [
        Inlet(
          path: 'security',
          factory: SecurityLayout.new,
          children: [
            Inlet(path: 'two-factor', factory: TwoFactorPage.new),
          ],
        ),
      ],
    ),
  ],
)
// Matches: /settings/account/security/two-factor
```

### State preservation

Unrouter automatically preserves page state:

- **Leaf routes**: Keyed by history index (recreated on back/forward)
- **Layout routes**: Cached by route identity (preserved when switching children)

Use `const` constructors to maximize layout reuse:

```dart
Inlet(
  path: 'users',
  factory: UsersLayout.new,  // ✅ Same instance reused
  children: [...],
)
```

</details>

---

<a id="route-patterns-and-matching"></a>
<details open>
<summary><strong>Route patterns and matching</strong></summary>

Unrouter supports flexible route patterns for static paths, parameters, optionals, and wildcards.

### Pattern syntax

| Pattern | Example | Matches | Params |
|---------|---------|---------|--------|
| Static | `about` | `/about` | `{}` |
| Static nested | `users/profile` | `/users/profile` | `{}` |
| Parameter | `users/:id` | `/users/123` | `{id: '123'}` |
| Parameter | `:userId` | `/abc` | `{userId: 'abc'}` |
| Optional | `:lang?/about` | `/about` or `/en/about` | `{}` or `{lang: 'en'}` |
| Optional suffix | `users/:id/edit?` | `/users/123` or `/users/123/edit` | `{id: '123'}` |
| Wildcard | `files/*` | `/files/a/b/c` | `{}` |
| Wildcard | `*` | `/anything/at/all` | `{}` |

### Route kinds

```dart
// Index route: empty path, no children
Inlet(factory: HomePage.new)  // Matches /

// Layout route: empty path, has children (does not consume segments)
Inlet(
  factory: AuthLayout.new,
  children: [
    Inlet(path: 'login', factory: LoginPage.new),  // Matches /login
  ],
)

// Leaf route: has path, no children
Inlet(path: 'about', factory: AboutPage.new)  // Matches /about

// Nested route: has path, has children
Inlet(
  path: 'users',
  factory: UsersLayout.new,
  children: [
    Inlet(factory: UsersIndex.new),  // Matches /users
  ],
)
```

### Matching order

Routes match by specificity (static segments > params > wildcard). If two
routes are equally specific, definition order breaks the tie:

```dart
routes: const [
  Inlet(path: 'users/new', factory: NewUserPage.new),     // ✅ Static wins
  Inlet(path: 'users/:id', factory: UserDetailPage.new),  // ✅ Param after
  Inlet(path: '*', factory: NotFoundPage.new),            // ✅ Wildcard last
]
```

### Partial matching

`Routes` widget performs greedy matching and allows partial matches so nested routes can continue matching:

```dart
// Declarative route: /products
Inlet(path: 'products', factory: ProductsPage.new)

// ProductsPage uses Routes for remaining segments
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Routes(const [
      Inlet(factory: ProductsList.new),           // Matches /products
      Inlet(path: ':id', factory: ProductDetail.new),  // Matches /products/123
    ]);
  }
}
```

### Parameter extraction

Access route parameters via `context.params` or `context.routeState.params`:

```dart
class UserDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final params = context.params;
    final userId = params['id'];  // From /users/:id

    return Text('User ID: $userId');
  }
}
```

</details>

---

<a id="navigation-and-history"></a>
<details open>
<summary><strong>Navigation and history</strong></summary>

Unrouter provides browser-style navigation with complete history control.

### Basic navigation

```dart
// Push new route
context.navigate(path: '/about');

// Replace current route
context.navigate(path: '/login', replace: true);

// Navigate back
context.navigate.back();

// Navigate forward
context.navigate.forward();

// Go to specific history offset
context.navigate.go(-2);  // Back 2 entries
context.navigate.go(1);   // Forward 1 entry
```

### Named routes

Give routes a `name` and navigate without hard-coded URIs:

```dart
final router = Unrouter(
  routes: const [
    Inlet(name: 'home', factory: HomePage.new),
    Inlet(name: 'userDetail', path: 'users/:id', factory: UserDetailPage.new),
  ],
);

// Navigate by name
context.navigate(name: 'home');
context.navigate(name: 'userDetail', params: {'id': '123'});

// Add query/fragment
context.navigate(
  name: 'userDetail',
  params: {'id': '123'},
  query: {'tab': 'profile'},
  fragment: 'top',
);

// Generate a URI for a named route
final uri = context.navigate.route(
  name: 'userDetail',
  params: {'id': '123'},
);

// Generate a URI from a path pattern
final profileUri = context.navigate.route(
  path: '/users/:id',
  params: {'id': '123'},
);
```

Route names must be unique within the route tree and are available only for
declarative routes (`Unrouter.routes`).
Optional params are omitted when not provided; optional static segments are
included when generating named routes.
When using optional segments in a path pattern, pass query values via the
`query` argument instead of embedding them in the path string.

### Navigation from shared router instance

```dart
final router = Unrouter(routes: const [...]);

router.navigate(path: '/about');
router.navigate.back();
```

### Relative navigation

Unrouter supports relative paths with dot segment normalization:

```dart
// Current URL: /users/123

context.navigate(path: 'edit');         // /users/123/edit
context.navigate(path: './edit');       // /users/123/edit
context.navigate(path: '../456');       // /users/456
context.navigate(path: '../../about');  // /about
```

**Important**: Query and fragment come from the new URI, not the current location:

```dart
// Current: /users/123?tab=profile#section

context.navigate(path: '../456');
// Result: /users/456 (no query/fragment)

context.navigate(path: '../456?tab=posts');
// Result: /users/456?tab=posts
```

### Building URIs

Use `Uri` class for type-safe navigation:

```dart
final userId = '123';

// String interpolation
context.navigate(path: '/users/$userId');

// Uri constructor
final uri = Uri(
  path: '/users/$userId',
  queryParameters: {'tab': 'profile', 'sort': 'name'},
);
context.navigate(path: uri.toString());  // /users/123?tab=profile&sort=name

// Pattern + params
context.navigate(path: '/users/:id', params: {'id': userId});
```

### Navigation results

All navigation methods return `Future<Navigation>` for awaitable results:

```dart
final result = await context.navigate(path: '/login');

switch (result) {
  case NavigationRedirected(:final to):
    print('Redirected to ${to.uri}');
  case NavigationSuccess():
    print('Navigation succeeded');
  case NavigationCancelled():
    print('Guard cancelled navigation');
}
```

### Context extensions

```dart
context.navigate(path: '/about');       // Navigate
context.navigate.back();                  // Back
context.navigate.forward();               // Forward
context.navigate.go(-1);                  // Go by delta

final router = context.router;            // Access router
final state = context.routeState;         // Current route state
final location = context.location;        // Current location
final name = context.location.name;       // Matched route name (if any)
final params = context.params;            // Route params
final index = context.historyIndex;       // History index
final action = context.historyAction;     // push/replace/pop
```

### History state

Attach arbitrary state to navigation entries:

```dart
// Navigate with state
context.navigate(path: '/product/123',
  state: {'source': 'home', 'campaign': 'summer-sale'},
);

// Read state
class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.routeState.location.state;
    final source = state?['source'];  // 'home'

    return Text('Referred from: $source');
  }
}
```

State is preserved across browser refresh on web platforms.

</details>

---

<a id="navigation-guards"></a>
<details open>
<summary><strong>Navigation guards</strong></summary>

Guards intercept navigation to allow, cancel, or redirect based on custom logic.

### Global guards

Applied to all navigation:

```dart
final router = Unrouter(
  routes: const [Inlet(factory: HomePage.new)],
  guards: [
    (context) {
      // Check authentication
      if (!auth.isSignedIn) {
        return GuardResult.redirect(path: '/login');
      }
      return GuardResult.allow;
    },
    (context) {
      // Check permissions
      if (!hasPermission(context.to.uri)) {
        return GuardResult.cancel;
      }
      return GuardResult.allow;
    },
  ],
);
```

### Route-specific guards

Applied only to specific routes:

```dart
Inlet(
  path: 'admin',
  guards: [
    (context) {
      if (!user.isAdmin) {
        return GuardResult.redirect(path: '/');
      }
      return GuardResult.allow;
    },
  ],
  factory: AdminPage.new,
)
```

### Guard execution order

Guards run in sequence:
1. Global guards (in definition order)
2. Matched route guards (from root to leaf)

First non-allow result (cancel/redirect) short-circuits.

### Guard context

Guards receive `GuardContext` with:

```dart
(GuardContext context) {
  final to = context.to;              // Target RouteInformation
  final from = context.from;          // Previous RouteInformation
  final replace = context.replace;    // Is replace navigation?
  final count = context.redirectCount; // Redirect count

  return GuardResult.allow;
}
```

### Async guards

Guards can return `Future<GuardResult>` for async checks:

```dart
guards: [
  (context) async {
    final user = await authService.getCurrentUser();
    if (user == null) {
      return GuardResult.redirect(path: '/login');
    }
    return GuardResult.allow;
  },
]
```

### Redirect loops

Configure `maxRedirects` to prevent infinite loops:

```dart
Unrouter(
  routes: const [...],
  guards: [...],
  maxRedirects: 5,  // Default: 10
)
```

When exceeded, navigation is cancelled.

### Guard results

```dart
GuardResult.allow                                // Allow navigation
GuardResult.cancel                               // Cancel navigation
GuardResult.redirect(path: '/login')        // Redirect to new route
```

### Real-world examples

**Authentication guard**:

```dart
GuardResult authGuard(GuardContext context) {
  if (!auth.isSignedIn) {
    return GuardResult.redirect(
      path: '/login',
      query: {'redirect': context.to.uri.path},
    );
  }
  return GuardResult.allow;
}
```

**Permission guard**:

```dart
GuardResult permissionGuard(GuardContext context) {
  final requiredRole = context.to.state?['role'];
  if (requiredRole != null && !user.hasRole(requiredRole)) {
    return GuardResult.cancel;
  }
  return GuardResult.allow;
}
```

**Feature flag guard**:

```dart
Future<GuardResult> featureFlagGuard(GuardContext context) async {
  final feature = context.to.state?['feature'];
  if (feature != null) {
    final enabled = await featureFlags.isEnabled(feature);
    if (!enabled) {
      return GuardResult.redirect(path: '/');
    }
  }
  return GuardResult.allow;
}
```

</details>

---

<a id="route-blockers"></a>
<details open>
<summary><strong>Route blockers</strong></summary>

Route blockers intercept back/pop navigation to confirm before leaving the current route.

### Basic blocker

```dart
class EditFormPage extends StatefulWidget {
  @override
  State<EditFormPage> createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  bool _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    return RouteBlocker(
      onWillPop: (ctx) async {
        if (!_hasUnsavedChanges) return true;

        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes.'),
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
      child: EditForm(
        onChanged: () => setState(() => _hasUnsavedChanges = true),
      ),
    );
  }
}
```

### Blocker with tracking

```dart
RouteBlocker(
  onWillPop: (ctx) async {
    final shouldPop = await _confirmDiscard();
    return shouldPop;
  },
  onBlocked: (ctx) {
    // Optional: track when user cancels navigation
    analytics.logEvent('form_exit_cancelled');
    _showToast('Changes not saved');
  },
  child: const FormContent(),
)
```

### Important notes

**What triggers blockers**:
- `context.navigate.back()`
- `context.navigate.go(-1)` or any negative delta
- `context.navigate.go(0)` (refresh with blocker check)
- Browser back button (web)
- Android back button

**What does NOT trigger blockers**:
- `context.navigate.forward()` or `navigate.go(1)` (positive delta)
- `context.navigate(path: '/path')` (new navigation)
- `Navigator.pop()` (handled by Flutter's PopScope/WillPopScope)

### Nested blockers

Blockers run from child to parent:

```dart
RouteBlocker(
  onWillPop: (ctx) async {
    print('Outer blocker');
    return true;
  },
  child: Column(
    children: [
      RouteBlocker(
        onWillPop: (ctx) async {
          print('Inner blocker');  // Runs first
          return true;
        },
        child: FormField(),
      ),
    ],
  ),
)
```

If inner blocker returns `false`, outer blocker never runs.

### Blocker context

```dart
onWillPop: (RouteBlockerContext ctx) async {
  final from = ctx.from;  // Current RouteInformation
  final to = ctx.to;      // Target RouteInformation (if any)

  // Decide based on context
  if (to?.uri.path == '/home') {
    return true;  // Allow navigation to home
  }

  return await _confirmDiscard();
}
```

</details>

---

<a id="route-animations"></a>
<details open>
<summary><strong>Route animations</strong></summary>

Unrouter provides per-route animations without Navigator 1.0 dependency.

### Basic animation

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

The animation controller:
- Runs **forward** on push/replace
- Runs **reverse** on pop
- Default duration: 300ms

### Custom transitions

```dart
class SlidingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.routeAnimation(
      duration: const Duration(milliseconds: 400),
    );

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: curved,
        child: Scaffold(...),
      ),
    );
  }
}
```

### Nested route animations

Animate only the inner route while keeping layout static:

```dart
class DashboardLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Layout has no animation
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Outlet(),  // Child routes animate independently
    );
  }
}

class AnalyticsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Only this panel animates
    final animation = context.routeAnimation();

    return FadeTransition(
      opacity: animation,
      child: const AnalyticsContent(),
    );
  }
}
```

### Conditional animations

```dart
class ConditionalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final shouldAnimate = state.location.state?['animate'] == true;

    if (!shouldAnimate) {
      return const PageContent();
    }

    final animation = context.routeAnimation();
    return FadeTransition(
      opacity: animation,
      child: const PageContent(),
    );
  }
}
```

### No animation

Pages that don't call `context.routeAnimation()` render immediately without transition.

</details>

---

<a id="navigator-10-compatibility"></a>
<details open>
<summary><strong>Navigator 1.0 compatibility</strong></summary>

Unrouter embeds a Navigator by default, making all Navigator 1.0 APIs work seamlessly.

### Enabled by default

```dart
final router = Unrouter(
  enableNavigator1: true,  // Default
  routes: const [Inlet(factory: HomePage.new)],
);
```

### Supported APIs

All standard Flutter overlay APIs work:

```dart
// Dialogs
showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);

// Bottom sheets
showModalBottomSheet(
  context: context,
  builder: (context) => BottomSheetContent(),
);

// General dialogs
showGeneralDialog(
  context: context,
  pageBuilder: (context, anim1, anim2) => CustomDialog(),
);

// Menus
showMenu(
  context: context,
  position: RelativeRect.fromLTRB(0, 0, 0, 0),
  items: [
    PopupMenuItem(child: Text('Item 1')),
  ],
);

// Date/time pickers
showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
);

// Imperative navigation
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => DetailPage()),
);
Navigator.of(context).pop();
```

### Disable if not needed

For Navigator 2.0-only behavior:

```dart
final router = Unrouter(
  enableNavigator1: false,
  routes: const [Inlet(factory: HomePage.new)],
);
```

This removes the embedded Navigator, making the app slightly more lightweight.

### WillPopScope/PopScope

Flutter's `WillPopScope` (or `PopScope` in Flutter 3.10+) still works for handling Android back button and `Navigator.pop()`:

```dart
WillPopScope(
  onWillPop: () async {
    // Handle Android back button
    return true;
  },
  child: Scaffold(...),
)
```

This is separate from Unrouter's `RouteBlocker`, which handles history navigation (`navigate.back()`).

</details>

---

<a id="state-and-params"></a>
<details open>
<summary><strong>State and params</strong></summary>

Access route state, parameters, and navigation metadata anywhere in the widget tree.

### Complete route state

```dart
class UserDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.routeState;

    final uri = state.location.uri;          // Current URI
    final params = state.params;             // Route params
    final extra = state.location.state;      // History state
    final action = state.action;             // push/replace/pop
    final index = state.index;               // History index
    final matched = state.matchedRoutes;     // Matched route chain

    return Text('User: ${params['id']}');
  }
}
```

### Fine-grained reads

For narrower rebuild scopes, use specific getters:

```dart
// Rebuilds only when location changes
final location = context.location;

// Rebuilds only when params change
final params = context.params;

// Rebuilds only when history index changes
final index = context.historyIndex;

// Rebuilds only when action changes (push/replace/pop)
final action = context.historyAction;

// Current route level in nested structure
final level = context.routeLevel;

// Matched routes from root to current
final matched = context.matchedRoutes;
```

### Route parameters

Extract parameters from dynamic routes:

```dart
// Route: users/:userId/posts/:postId

class PostDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final params = context.params;
    final userId = params['userId'];    // '123'
    final postId = params['postId'];    // '456'

    return Text('User $userId, Post $postId');
  }
}

// Navigating: /users/123/posts/456
```

### Query parameters

Access query parameters from URI:

```dart
class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uri = context.location.uri;
    final query = uri.queryParameters['q'];      // Search query
    final sort = uri.queryParameters['sort'];    // Sort order

    return Text('Search: $query, Sort: $sort');
  }
}

// Navigating: /search?q=flutter&sort=recent
```

### History state

Attach and read arbitrary state:

```dart
// Navigate with state
context.navigate(path: '/product/123',
  state: {
    'source': 'home',
    'referrer': 'banner',
    'campaign': 'summer-sale',
  },
);

// Read state
class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.routeState.location.state as Map?;
    final source = state?['source'];

    if (source == 'home') {
      // Track conversion from home page
      analytics.logEvent('product_view_from_home');
    }

    return ProductDetails();
  }
}
```

### History action

Determine navigation type:

```dart
class AnimatedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final action = context.historyAction;

    final animation = switch (action) {
      HistoryAction.push => slideInFromRight(),
      HistoryAction.pop => slideOutToRight(),
      HistoryAction.replace => fadeTransition(),
    };

    return AnimatedTransition(animation: animation, child: PageContent());
  }
}
```

### Nullable access

Use `maybeRouteState` to safely access state in widgets that might not be under a router:

```dart
final state = context.maybeRouteState;
if (state != null) {
  final params = state.params;
  // Use params
}
```

</details>

---

<a id="link-widget"></a>
<details open>
<summary><strong>Link widget</strong></summary>

The `Link` widget provides declarative navigation with customizable appearance.
Provide a route `name` or a `path`.

### Basic link

```dart
Link(
  path: '/about',
  child: const Text('About'),
)
```

Renders as a clickable widget. On web, right-click shows "Open in new tab".

### Link with state

```dart
Link(
  path: '/product/123',
  state: {'source': 'featured'},
  child: const Card(
    child: Text('Featured Product'),
  ),
)
```

### Custom link builder

For full control over gesture handling:

```dart
Link(
  name: 'productDetail',
  params: {'id': '123'},
  state: {'referrer': 'home'},
  builder: (context, location, navigate) {
    return GestureDetector(
      onTap: () => navigate(),
      onLongPress: () => navigate(replace: true),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  },
)
```

The builder receives:
- `context`: BuildContext
- `location`: Target RouteInformation
- `navigate`: Function to trigger navigation
  - `navigate()`: Normal push
  - `navigate(replace: true)`: Replace current route

### Relative links

```dart
// Current URL: /users/123

Link(
  path: 'edit',         // /users/123/edit
  child: const Text('Edit'),
)

Link(
  path: '../456',       // /users/456
  child: const Text('User 456'),
)
```

### Link with query parameters

```dart
Link(
  path: '/search',
  query: {'q': 'flutter', 'sort': 'recent'},
  child: const Text('Search Flutter'),
)
// Navigates to: /search?q=flutter&sort=recent
```

### Conditional navigation

```dart
Link(
  path: '/premium',
  builder: (context, location, navigate) {
    return ElevatedButton(
      onPressed: () {
        if (user.isPremium) {
          navigate();
        } else {
          _showUpgradeDialog();
        }
      },
      child: const Text('Premium Features'),
    );
  },
)
```

</details>

---

<a id="web-url-strategy"></a>
<details open>
<summary><strong>Web URL strategy</strong></summary>

Unrouter supports two URL strategies for web deployment.

### Browser strategy (path-based URLs)

```dart
Unrouter(
  strategy: .browser,  // Default on web
  routes: const [...],
)
```

**URLs**: `/about`, `/users/123`

**Pros**:
- Clean, SEO-friendly URLs
- Standard web convention

**Cons**:
- Requires server rewrites to handle deep links
- All routes must return `index.html`

**Server configuration**:

nginx:
```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

Apache (.htaccess):
```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
```

### Hash strategy (hash-based URLs)

```dart
Unrouter(
  strategy: .hash,
  routes: const [...],
)
```

**URLs**: `/#/about`, `/#/users/123`

**Pros**:
- Zero server configuration required
- Works with any static file server
- Great for GitHub Pages, Netlify, etc.

**Cons**:
- Less clean URLs
- Fragment not sent to server (analytics caveat)

### Custom history

For advanced use cases, inject a custom History implementation:

```dart
Unrouter(
  history: CustomHistory(),  // strategy is ignored
  routes: const [...],
)
```

### Platform behavior

| Platform | Default Strategy |
|----------|-----------------|
| Web | `.browser` |
| Android/iOS/macOS/Windows/Linux | MemoryHistory (in-memory) |

On native platforms, `strategy` is ignored and `MemoryHistory` is used by default.

</details>

---

<a id="state-restoration"></a>
<details open>
<summary><strong>State restoration</strong></summary>

Unrouter fully supports Flutter's state restoration for web and mobile apps.

### Enable restoration

State restoration is enabled by default with a restoration scope:

```dart
Unrouter(
  restorationScopeId: 'unrouter',  // Default
  routes: const [...],
)
```

This preserves:
- Current route path
- History stack
- Route parameters
- Navigation state

### Web behavior

On web, state restoration enables:
- Browser refresh preserves navigation stack
- Back/forward buttons work after refresh
- Deep links restore full app state

### Mobile behavior

On mobile (Android/iOS), state restoration enables:
- App state preserved across process death
- Route stack restored when app resumes
- Seamless user experience after background termination

### Custom restoration ID

Override the default ID if you have multiple routers:

```dart
Unrouter(
  restorationScopeId: 'main-router',
  routes: const [...],
)
```

### Disable restoration

Set to `null` to disable:

```dart
Unrouter(
  restorationScopeId: null,
  routes: const [...],
)
```

### RestorableRoutePath

For advanced cases, use `RestorableRoutePath` to customize serialization:

```dart
class CustomRestorableRoute extends RestorableRoutePath {
  @override
  RouteInformation createDefaultValue() {
    return RouteInformation(uri: Uri.parse('/'));
  }

  @override
  void didUpdateValue(RouteInformation? oldValue) {
    // Custom restoration logic
  }
}
```

</details>

---

<a id="testing"></a>
<details open>
<summary><strong>Testing</strong></summary>

Unrouter makes routing tests simple with `MemoryHistory`.

### Basic routing test

```dart
testWidgets('navigates to about page', (tester) async {
  final router = Unrouter(
    routes: const [
      Inlet(factory: HomePage.new),
      Inlet(path: 'about', factory: AboutPage.new),
    ],
    history: MemoryHistory(
      initialEntries: [RouteInformation(uri: Uri.parse('/'))],
    ),
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));

  expect(find.text('Home'), findsOneWidget);

  router.navigate(path: '/about');
  await tester.pumpAndSettle();

  expect(find.text('About'), findsOneWidget);
});
```

### Test initial route

```dart
testWidgets('starts at specific route', (tester) async {
  final router = Unrouter(
    routes: const [
      Inlet(factory: HomePage.new),
      Inlet(path: 'profile', factory: ProfilePage.new),
    ],
    history: MemoryHistory(
      initialEntries: [
        RouteInformation(uri: Uri.parse('/profile')),
      ],
    ),
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));

  expect(find.text('Profile'), findsOneWidget);
});
```

### Test navigation guards

```dart
testWidgets('guard redirects to login', (tester) async {
  var isAuthenticated = false;

  final router = Unrouter(
    routes: const [
      Inlet(factory: HomePage.new),
      Inlet(path: 'login', factory: LoginPage.new),
      Inlet(path: 'profile', factory: ProfilePage.new),
    ],
    guards: [
      (context) {
        if (context.to.uri.path == '/profile' && !isAuthenticated) {
          return GuardResult.redirect(path: '/login');
        }
        return GuardResult.allow;
      },
    ],
    history: MemoryHistory(),
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));

  router.navigate(path: '/profile');
  await tester.pumpAndSettle();

  expect(find.text('Login'), findsOneWidget);

  isAuthenticated = true;
  router.navigate(path: '/profile');
  await tester.pumpAndSettle();

  expect(find.text('Profile'), findsOneWidget);
});
```

### Test back navigation

```dart
testWidgets('back navigation works', (tester) async {
  final router = Unrouter(
    routes: const [
      Inlet(factory: HomePage.new),
      Inlet(path: 'about', factory: AboutPage.new),
    ],
    history: MemoryHistory(),
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));

  router.navigate(path: '/about');
  await tester.pumpAndSettle();
  expect(find.text('About'), findsOneWidget);

  router.navigate.back();
  await tester.pumpAndSettle();
  expect(find.text('Home'), findsOneWidget);
});
```

### Test route parameters

```dart
testWidgets('extracts route parameters', (tester) async {
  final router = Unrouter(
    routes: const [
      Inlet(path: 'users/:id', factory: UserDetailPage.new),
    ],
    history: MemoryHistory(
      initialEntries: [
        RouteInformation(uri: Uri.parse('/users/123')),
      ],
    ),
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));

  expect(find.text('User ID: 123'), findsOneWidget);
});
```

### Run tests

```bash
flutter test
flutter test test/navigation_test.dart
```

</details>

---

<a id="api-overview"></a>
<details>
<summary><strong>API overview</strong></summary>

### Core classes

| Class | Description |
|-------|-------------|
| `Unrouter` | Main router widget and `RouterConfig<RouteInformation>` |
| `Inlet` | Route definition (index/layout/leaf/nested) with optional name |
| `RouteLocation` | RouteInformation with an optional matched route name |
| `Outlet` | Renders next matched child route (for declarative routes) |
| `Routes` | Widget-scoped route matcher |
| `Link` | Declarative navigation widget |

### Navigation

| API | Description |
|-----|-------------|
| `Navigate` | Navigation interface with push/replace/back/forward/go + route URI builder |
| `context.navigate` | Navigate from any widget |
| `context.navigate.route(name: ..., ...)` | Generate a URI for a named route |
| `context.navigate.route(path: ..., ...)` | Generate a URI from a path pattern |
| `context.navigate.back()` | Go back in history |
| `context.navigate.forward()` | Go forward in history |
| `context.navigate.go(delta)` | Go by history offset |
| `router.navigate` | Navigate from router instance |

### Navigation results

| Type | Description |
|------|-------------|
| `Navigation` | Base type for navigation results |
| `NavigationSuccess` | Navigation succeeded |
| `NavigationCancelled` | Guard cancelled navigation |
| `NavigationRedirected` | Guard redirected to different route |

### Guards

| Type | Description |
|------|-------------|
| `Guard` | Guard function type |
| `GuardContext` | Context passed to guards (to/from/replace/redirectCount) |
| `GuardResult` | Guard decision (allow/cancel/redirect) |
| `GuardResult.allow` | Allow navigation |
| `GuardResult.cancel` | Cancel navigation |
| `GuardResult.redirect(name: ..., path: ...)` | Redirect to a named route or path |

### Blockers

| Type | Description |
|------|-------------|
| `RouteBlocker` | Widget to intercept back/pop |
| `RouteBlockerContext` | Context passed to blocker callback |
| `RouteBlockerCallback` | Callback type `Future<bool> Function(RouteBlockerContext)` |
| `RouteBlockedCallback` | Called when navigation is blocked |

### Route state

| API | Description |
|-----|-------------|
| `RouteState` | Current route state |
| `context.routeState` | Access full route state |
| `context.location` | Current RouteInformation |
| `context.params` | Route parameters |
| `context.historyIndex` | Current history index |
| `context.historyAction` | Current action (push/replace/pop) |
| `context.routeLevel` | Route level in nesting |
| `context.matchedRoutes` | Matched routes from root to current |

### History

| Class | Description |
|-------|-------------|
| `History` | Abstract history interface |
| `MemoryHistory` | In-memory history (for testing and native) |
| `BrowserHistory` | Browser history (web, browser strategy) |
| `HashHistory` | Hash history (web, hash strategy) |
| `HistoryEvent` | History change event |
| `HistoryAction` | Action type (push/replace/pop) |

### Route matching

| Type | Description |
|------|-------------|
| `MatchedRoute` | A matched route in the hierarchy |
| `RouteInformation` | Current location + state |

### URL Strategy

| Type | Description |
|------|-------------|
| `UrlStrategy` | Enum for URL strategies |
| `UrlStrategy.browser` | Path-based URLs `/about` |
| `UrlStrategy.hash` | Hash-based URLs `/#/about` |

### Context extensions

```dart
// Navigation
context.navigate(path: '/about')
context.navigate.back()
context.navigate.forward()
context.navigate.go(-1)

// Router access
context.router

// Route state (broad rebuild scope)
context.routeState
context.maybeRouteState

// Fine-grained access (narrow rebuild scope)
context.location
context.params
context.historyIndex
context.historyAction
context.routeLevel
context.matchedRoutes

// Animations
context.routeAnimation(duration: ...)
```

</details>

---

<a id="comparison-with-other-routers"></a>
<details>
<summary><strong>Comparison with other routers</strong></summary>

### Unrouter vs go_router

| Feature | Unrouter | go_router |
|---------|----------|-----------|
| **Route definition** | Dart classes (zero boilerplate) | String paths + GoRoute classes |
| **Code generation** | None | None |
| **Navigation API** | URI-based | String paths |
| **Routing flexibility** | Declarative, widget-scoped, hybrid | Declarative only |
| **History abstraction** | ✅ Complete (push/replace/back/forward/go) | Partial (no forward/go) |
| **Relative navigation** | ✅ Full support with dot segments | Limited |
| **Navigator 1.0 compat** | ✅ Built-in | ✅ Built-in |
| **Web URL strategies** | browser, hash | browser, hash |
| **State restoration** | ✅ Built-in | ✅ Built-in |
| **Guards** | Async with redirect | Async with redirect |
| **Nested routes** | Unlimited depth | Unlimited depth |
| **Type safety** | Runtime (URI-based) | Runtime (string-based) |
| **Learning curve** | Low | Medium |

**Use go_router if**: You prefer the official Google-backed solution with a large community.

**Use Unrouter if**: You want routing flexibility (declarative + widget-scoped), superior web support, or simpler API.

### Unrouter vs auto_route

| Feature | Unrouter | auto_route |
|---------|----------|-----------|
| **Route definition** | Dart classes | Annotations + code generation |
| **Code generation** | None | Required |
| **Type safety** | Runtime | Compile-time |
| **Boilerplate** | Minimal | High (annotations) |
| **Build time** | Fast | Slower (code gen) |
| **Routing flexibility** | Declarative, widget-scoped, hybrid | Declarative only |
| **Guards** | Async functions | Class-based guards |
| **IDE support** | Standard | Enhanced (generated code) |
| **Refactoring** | Manual | Better (type-safe) |

**Use auto_route if**: You need compile-time type safety and prefer generated route objects.

**Use Unrouter if**: You want zero code generation, faster builds, or routing flexibility.

### Unrouter vs beamer

| Feature | Unrouter | beamer |
|---------|----------|-----------|
| **Route definition** | Inlet classes | BeamLocation classes |
| **Nested routes** | Unlimited | Unlimited |
| **Guards** | Async with context | BeamGuard classes |
| **History control** | ✅ Full (back/forward/go) | Partial |
| **Relative navigation** | ✅ Full support | Limited |
| **Navigator 1.0 compat** | ✅ Built-in | ✅ Built-in |
| **Learning curve** | Low | Medium-High |

**Use beamer if**: You prefer location-based routing architecture.

**Use Unrouter if**: You want simpler API, better history control, or routing flexibility.

### Unrouter vs routemaster

| Feature | Unrouter | routemaster |
|---------|----------|-----------|
| **Route definition** | Inlet classes | Map-based configuration |
| **Guards** | Async functions | Guard callbacks |
| **Nested routes** | Unlimited | Unlimited |
| **Routing flexibility** | Declarative, widget-scoped, hybrid | Declarative only |
| **Web support** | Superior (History abstraction) | Standard |

**Use routemaster if**: You prefer map-based route configuration.

**Use Unrouter if**: You want superior web support or routing flexibility.

### Feature matrix

|  | Unrouter | go_router | auto_route | beamer | routemaster |
|--|----------|-----------|-----------|--------|-------------|
| **Zero code gen** | ✅ | ✅ | ❌ | ✅ | ✅ |
| **Widget-scoped routes** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Hybrid routing** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **History.forward()** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **History.go(delta)** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Relative navigation** | ✅ | Partial | ❌ | Partial | ❌ |
| **Route animations** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Async guards** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Route blockers** | ✅ | ❌ | ✅ | ❌ | ❌ |
| **Type safety** | Runtime | Runtime | Compile-time | Runtime | Runtime |

</details>

---

<a id="example-app"></a>
<details>
<summary><strong>Example app</strong></summary>

The `example/` directory contains a complete Flutter app demonstrating:

- ✅ Declarative routing with nested routes
- ✅ Layout routes and nested routes
- ✅ Widget-scoped routing with `Routes`
- ✅ Hybrid routing (declarative + widget-scoped)
- ✅ Dynamic route parameters
- ✅ Navigation guards
- ✅ Route animations (full-page and nested)
- ✅ Navigator 1.0 APIs (dialogs, bottom sheets, menus)
- ✅ Link widget for declarative navigation
- ✅ Relative navigation

### Run the example

```bash
cd example
flutter run -d chrome  # Web
flutter run            # Mobile/Desktop
```

### Example structure

```
example/
├── lib/
│   └── main.dart          # Complete routing demo
└── pubspec.yaml
```

The example showcases real-world patterns you can copy into your app.

</details>

---

<a id="migration-guide"></a>
<details>
<summary><strong>Migration guide</strong></summary>

### From go_router

**Route definition**:

```dart
// go_router
GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomePage(),
    ),
    GoRoute(
      path: '/users/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UserDetailPage(id: id);
      },
    ),
  ],
)

// Unrouter
Unrouter(
  routes: const [
    Inlet(factory: HomePage.new),
    Inlet(path: 'users/:id', factory: UserDetailPage.new),
  ],
)
```

**Navigation**:

```dart
// go_router
context.go('/users/123');
context.push('/about');

// Unrouter
context.navigate(path: '/users/123');
context.navigate(path: '/about');
```

**Parameters**:

```dart
// go_router
final id = GoRouterState.of(context).pathParameters['id'];

// Unrouter
final id = context.params['id'];
```

### From auto_route

**Route definition**:

```dart
// auto_route
@MaterialAutoRouter(
  routes: [
    AutoRoute(page: HomePage, initial: true),
    AutoRoute(page: UserDetailPage, path: '/users/:id'),
  ],
)
class AppRouter extends _$AppRouter {}

// Unrouter (no code generation)
final router = Unrouter(
  routes: const [
    Inlet(factory: HomePage.new),
    Inlet(path: 'users/:id', factory: UserDetailPage.new),
  ],
);
```

**Navigation**:

```dart
// auto_route
context.router.push(UserDetailRoute(id: '123'));

// Unrouter
context.navigate(path: '/users/123');
```

### From Navigator 1.0

**Route definition**:

```dart
// Navigator 1.0
MaterialApp(
  onGenerateRoute: (settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomePage());
      case '/about':
        return MaterialPageRoute(builder: (_) => AboutPage());
      default:
        return null;
    }
  },
)

// Unrouter
Unrouter(
  routes: const [
    Inlet(factory: HomePage.new),
    Inlet(path: 'about', factory: AboutPage.new),
  ],
)
```

**Navigation**:

```dart
// Navigator 1.0
Navigator.of(context).pushNamed('/about');
Navigator.of(context).pop();

// Unrouter
context.navigate(path: '/about');
context.navigate.back();
```

### Key differences

| Aspect | Other routers | Unrouter |
|--------|--------------|----------|
| **Routes location** | Centralized only | Centralized OR widget-scoped OR hybrid |
| **Code generation** | Often required | Never required |
| **Navigation input** | Strings or generated objects | URI |
| **History control** | Limited | Complete (back/forward/go) |
| **Relative paths** | Limited or none | Full support |

</details>

---

<a id="troubleshooting"></a>
<details>
<summary><strong>Troubleshooting</strong></summary>

### context.navigate throws exception

**Error**: `No Unrouter found in context`

**Solution**: Ensure your widget is a descendant of `Unrouter`:

```dart
// ✅ Correct
void main() => runApp(
  MaterialApp.router(
    routerConfig: Unrouter(routes: const [...]),
  ),
);

// ✅ Also correct
void main() => runApp(
  Unrouter(routes: const [...]),
);
```

### Routes widget renders nothing

**Error**: `Routes` doesn't display any content

**Solution**: `Routes` must be a descendant of `Unrouter`:

```dart
Unrouter(
  routes: const [
    Inlet(path: 'products', factory: ProductsPage.new),
  ],
)

// Inside ProductsPage
Routes(const [
  Inlet(factory: ProductsList.new),
])
```

### showDialog not working

**Error**: `No Navigator widget found`

**Solution**: Keep `enableNavigator1: true` (default):

```dart
Unrouter(
  enableNavigator1: true,  // ✅ Default, enables dialogs
  routes: const [...],
)
```

### Web 404 on refresh

**Error**: Server returns 404 when refreshing `/about`

**Solution**: Either:

1. Use hash strategy (no server config):
```dart
Unrouter(
  strategy: .hash,  // URLs: /#/about
  routes: const [...],
)
```

2. Configure server rewrites for browser strategy:

nginx:
```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

### Guards not firing

**Error**: Navigation guards don't run

**Solution**: Guards must return `GuardResult`:

```dart
// ❌ Wrong
guards: [
  (context) {
    if (!auth.isSignedIn) {
      // Missing return!
    }
  },
]

// ✅ Correct
guards: [
  (context) {
    if (!auth.isSignedIn) {
      return GuardResult.redirect(path: '/login');
    }
    return GuardResult.allow;
  },
]
```

### Route parameters are null

**Error**: `context.params['id']` is null

**Solution**: Check route pattern has `:id`:

```dart
// ❌ Wrong
Inlet(path: 'users/id', factory: UserDetailPage.new)

// ✅ Correct
Inlet(path: 'users/:id', factory: UserDetailPage.new)
```

### Back button doesn't work

**Error**: Android back button or browser back button doesn't navigate

**Solution**: Unrouter handles this by default. If it's not working:

1. Ensure you're not blocking with `WillPopScope` returning `false`
2. Check `RouteBlocker` isn't preventing navigation
3. Verify history has entries to go back to

### Outlet renders nothing

**Error**: `Outlet` doesn't show child routes

**Solution**: Ensure layout route has children:

```dart
// ❌ Wrong (no children)
Inlet(factory: Layout.new)

// ✅ Correct
Inlet(
  factory: Layout.new,
  children: [
    Inlet(path: 'child', factory: ChildPage.new),
  ],
)
```

</details>

---

<a id="contributing"></a>
<details>
<summary><strong>Contributing</strong></summary>

Contributions are welcome! Here's how to contribute:

### Development setup

```bash
git clone https://github.com/medz/unrouter.git
cd unrouter
flutter pub get
```

### Code style

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test
```

Follow `flutter_lints` rules (configured in `analysis_options.yaml`).

### Naming conventions

- Types: `UpperCamelCase`
- Variables/functions: `lowerCamelCase`
- Files: `snake_case.dart`

### Pull requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`flutter test`)
6. Format code (`dart format .`)
7. Commit with clear message (`git commit -m 'Add amazing feature'`)
8. Push to branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

### PR guidelines

- Keep changes focused and atomic
- Write clear commit messages (sentence case, imperative mood)
- Add tests for new features
- Update documentation for API changes
- Include example usage for new features
- Keep diffs small and reviewable

### Reporting issues

Open an issue on GitHub with:
- Clear description of the problem
- Minimal reproduction code
- Expected vs actual behavior
- Flutter version and platform

</details>

---

<a id="license"></a>
<details>
<summary><strong>License</strong></summary>

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2024 Seven Du

</details>

---

<p align="center">
  <sub>Built with ❤️ by <a href="https://github.com/medz">Seven Du</a></sub>
</p>
