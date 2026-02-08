import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    show
        RedirectDiagnosticsCallback,
        RedirectLoopPolicy,
        RouteData,
        RouteExecutionSignal,
        RouteNeverCancelledSignal;
import 'package:unrouter/unrouter.dart'
    as core
    show RouteRecord, RouteResolution, RouteResolutionType, Unrouter;
import 'router_delegate.dart';
import 'package:unstory/unstory.dart';

import '../core/route_definition.dart';
import '../platform/route_information_parser.dart';
import '../platform/route_information_provider.dart';

export '../core/redirect_diagnostics.dart';

/// Pure Dart core router type exported for controller-only usage.
typedef CoreUnrouter<R extends RouteData> = core.Unrouter<R>;
typedef RouteResolutionType = core.RouteResolutionType;
typedef RouteResolution<R extends RouteData> = core.RouteResolution<R>;

/// Builds a fallback widget for unmatched locations.
typedef UnknownRouteBuilder = Widget Function(BuildContext context, Uri uri);

/// Builds a fallback widget for route parsing/guard/loader errors.
typedef RouteErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace stackTrace);

/// Router configuration entrypoint for typed URL-first navigation.
class Unrouter<R extends RouteData> extends StatelessWidget
    implements RouterConfig<HistoryLocation> {
  Unrouter({
    super.key,
    required List<RouteRecord<R>> routes,
    this.restorationScopeId,
    this.unknown,
    this.onError,
    this.loading,
    this.blocked,
    this.maxRedirectHops = 8,
    this.redirectLoopPolicy = RedirectLoopPolicy.error,
    this.onRedirectDiagnostics,
    History? history,
    String? base,
    HistoryStrategy strategy = HistoryStrategy.browser,
  }) : assert(routes.isNotEmpty, 'Unrouter routes must not be empty.'),
       assert(
         maxRedirectHops > 0,
         'Unrouter maxRedirectHops must be greater than zero.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       _core = core.Unrouter<R>(
         routes: routes.cast<core.RouteRecord<R>>(),
         maxRedirectHops: maxRedirectHops,
         redirectLoopPolicy: redirectLoopPolicy,
         onRedirectDiagnostics: onRedirectDiagnostics,
       ),
       routeInformationProvider = UnrouterRouteInformationProvider(
         history ?? createHistory(base: base, strategy: strategy),
       );

  /// Immutable route table consumed by the matcher.
  final List<RouteRecord<R>> routes;
  final CoreUnrouter<R> _core;

  /// Optional builder for unknown locations.
  final UnknownRouteBuilder? unknown;

  /// Optional builder for route resolution errors.
  final RouteErrorBuilder? onError;

  /// Optional global loading widget shown before first successful resolution.
  final WidgetBuilder? loading;

  /// Optional builder for blocked locations.
  final UnknownRouteBuilder? blocked;

  /// Redirect hop limit used to prevent infinite redirect chains.
  final int maxRedirectHops;

  /// Policy used when redirect loops are detected.
  final RedirectLoopPolicy redirectLoopPolicy;

  /// Callback invoked when redirect safety checks emit diagnostics.
  final RedirectDiagnosticsCallback? onRedirectDiagnostics;

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

  /// Resolves [uri] to a typed route, redirect, block, or error result.
  Future<RouteResolution<R>> resolve(
    Uri uri, {
    RouteExecutionSignal signal = const RouteNeverCancelledSignal(),
  }) => _core.resolve(uri, signal: signal);

  CoreUnrouter<R> get coreRouter {
    return _core;
  }

  RouteRecord<R>? routeRecordOf(core.RouteRecord<R>? record) {
    return record is RouteRecord<R> ? record : null;
  }

  @override
  Widget build(BuildContext context) {
    return Router.withConfig(
      config: this,
      restorationScopeId: restorationScopeId,
    );
  }
}
