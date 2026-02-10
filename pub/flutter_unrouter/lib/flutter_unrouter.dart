/// Flutter adapter API for `unrouter`.
///
/// Import this entrypoint for typed route definitions, router configuration,
/// and widget-level navigation access.
library;

export 'src/core/route_records.dart';
export 'src/core/route_shell.dart';
export 'src/runtime/unrouter.dart';
export 'package:unrouter/unrouter.dart'
    hide
        Unrouter,
        RouteRecord,
        RouteDefinition,
        DataRouteDefinition,
        route,
        dataRoute,
        branch,
        shell;
export 'src/runtime/navigation.dart'
    show
        UnrouterScope,
        UnrouterBuildContextExtension,
        UnrouterControllerListenableExtension;
