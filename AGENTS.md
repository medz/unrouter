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
dart test
dart format .
dart analyze
```

## Notes

- The temporary spec file is a local working artifact, not a committed project document unless the task explicitly calls for that.
- The red-to-green test step is important for behavior changes and bug fixes.
- If a task is docs-only, release-only, or otherwise not test-driven by nature, choose a lighter process intentionally instead of forcing the default flow.
- If formatting or analyzer scope can be narrowed safely, that is acceptable, but the final state should still be clean.
