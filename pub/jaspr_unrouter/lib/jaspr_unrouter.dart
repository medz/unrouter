/// Jaspr adapter API for `unrouter`.
library;

export 'src/core/route_data.dart';
export 'src/core/route_definition.dart';
export 'src/runtime/link.dart' show UnrouterLink, UnrouterLinkMode;
export 'src/runtime/unrouter.dart';
export 'src/runtime/navigation.dart'
    show UnrouterBuildContextExtension, UnrouterController, UnrouterScope;
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
