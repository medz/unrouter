# Changelog

## 0.3.0

### What's New

- Add `useRouter(context)` helper to retrieve the active `Unrouter` instance
  from the nearest route scope. (#40)
- Bump `unrouter_core` dependency to `^0.2.0`.

## v0.2.0

**Migration guide**: See Migration note below.

### Highlights

Nocterm Unrouter 0.2.0 rebuilds the package on top of `unrouter_core` and
aligns the terminal API with the shared route-tree model used across the
workspace. This release replaces the old typed route-data adapter surface with
`createRouter`, `Inlet`, `RouterView`, and `Outlet`, adds route scope helpers
for terminal components, refreshes the Nocterm example app, and keeps guard
handling on the shared core runtime.

### Breaking Changes

- Routers are now created with `createRouter(routes: [...])` and `Inlet`
  declarations instead of `Unrouter<T>(routes: ...)`.
- The old typed route-data adapter surface from `0.1.x` is gone.
- The adapter no longer exposes the old runtime widget/controller API from the
  pre-core implementation.

### What's New

#### Route tree rendering

- Added `RouterView` to render the matched route chain in Nocterm apps.
- Added `Outlet` for nested terminal layouts backed by child routes.

#### Route scope and navigation

- Added route scope helpers such as `useRouteParams`, `useQuery`,
  `useLocation`, `useRouteState<T>`, and `useFromLocation`.
- Shared guard handling now comes from `unrouter_core`.

#### Examples and tests

- Added a refreshed Nocterm example app with nested docs routes, named profile
  navigation, history pop, and query/state inspection.
- Added adapter tests covering nested rendering and wildcard params.

### Migration note

- Replace `Unrouter<T>(routes: ...)` with `createRouter(routes: [...])`.
  Nocterm routes are now declared with `Inlet`, not the old typed route-data
  adapter helpers.
- Replace typed route-data parsing with direct path trees.

  Before:

  ```dart
  final router = Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (_, __) => const HomeView(),
      ),
    ],
  );
  ```

  After:

  ```dart
  final router = createRouter(
    routes: const [
      Inlet(path: '/', view: HomeView.new),
    ],
  );
  ```

- Replace the old runtime root widget with `RouterView(router: router)`.
- Replace shell-style parent layouts with nested `Inlet(children: [...])` plus
  `Outlet()` inside the parent component.
- Replace old scope/controller access with `useRouteParams`, `useQuery`,
  `useLocation`, `useRouteState<T>`, and `useFromLocation`.

### Full Changelog

- https://github.com/medz/unrouter/compare/nocterm_unrouter-v0.1.0...nocterm_unrouter-v0.2.0

## v0.1.0

**Migration guide**: Not required.

### Highlights

Nocterm Unrouter 0.1.0 introduced the first standalone Nocterm adapter for
Unrouter, pairing the original typed route-data model with a keyboard-first
terminal navigation runtime.

### Breaking Changes

- None.

### What's New

#### Initial adapter package

- Added the initial Nocterm adapter package for `unrouter`.
- Inherited the original core `Unrouter` controller directly and kept the
  adapter runtime thin.

#### Examples and tests

- Added a complete keyboard-first example with shell branches, guards,
  redirects, loaders, and typed navigation flows.
- Added functional runtime tests for scope/controller access, navigation
  behavior, fallback rendering, and lifecycle updates.
- Added default runtime error handling that renders a fallback error component
  when `onError` is not provided.

### Migration note

- No migration is required for the initial release.
