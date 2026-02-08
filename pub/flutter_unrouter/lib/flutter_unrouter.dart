/// Core `unrouter` API.
///
/// Import this entrypoint for typed route definitions, router configuration,
/// and widget-level navigation access.
library;

export 'src/core/route_definition.dart';
export 'src/runtime/unrouter.dart';
export 'package:unrouter/unrouter.dart'
    show
        RouteData,
        UnrouterResolutionState,
        UnrouterStateSnapshot,
        RouteExecutionCancelledException,
        RouteExecutionSignal,
        RouteGuardResult,
        RouteGuardResultType,
        RouteHookContext,
        RouteNeverCancelledSignal,
        RouteParserState;
export 'src/runtime/navigation.dart'
    show
        UnrouterController,
        UnrouterScope,
        UnrouterBuildContextExtension,
        UnrouterControllerListenableExtension;
