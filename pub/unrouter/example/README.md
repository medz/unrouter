# unrouter core complete Dart example

This example is a pure Dart application that demonstrates a full routing flow
using `unrouter` core runtime only (no Flutter/Jaspr adapters).

## Run

```bash
dart run bin/main.dart
```

## What it demonstrates

- typed path + query parsing with `RouteState.params/query`
- route-level redirect (`/` -> `/home`)
- legacy URL redirect (`/p/:id` -> `/products/:id`)
- async loader with `dataRoute<T, L>()`
- guard redirect flow (`/checkout` -> `/login?from=...`)
- guard block fallback behavior (`/beta`)
- runtime controller APIs (`sync`, `go`, `push`, `pop`, `href`, `cast`)
- state stream observation (`controller.states`)
- redirect loop diagnostics (`RedirectDiagnostics`)

## Scenario overview

The script runs these steps in sequence:

1. bootstrap through external URL sync
2. parse typed query route (`/search?q=...`)
3. push legacy product URL and follow redirect + loader
4. complete typed push result with `pop(result)`
5. attempt checkout and get redirected to login
6. sign in and continue to checkout
7. attempt blocked route and verify fallback behavior
8. sync to unmatched URI
9. trigger redirect loop and print diagnostics
