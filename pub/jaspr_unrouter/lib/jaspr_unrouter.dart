/// Jaspr adapter API for `unrouter`.
library;

export 'src/core/route_data.dart';
export 'src/core/route_definition.dart';
export 'src/runtime/unrouter.dart';
export 'package:unrouter/unrouter.dart'
    show
        RouteExecutionCancelledException,
        RouteExecutionSignal,
        RouteGuardResult,
        RouteGuardResultType,
        RouteHookContext,
        RouteNeverCancelledSignal,
        RouteParserState,
        UnrouterResolutionState,
        UnrouterStateSnapshot;
