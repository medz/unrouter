# Unrouter API Surface Review

This document audits the current public API through four lenses:

- low floor (easy first use)
- high ceiling (advanced power)
- developer friendliness
- long-term consistency with `docs/target_knowledge.md`

## Entrypoint layers

| Entrypoint | Audience | Role |
| --- | --- | --- |
| `package:unrouter/unrouter.dart` | default app developers | core routing entrypoint |
| `package:unrouter/machine.dart` | advanced orchestration users | command/action/event machine surface |
| `package:unrouter/devtools.dart` | diagnostics tooling users | inspector, bridge, panel, replay |

## Internal module layout

Current internal source grouping under `lib/src/`:

- `core/`: route model/definitions and redirect diagnostics primitives
- `runtime/`: controller, delegate, router runtime, and navigation machine host
- `devtools/`: inspector, bridge, panel, replay, and persistence tooling
- `platform/`: `RouteInformation` parser/provider and history integration glue

## API inventory (layered)

### Core (`unrouter.dart`)

Main symbols and families:

- route model: `RouteData`, `RouteRecord`, `RouteResolution`, `RouteResolutionType`
- route graph builders: `route`, `routeWithLoader`, `shell`, `branch`
- parser helpers and hook context: `RouteParserState`, `RouteHookContext`,
  `RouteExecutionSignal`, `RouteExecutionCancelledException`
- guards/redirect/loader: `RouteGuard`, `RouteGuardResult`, redirect loop policy
  and diagnostics callbacks/types
- router runtime: `Unrouter<R extends RouteData>`
- widget/runtime access: `UnrouterController`, `UnrouterScope`,
  `UnrouterBuildContextExtension`
- state introspection: `UnrouterResolutionState`, `UnrouterStateSnapshot`,
  `UnrouterStateTimelineEntry`, history composer request APIs

### Machine (`machine.dart`)

Main symbols and families:

- machine topology: `UnrouterMachine`, `UnrouterMachineState`,
  `UnrouterMachineTransitionEntry`
- machine identity model: `UnrouterMachineSource`, `UnrouterMachineEvent`,
  `UnrouterMachineEventGroup`, grouping extension
- command API: `UnrouterMachineCommand`
- declarative action API: `UnrouterMachineAction`, `UnrouterMachineNavigateMode`
- action-envelope API:
  `UnrouterMachineActionEnvelope`,
  `UnrouterMachineActionEnvelopeState`,
  `UnrouterMachineActionFailure`,
  `UnrouterMachineActionFailureCategory`,
  `UnrouterMachineActionRejectCode`
- typed timeline payload API:
  `UnrouterMachineTypedTransition` +
  typed payload variants (`actionEnvelope`, `navigation`, `route`, `controller`,
  `generic`)
- widget access: `UnrouterMachineBuildContextExtension`

### Devtools (`devtools.dart`)

Main symbols and families:

- inspector API: `UnrouterInspector`, `UnrouterInspectorWidget`
- streaming bridge API: `UnrouterInspectorBridge`, bridge config, sink types
- panel model + widget:
  `UnrouterInspectorPanelAdapter`,
  `UnrouterInspectorPanelWidget`
- replay workflow:
  `UnrouterInspectorReplayStore`,
  `UnrouterInspectorReplayController`,
  `UnrouterInspectorReplayPersistence`,
  compare/diff APIs

## Scorecard

| Dimension | Score | Notes |
| --- | --- | --- |
| Low floor | 8/10 | Layered entrypoints are in place; first-use docs still include advanced snippets in long sections. |
| High ceiling | 9/10 | Machine + replay + typed timeline give strong orchestration/observability coverage. |
| Developer friendliness | 8/10 | Typed APIs are strong; discoverability can improve with smaller focused examples. |
| API consistency | 8/10 | Core naming is stable; draft docs should stay synchronized with shipped action names. |

## Gaps to close

1. README currently mixes core and advanced usage in a single long navigation
   section, which raises first-read cognitive load.
2. Draft/advanced docs must continuously match the latest action/command naming
   to avoid onboarding confusion.

## Next actions

1. Split README usage into three focused sections:
   `Core quick actions`, `Machine orchestration`, `Devtools and replay`.
2. Keep examples layered:
   basic paths should import only `unrouter.dart`; debug and replay samples should
   opt into `machine.dart` and `devtools.dart`.
3. Track success with DX metrics:
   first-route setup time, first typed `push<T>()` success rate, and whether
   users can reach debug tooling without reading internals.
