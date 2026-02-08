/// Core `unrouter` API.
///
/// Import this entrypoint for typed route definitions, router configuration,
/// and widget-level navigation access.
library;

export 'src/core/route_definition.dart';
export 'src/runtime/unrouter.dart';
export 'package:unrouter/unrouter.dart'
    hide
        Unrouter,
        RouteRecord,
        RouteDefinition,
        LoadedRouteDefinition,
        route,
        routeWithLoader,
        ShellBranch,
        branch,
        shell,
        RouteResolution,
        RouteResolutionType,
        UnrouterController;
export 'src/runtime/navigation.dart'
    show UnrouterController, UnrouterScope, UnrouterBuildContextExtension;
