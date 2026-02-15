# Unrouter Example App

Runnable Flutter example app for `unrouter`, with two scenarios in one project.

## Run

```bash
cd example
flutter pub get
flutter run
```

## Scenarios

- `Quickstart`: minimal setup with `createRouter`, `createRouterConfig`, nested layout, `Link`, and `useRouter().push(...)`.
- `Advanced`: guards (`allow/block/redirect`), named/path navigation, query override, navigation state, `Link` options, nested layouts, and `defineDataLoader`.

## Key Files

- `lib/main.dart`: launcher app and scenario entry point.
- `lib/home/example_home_view.dart`: home screen that opens each scenario.
- `lib/quickstart/quickstart_app.dart`: quickstart router + `MaterialApp.router`.
- `lib/quickstart/quickstart_views.dart`: quickstart views (`const Outlet()` in layout).
- `lib/advanced/advanced_app.dart`: advanced router + guards.
- `lib/advanced/advanced_views.dart`: advanced views and navigation actions.
- `lib/advanced/data_loader_demo.dart`: `defineDataLoader` success/error/refresh demo.
