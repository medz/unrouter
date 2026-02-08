import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart' hide RouteRecord, Unrouter;
import 'package:unrouter/unrouter.dart' as core show RouteRecord, Unrouter;
import 'package:unstory/unstory.dart';

import '../core/route_definition.dart';
import '../platform/route_information_parser.dart';
import '../platform/route_information_provider.dart';
import 'router_delegate.dart';

export 'package:unrouter/unrouter.dart'
    show
        RedirectDiagnostics,
        RedirectDiagnosticsCallback,
        RedirectDiagnosticsReason,
        RedirectLoopPolicy;

/// Builds a fallback widget for unmatched locations.
typedef UnknownRouteBuilder = Widget Function(BuildContext context, Uri uri);

/// Builds a fallback widget for route parsing/guard/loader errors.
typedef RouteErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace stackTrace);

/// Router configuration entrypoint for typed URL-first navigation.
class Unrouter<R extends RouteData> extends core.Unrouter<R>
    implements RouterConfig<HistoryLocation> {
  Unrouter({
    required List<RouteRecord<R>> routes,
    this.restorationScopeId,
    this.unknown,
    this.onError,
    this.loading,
    this.blocked,
    this.resolveInitialRoute = false,
    super.maxRedirectHops = 8,
    super.redirectLoopPolicy = RedirectLoopPolicy.error,
    super.onRedirectDiagnostics,
    History? history,
    String? base,
    HistoryStrategy strategy = HistoryStrategy.browser,
  }) : routeInformationProvider = UnrouterRouteInformationProvider(
         history ?? createHistory(base: base, strategy: strategy),
       ),
       super(routes: routes.cast<core.RouteRecord<R>>());

  /// Optional builder for unknown locations.
  final UnknownRouteBuilder? unknown;

  /// Optional builder for route resolution errors.
  final RouteErrorBuilder? onError;

  /// Optional global loading widget shown before first successful resolution.
  final WidgetBuilder? loading;

  /// Optional builder for blocked locations.
  final UnknownRouteBuilder? blocked;

  /// Whether the delegate resolves initial route when mounted.
  final bool resolveInitialRoute;

  /// Optional restoration scope id passed to `Router.withConfig`.
  final String? restorationScopeId;

  @override
  final UnrouterRouteInformationProvider routeInformationProvider;

  @override
  late final UnrouterDelegate<R> routerDelegate = UnrouterDelegate<R>(this);

  @override
  final BackButtonDispatcher? backButtonDispatcher = RootBackButtonDispatcher();

  @override
  RouteInformationParser<HistoryLocation> get routeInformationParser {
    return const UnrouterRouteInformationParser();
  }
}
