# unrouter documentation

This folder contains user-facing guides and reference notes for `unrouter`.

## Guides

- [Getting started](getting_started.md): install `unrouter`, define typed routes,
  and wire `MaterialApp.router`.
- [Core routing guide](core_routing.md): route definitions, guards, redirects,
  loaders, and shell branches.
- [Machine API guide](machine_api.md): typed command/action dispatch and action
  envelope flows.
- [Devtools guide](devtools.md): inspector widget, bridge, panel, replay, and
  `/debug` integration.
- [Router benchmarking](router_benchmarking.md): behavior parity and performance
  comparison workflow.

## Reference contracts

- [State envelope](state_envelope.md): `history.state` format and compatibility.
- [Machine action envelope schema](machine_action_envelope_schema.md): schema
  and event version contract for machine action envelopes.
- [Replay persistence examples](replay_persistence_examples.md): storage adapter
  patterns for replay persistence.
