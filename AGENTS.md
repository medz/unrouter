# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds the public API (`unrouter.dart`) and platform helpers like `browser.dart`; implementation details live in `lib/src/`.
- `test/` contains Flutter tests (e.g., `*_test.dart` and `test/history/` for history behavior).
- `example/` is a runnable Flutter app that demonstrates package usage.
- `build/` is generated output (do not edit by hand).
- `pubspec.yaml`, `analysis_options.yaml`, and `CHANGELOG.md` capture package metadata, lint rules, and release notes.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter analyze` runs the analyzer with `flutter_lints`.
- `dart format .` applies standard Dart formatting (2-space indentation).
- `flutter test` runs the full test suite in `test/`.
- `cd example && flutter run` runs the sample app (use `-d chrome` for web).

## Coding Style & Naming Conventions
- Use the Dart formatter; avoid manual alignment or custom indentation.
- Follow `flutter_lints` as configured in `analysis_options.yaml`.
- Naming: `UpperCamelCase` for types, `lowerCamelCase` for variables/functions, and `snake_case.dart` for files.
- Keep the public surface in `lib/` lean; place internals under `lib/src/`.

## Testing Guidelines
- Tests use `flutter_test`; name files `*_test.dart`.
- Prefer focused unit tests and cover navigation/history edge cases.
- Run a single test file with `flutter test test/navigation_test.dart`.

## Documentation & Changelog Requirements
- When the user confirms a fix or feature is complete, add an entry to the next unreleased version in `CHANGELOG.md`.
- Any feature development must update the relevant documentation (`README.md`, `example/`, or other docs as applicable).
- If reworking an existing feature, refresh its docs to match the new behavior.
- If the work happens in an unreleased version, ensure the changelog entry is updated alongside the doc changes.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, sentence case (e.g., “Add Link widget for declarative navigation (#9)”, “Bump version to 0.2.0”).
- PRs should include a concise description, rationale, and testing notes; keep diffs focused.
- Include screenshots/recordings for UI changes in `example/` when applicable.
- If changes affect public API or behavior, update `CHANGELOG.md`.
