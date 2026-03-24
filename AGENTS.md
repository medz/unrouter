# AGENTS

## Default Implementation Flow

Unless the task is clearly docs-only or otherwise exempt, use this default execution flow for features, fixes, and implementation PRs:

1. investigate the relevant code, tests, docs, and upstream references
2. write a local temporary spec markdown file describing the intended change
3. add or update the relevant tests first
4. run the targeted tests and confirm they fail so the test is proven effective
5. implement the feature or fix
6. run the targeted tests again and confirm they pass
7. run the full test suite to check for regressions
8. run formatting
9. run the analyzer and ensure there are no issues
10. delete the local temporary spec markdown file before finishing

Default command sequence, adjusted as needed for the task:

```bash
dart test <targeted-tests>
flutter test <targeted-tests>
flutter test packages
dart format .
flutter analyze
```

## Notes

- The temporary spec file is a local working artifact, not a committed project document unless the task explicitly calls for that.
- The red-to-green test step is important for behavior changes and bug fixes.
- If a task is docs-only, release-only, or otherwise not test-driven by nature, choose a lighter process intentionally instead of forcing the default flow.
- If formatting or analyzer scope can be narrowed safely, that is acceptable, but the final state should still be clean.
- Root-level full test verification should use `flutter test packages` for the package suite in this workspace.
- Example apps are not part of the default CI test matrix; only smoke-test examples when a change specifically affects them.

## Commit and PR Rules

- Use Conventional Commits.
- Prefer these commit types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
- Use a scope when it improves clarity, especially in this workspace. Examples:
  - `feat(unrouter_core): add named route aliases`
  - `fix(flutter_unrouter): preserve route state on replace`
  - `docs(readme): clarify main package entrypoints`
- Use `BREAKING CHANGE:` in the footer when a commit introduces a breaking API or behavior change.
- PR titles should also use Conventional Commit style.
- Leave the PR body empty unless the PR directly resolves a tracked issue.
- If the PR resolves an issue, use `Resolves #<id>` as the full body.

## Changelog Rules

- Each publishable package keeps its own `CHANGELOG.md`.
- Do not maintain a root workspace `CHANGELOG.md`.
- A new package may start with a simple initial release entry.
- For any later release, rebuild the changelog entry from the actual diff between the previous released tag for that package and the new release target.
- Do not trust an existing unreleased draft blindly when preparing a real release.
- Optimize changelog entries for historical accuracy and user-facing impact, not for commit-by-commit narration.
- Group entries by user-facing area when that improves readability.

Recommended release entry structure:

```md
## X.Y.Z

### Highlights

Short release summary.

### Breaking Changes

- User-facing breaking changes only.

### What's New

- User-facing additions, fixes, or improvements.

### Migration Notes

- Concrete upgrade actions when needed.
```

## Release Rules

- This repository is a monorepo. Use package-specific tags, not bare version tags.
- Tag format must be `<package-name>-vX.Y.Z`. Examples:
  - `unrouter_core-v0.1.0`
  - `flutter_unrouter-v0.1.0`
  - `nocterm_unrouter-v0.1.0`
  - `unrouter-v0.12.0`
- Do not use bare tags such as `v0.1.0`.
- GitHub Release titles should use `<package-name> X.Y.Z`.
- The GitHub Release body should match the substantive content of that package's `CHANGELOG.md` entry for the same version.
- For GitHub Releases, prefer GitHub-native references such as `@medz` and `#39`.
- For `CHANGELOG.md`, prefer normal markdown links when explicit source attribution is useful.

## Release Preparation Checklist

Before publishing a package:

1. update that package's `pubspec.yaml`
2. finalize that package's `CHANGELOG.md`
3. verify docs and release-facing version wording for that package
4. run package-scoped tests
5. run package-scoped analyze
6. run `dart pub publish --dry-run` or `flutter pub publish --dry-run`
7. smoke-test related examples when the release changes runtime or routing behavior
8. create and push the package tag
9. publish to pub.dev
10. create the GitHub Release using the same release summary
