## Unreleased

### Breaking Changes

- `Navigate` and `Link` now use named arguments with `name` or `path`; `query`
  replaces `queryParameters` for navigation and URI generation.
- Guard APIs now use `RouteLocation` in `GuardContext` and accept named route or
  path data in `GuardResult.redirect`.

### Features

- **Named routes**: add `Inlet.name`, name-based navigation, and
  `Navigate.route(...)` for URI generation from names or path patterns.
- **Route location names**: expose the matched route name via `RouteLocation`
  (available from `context.location`).
- **Path patterns**: allow params, optional segments, and wildcards to be
  substituted when navigating or generating URIs.

### Improvements

- Route matching now prefers more specific routes (static > params > wildcard),
  with definition order as the tiebreaker.

### Fixes

- Encode dynamic path segments when building URIs and throw clear errors for
  missing wildcard params.
- Include route names in `RouteLocation` and `RouteState` equality/hashCode.

### Testing

- Added tests for named routes and specificity-based matching.

## 0.5.1 (2025-12-24)

### Improvements

- Refactor guard execution and history listener logic for clarity without
  behavior changes.

### Fixes

- Export `UrlStrategy` from the public API so `package:unrouter/unrouter.dart`
  can access it directly.

## 0.5.0 (2025-12-21)

### Features

- **Route blockers**: add `RouteBlocker` to intercept back/pop navigation with
  level-aware blocking and optional `onBlocked` callbacks (supports widget-scoped
  `Routes`).

## 0.4.0 (2025-12-20)

### Breaking Changes

- `Link.builder` constructor removed. Use `Link(builder: ...)` and provide
  either `child` or `builder` (not both).
- `Navigate` methods now return `Future<Navigation>`; await when you need to
  know whether navigation succeeded, redirected, or was cancelled.
- `UnrouterNavigationContext` extension renamed to `UnrouterBuildContext`.
- `RouterState` renamed to `RouteState`, and `RouterStateProvider` to `RouteStateScope`.
  Use `context.routeState` / `context.maybeRouteState` to read the state.
- Removed `Navigate.of`, `Unrouter.of`, and `RouteStateScope.of/maybeOf`.
  Use `context.navigate`, `context.router`, and `context.routeState` instead.
- `createHistory` is no longer exported; pass a `History` instance explicitly.

### Features

- **Navigation guards**: add `guards` and `maxRedirects` to intercept navigation
  (`allow`, `cancel`, `redirect`) across push/replace/pop and external route updates.
- **Route-level guards**: allow `Inlet.guards` to run per-route guards from
  root to leaf after global guards.
- **Route animations**: add `context.routeAnimation(...)` to access per-route
  animation controllers for push/replace/pop transitions.
- **Granular route state accessors**: add `context.location`,
  `context.matchedRoutes`, `context.params`, `context.routeLevel`,
  `context.historyIndex`, and `context.historyAction` for fine-grained rebuilds.

### Fixes

- Preserve cached stacked-route entries when their order changes, preventing
  unnecessary rebuilds in layout/nested routes.
- Pop navigation without guards now resolves in the same frame.

### Testing

- Added guard tests for async guards, error handling, short-circuiting, setNewRoutePath,
  pop redirects, and null-delta pop events.

## 0.3.0

### Features

- **Navigator 1.0 compatibility**: added `enableNavigator1` (default `true`) so APIs like `showDialog`, `showModalBottomSheet`, `showMenu`, and `Navigator.push/pop` work when using `Unrouter`.
- **Example updates**: the example app now demonstrates Navigator 1.0 APIs alongside existing routing patterns.

### Improvements

- `popRoute` now delegates to the embedded Navigator first (when enabled) before falling back to history navigation.
- Relative navigation now normalizes dot segments (`.` / `..`) and clamps above-root paths.

### Testing

- Added comprehensive widget tests covering Navigator 1.0 overlays, push/pop/popUntil, and nested Navigator behavior.
- Added tests for relative navigation dot-segment normalization.

## 0.2.0

### Breaking Changes

- **Navigation API refactored**: History navigation methods (`back()`, `forward()`, `go()`) are now accessed through `navigate` property
  - Before: `router.back()`
  - After: `router.navigate.back()`
- **Internal reorganization**: Removed `router_delegate.dart` file. The `Navigate` interface and router delegate logic have been consolidated into `router.dart`

### Features

- **Link widget**: Added declarative navigation with the new `Link` widget (#5)
  - Simple usage: `Link(to: Uri.parse('/about'), child: Text('About'))`
  - Advanced usage: `Link.builder` for custom gesture handling
  - Supports `replace` and `state` parameters
  - Automatic mouse cursor (click) and accessibility semantics (link role)
  - Example: Build navigation links without imperative callbacks
- **BuildContext extensions**: Added convenient extensions for navigation (#6)
  - Use `context.navigate` to access navigation methods from any widget
  - Use `context.router` to access the router instance
  - Example: `context.navigate(.parse('/about'))`
- **Better error messages**: `Navigate.of()` now throws helpful `FlutterError` with clear messages when:
  - Called outside a Router scope
  - Router delegate doesn't implement `Navigate`

### Improvements

- Changed `matchRoutes` parameter type from `List<Inlet>` to `Iterable<Inlet>` for better flexibility
- Updated examples to demonstrate new BuildContext extension usage
- Added comprehensive tests for context navigation features

### Migration Guide

Update your navigation code to use the new API:

```dart
// Before
router.back()
router.forward()
router.go(-1)

// After
router.navigate.back()
router.navigate.forward()
router.navigate.go(-1)

// Or use the new BuildContext extension
context.navigate.back()
```

## 0.1.1

- Update package description and add pub topics
- Remove routingkit dependency and format product card
- Format Dart code with dart format
