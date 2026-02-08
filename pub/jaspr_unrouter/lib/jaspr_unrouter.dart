/// Jaspr adapter API for `unrouter`.
library;

export 'src/core/route_records.dart';
export 'src/runtime/link.dart' show UnrouterLink, UnrouterLinkMode;
export 'src/runtime/unrouter.dart';
export 'src/runtime/navigation.dart'
    show UnrouterBuildContextExtension, UnrouterScope;
export 'package:unrouter/unrouter.dart'
    hide
        Unrouter,
        RouteRecord,
        RouteDefinition,
        LoadedRouteDefinition,
        route,
        routeWithLoader,
        branch,
        shell;
