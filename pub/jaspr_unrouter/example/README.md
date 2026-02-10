# jaspr_unrouter example

Complete storefront demo for `jaspr_unrouter`, including:

- shell branches (`Explore` + `Wallet`)
- typed query parsing (`CatalogRoute(tab)`)
- typed path parsing (`ProductRoute(id, panel)`)
- data loaders (`Product`, `Cart`, `Checkout`)
- guard redirect + block (`/checkout`)
- typed `push`/`pop` result flow (`QuantityRoute`)
- unknown / blocked / loading / error fallback UIs

## Run

```bash
cd example
dart pub get
dart run lib/main.dart
dart test
```
