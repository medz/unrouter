# Changelog

## 0.2.1

### What's New

- Internal refactor: extract `_ViewHost` as a shared stateful widget to reduce
  duplication between the router delegate and outlet rendering paths.
- Bump `unrouter_core` dependency to `^0.2.0`.

## v0.2.0

**Migration guide**: See Migration note below.

### Highlights

Flutter Unrouter 0.2.0 rebuilds the package on top of `unrouter_core` and
aligns the Flutter API with the new shared route-tree model. This release
replaces the old typed route-data adapter surface with `createRouter`,
`Inlet`, `Outlet`, and `createRouterConfig`, refreshes the Flutter example app,
and expands test coverage around links, route scopes, data loaders, and
history-driven router updates.

### Breaking Changes

- Routers are now created with `createRouter(routes: [...])` and `Inlet`
  declarations instead of `Unrouter<T>(routes: ...)`.
- `MaterialApp.router` now uses `createRouterConfig(router)` instead of passing
  the router directly as `routerConfig`.
- The old `route()`, `dataRoute()`, `branch()`, and `shell()` Flutter adapter
  helpers are gone.
- The adapter no longer exposes the old generic `Unrouter<T>` surface from
  `0.1.x`.

### What's New

#### Flutter Router integration

- Added `createRouterConfig(router)` and the rebuilt route-information provider,
  parser, delegate, and back-button integration for Flutter apps.

#### Nested routing UI

- Added `Outlet`-driven nested rendering for parent and child route layouts.
- Added `RouteScopeProvider` plus route hooks such as `useRouteParams`,
  `useQuery`, `useLocation`, `useRouteState<T>`, and `useFromLocation`.
- Added `Link` for declarative push and replace navigation inside widget trees.

#### Data loading, examples, and tests

- Added `defineDataLoader` for context-aware async loading in Flutter widgets.
- Added a refreshed workspace Flutter example with quick-start and advanced
  flows.
- Expanded test coverage for router delegation, route scopes, links, outlet
  rendering, history pop handling, and data loaders.

### Migration note

- Replace `Unrouter<T>(routes: ...)` with `createRouter(routes: [...])`.
  Flutter routes are now declared with `Inlet`, not `route()`, `dataRoute()`,
  `branch()`, or `shell()`.
- Replace typed route-data parsing with direct path trees.

  Before:

  ```dart
  final router = Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (_, __) => const HomePage(),
      ),
    ],
  );
  ```

  After:

  ```dart
  final router = createRouter(
    routes: [
      Inlet(path: '/', view: HomePage.new),
    ],
  );
  ```

- Replace `MaterialApp.router(routerConfig: router)` with
  `MaterialApp.router(routerConfig: createRouterConfig(router))`.
- Replace shell layouts with nested `Inlet(children: [...])` plus `Outlet()`
  inside the parent view.
- Replace old scope access with `useRouter`, `useRouteParams`, `useQuery`,
  `useLocation`, `useRouteState<T>`, and `useFromLocation`.

### Full Changelog

- https://github.com/medz/unrouter/compare/flutter_unrouter-v0.1.0...flutter_unrouter-v0.2.0

## v0.1.0

**Migration guide**: Not required.

### Highlights

Flutter Unrouter 0.1.0 introduced the first standalone Flutter adapter for
Unrouter, pairing the original typed route-data model with Flutter Router
integration and a full example app.

### Breaking Changes

- None.

### What's New

#### Initial adapter package

- Added the initial Flutter adapter package for `unrouter`.
- Kept the adapter runtime lean by inheriting the original core `Unrouter`
  controller directly.

#### Examples and tests

- Added a complete Flutter example covering shell navigation, guards,
  redirects, loader routes, and typed push/pop flows.
- Added functional runtime and widget tests for route-information sync, scope
  helpers, delegate fallbacks, and shell branch behavior.

### Migration note

- No migration is required for the initial release.
