# Unrouter example

This example simulates a small workspace app with nested layouts:

- Root shell with navigation rail.
- `projects` layout renders a list + details side-by-side via nested `RouterView`.
- `account` layout switches between overview/settings routes.
- `dashboard` shows a simple stats panel.

## Run

```sh
flutter run -d chrome lib/main.dart
```

Switch to hash URLs on web by changing `strategy: RouterUrlStrategy.hash` in `main.dart`.
