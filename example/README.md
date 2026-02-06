# unrouter_example

Runnable reference app for the slimmed `unrouter` API.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## Route map

- `/`: home page
- `/users/:id`: typed push result demo
- `/settings`: basic navigation demo
- `/secure`: guard-protected route
- `/login?from=...`: redirect target for secure guard

## Core capabilities covered

- Typed routes via `RouteData` + `route<T>()`
- `context.unrouter` navigation: `go`, `push`, `back`, `pop`
- Typed push result delivery (`push<T>()` + `pop(result)`)
- Guard + redirect flow with sign-in continuation
- Machine envelope state via `dispatchActionEnvelope(...)`
