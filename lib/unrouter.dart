/// A declarative, guard-driven router for Flutter applications.
///
/// This library exports:
/// - Core router APIs: [Unrouter], [createRouter], [createRouterConfig]
/// - Route declarations and rendering: [Inlet], [Outlet], [Link]
/// - Guard APIs: [Guard], [GuardContext], [GuardResult], [defineGuard]
/// - Route hooks and typed helpers: [useRouter], [useLocation],
///   [useRouteParams], [useQuery], [useRouteMeta], [useRouteState],
///   [useRouteURI], [useFromLocation], [RouteParams], [URLSearchParams]
library;

export 'src/data_loader.dart';
export 'src/guard.dart';
export 'src/inlet.dart';
export 'src/link.dart';
export 'src/outlet.dart';
export 'src/route_params.dart';
export 'src/route_record.dart';
export 'src/route_scope.dart';
export 'src/router.dart';
export 'src/router_delegate.dart';
export 'src/url_search_params.dart';
