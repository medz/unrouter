/// Core `unrouter` API.
///
/// Import this entrypoint for typed route definitions and platform-agnostic
/// route resolution.
library;

export 'src/core/route_data.dart';
export 'src/core/route_definition.dart';
export 'src/runtime/adapter_runtime.dart';
export 'src/runtime/unrouter.dart';
export 'src/shell/shell.dart';
export 'src/runtime/runtime_state.dart'
    show UnrouterResolutionState, UnrouterStateSnapshot;
