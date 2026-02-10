# nocterm_unrouter example

Complete terminal (TUI) storefront demo for `nocterm_unrouter`, including:

- shell branches (`Explore` + `Wallet`)
- typed query/path parsing (`CatalogRoute`, `ProductRoute`)
- data loaders (`Product`, `Cart`, `Checkout`)
- guard redirect + block (`/checkout`)
- typed `push`/`pop` result flow (`QuantityRoute`)
- unknown / blocked / loading / error fallback views
- keyboard-first navigation and actions

## Run

```bash
cd example
dart pub get
dart run bin/main.dart
```
