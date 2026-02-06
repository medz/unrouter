# Unrouter Machine Action Envelope Schema

This document defines the machine action-envelope payload contract used by
inspector/bridge/replay tooling.

## Scope

- Produced by `dispatchActionEnvelope<T>()`.
- Emitted into machine transitions where `event == actionEnvelope`.
- Intended for diagnostics, replay validation, and cross-version tooling.

## Envelope Versions

- `schemaVersion = 2`
- `eventVersion = 2`
- `producer = "unrouter.machine"`

Compatibility gate:

- Minimum compatible schema version: `1`
- Minimum compatible event version: `1`
- Runtime helpers:
  - `UnrouterMachineActionEnvelope.isSchemaVersionCompatible(version)`
  - `UnrouterMachineActionEnvelope.isEventVersionCompatible(version)`

## Canonical Envelope Shape

```json
{
  "schemaVersion": 2,
  "eventVersion": 2,
  "producer": "unrouter.machine",
  "state": "rejected",
  "event": "back",
  "isAccepted": false,
  "isRejected": true,
  "isDeferred": false,
  "isCompleted": false,
  "rejectCode": "noBackHistory",
  "rejectReason": "No history entry is available for back navigation.",
  "failure": {
    "code": "noBackHistory",
    "message": "No history entry is available for back navigation.",
    "category": "history",
    "retryable": true,
    "metadata": {}
  },
  "hasValue": true,
  "valueType": "bool"
}
```

## Machine Transition Payload Mirrors

When envelope transitions are recorded, payload includes:

- `actionEnvelopeSchemaVersion`
- `actionEnvelopeEventVersion`
- `actionEnvelopeProducer`
- `actionEnvelopePhase` (`dispatch` or `settled`)
- `actionEnvelope` (full envelope JSON)
- `actionFailure` (structured failure mirror, nullable)
- `actionFailureCategory` (nullable)
- `actionFailureRetryable` (nullable)
- Legacy compatibility mirrors:
  - `actionRejectCode`
  - `actionRejectReason`

## Rejected Envelope Failure Contract

For rejected envelopes in schema `>= 2`, consumers should prefer `failure`:

- `code`: stable machine reject code
- `message`: user/developer-readable reason
- `category`: semantic class (`unknown`, `history`, `shell`, `asynchronous`)
- `retryable`: whether retry is likely meaningful
- `metadata`: optional structured detail map

`rejectCode` and `rejectReason` are retained for older tooling.

## Consumer Parsing Rules

1. Parse versions first. If version is outside compatible range, treat entry as
   unsupported and degrade gracefully.
2. Prefer `failure` over legacy reject fields when both exist.
3. Ignore unknown keys to stay forward-compatible.
4. Do not require ordering of keys or extra payload fields.
5. For deferred actions, expect a follow-up `settled` phase transition.

## Typed Runtime Projection

For strongly typed consumers, transition entries expose typed projections:

- `UnrouterMachineTransitionEntry.typed`
- `UnrouterMachine.typedTimeline`
- `UnrouterInspector.debugTypedMachineTimeline(...)`

`actionEnvelope` events are parsed into
`UnrouterMachineActionEnvelopeTypedPayload`, while non-envelope events keep a
typed payload wrapper (`controller`, `navigation`, `route`, or `generic`) based on event
source.
