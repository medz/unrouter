# flutter_unrouter storefront example

A full Flutter reference app for `flutter_unrouter` with a polished visual style
and production-like navigation flows.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## What this demo covers

- shell navigation with two branches (`Explore` and `Wallet`)
- typed query parsing (`/catalog?tab=...`)
- typed param parsing (`/products/:id`)
- async loader routes with `dataRoute<T, L>()`
- typed push/pop result flow (product quantity return)
- guard redirect to login for checkout
- guard block fallback when cart is empty
- runtime state usage through `context.unrouterAs<T>()`
- custom fallback UIs for loading / unknown / blocked / error

## Route map

- `/` dashboard
- `/catalog?tab=...` catalog lanes
- `/products/:id?panel=...` product detail (loader)
- `/cart` cart summary (loader)
- `/profile` session panel
- `/checkout` guarded checkout (loader)
- `/login?from=...` guard redirect target
