# Unrouter API Layering Strategy

Status: Phase 3 implemented (`unrouter.dart` is core-by-default)  
Scope: Public API organization and onboarding path  
Primary objective: keep a low floor for most apps while preserving a high
ceiling for advanced teams

## Current policy

Entry points are audience-oriented:

- `package:unrouter/unrouter.dart`: default core import
- `package:unrouter/machine.dart`: advanced machine command/action/event APIs
- `package:unrouter/devtools.dart`: inspector/bridge/panel/replay tooling

`unrouter.dart` is no longer an all-in umbrella.  
Advanced capabilities are opt-in through dedicated imports.

## Why this shape

1. New adopters should start with one obvious import path.
2. Power users should opt into machine/devtools only when needed.
3. The import path itself should communicate architectural layering.
4. Examples and docs should mirror the same default.

## Layer responsibilities

### Core (`unrouter.dart`)

- typed route graph (`route`, `routeWithLoader`, `shell`, `branch`)
- router runtime (`Unrouter`)
- route parser + guard + redirect + loader primitives
- context navigation (`context.unrouter`, `context.unrouterAs<R>()`)
- state snapshot/timeline primitives

### Machine (`machine.dart`)

- `UnrouterMachine` state/transition timeline
- `UnrouterMachineCommand` and `UnrouterMachineAction`
- action envelope/failure model and typed timeline payload API
- `context.unrouterMachine`, `context.unrouterMachineAs<R>()`

### Devtools (`devtools.dart`)

- `UnrouterInspector` and inspector widget
- bridge/sink stream model
- panel adapter/widget
- replay store/controller/persistence/comparison APIs

## Migration matrix

| Existing usage | Recommended import(s) |
| --- | --- |
| Core routing only | `unrouter.dart` |
| Core + machine dispatch | `unrouter.dart` + `machine.dart` |
| Core + inspector/replay tooling | `unrouter.dart` + `devtools.dart` |

## Rollout checkpoints

### Phase 1 completed

- Added layered public entry points (`core` / `machine` / `devtools`)
- Split `BuildContext` machine access into machine-only extension export

### Phase 2 completed

- Migrated docs/examples toward layered imports
- Added layered API inventory and DX scorecard (`docs/api_surface_review.md`)

### Phase 3 completed

- `unrouter.dart` switched to core-only default entrypoint
- test suite imports updated to explicit layer usage

## Success criteria

1. Most code snippets start with only `unrouter.dart`.
2. Machine/devtools symbols are never required for core flows.
3. Advanced usage remains fully public and type-safe.
4. Large internals keep moving from monolithic files toward module boundaries.

## Next actions

1. Continue internal decomposition of `navigation.dart`.
2. Keep devtools internals isolated from core runtime concerns.
3. Periodically re-score API floor/ceiling in `docs/api_surface_review.md`.
