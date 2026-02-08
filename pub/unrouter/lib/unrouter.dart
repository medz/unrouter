/// Core `unrouter` API.
///
/// Import this entrypoint for typed route definitions and platform-agnostic
/// route resolution.
library;

export 'src/core/route_data.dart';
export 'src/core/route_guards.dart';
export 'src/core/route_state.dart';
export 'src/core/route_records.dart';
export 'src/core/route_shell.dart';
export 'src/runtime/adapter_runtime.dart';
export 'src/runtime/unrouter.dart';
export 'src/shell/shell.dart';
export 'src/runtime/runtime_state.dart'
    show UnrouterResolutionState, UnrouterStateSnapshot;
