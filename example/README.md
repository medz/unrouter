# Example App

This example demonstrates Unrouter's file-based routing plus Navigator 1.0
compatibility. Pages live in `lib/pages`, and the generated routes live in
`lib/routes.dart`.

## Update routes

If you change files under `lib/pages`, regenerate routes:

```sh
dart run unrouter generate --pages lib/pages --output lib/routes.dart
```

## Running

```sh
flutter pub get
flutter run -d chrome
```
