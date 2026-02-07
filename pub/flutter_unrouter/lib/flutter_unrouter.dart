/// Core `unrouter` API.
///
/// Import this entrypoint for typed route definitions, router configuration,
/// and widget-level navigation access.
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
        RouteParserState;
export 'src/runtime/navigation.dart'
    show
        UnrouterResolutionState,
        UnrouterStateSnapshot,
        UnrouterStateTimelineEntry,
        UnrouterController,
        UnrouterScope,
        UnrouterBuildContextExtension;
