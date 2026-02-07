import 'package:unrouter/unrouter.dart'
    as core
    show
        RedirectDiagnosticsCallback,
        RedirectLoopPolicy,
        RouteExecutionSignal,
        RouteNeverCancelledSignal,
        RouteRecord,
        RouteResolution,
        RouteResolutionType,
        Unrouter;

import '../core/route_data.dart';
import '../core/route_definition.dart';

typedef _CoreRouteRecord<T extends RouteData> = core.RouteRecord<T>;
typedef _CoreRouteResolution<R extends RouteData> = core.RouteResolution<R>;
typedef _CoreRouteResolutionType = core.RouteResolutionType;
typedef _CoreUnrouter<R extends RouteData> = core.Unrouter<R>;

typedef RouteResolutionType = _CoreRouteResolutionType;
typedef RouteResolution<R extends RouteData> = _CoreRouteResolution<R>;

/// Jaspr adapter skeleton router.
///
/// This adapter currently wraps the platform-agnostic `unrouter` core and keeps
/// the route-definition surface compatible with Jaspr component builders.
class Unrouter<R extends RouteData> {
  Unrouter({
    required List<RouteRecord<R>> routes,
    this.maxRedirectHops = 8,
    this.redirectLoopPolicy = core.RedirectLoopPolicy.error,
    this.onRedirectDiagnostics,
  }) : assert(routes.isNotEmpty, 'Unrouter routes must not be empty.'),
       assert(
         maxRedirectHops > 0,
         'Unrouter maxRedirectHops must be greater than zero.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       _recordsByCore = Map<_CoreRouteRecord<R>, RouteRecord<R>>.unmodifiable(
         <_CoreRouteRecord<R>, RouteRecord<R>>{
           for (final record in routes) record.core: record,
         },
       ),
       _core = _CoreUnrouter<R>(
         routes: routes
             .map<_CoreRouteRecord<R>>((record) => record.core)
             .toList(growable: false),
         maxRedirectHops: maxRedirectHops,
         redirectLoopPolicy: redirectLoopPolicy,
         onRedirectDiagnostics: onRedirectDiagnostics,
       );

  /// Immutable route table consumed by the matcher.
  final List<RouteRecord<R>> routes;
  final Map<_CoreRouteRecord<R>, RouteRecord<R>> _recordsByCore;
  final _CoreUnrouter<R> _core;

  /// Redirect hop limit used to prevent infinite redirect chains.
  final int maxRedirectHops;

  /// Policy used when redirect loops are detected.
  final core.RedirectLoopPolicy redirectLoopPolicy;

  /// Callback invoked when redirect safety checks emit diagnostics.
  final core.RedirectDiagnosticsCallback? onRedirectDiagnostics;

  /// Resolves [uri] to a typed route, redirect, block, or error result.
  Future<RouteResolution<R>> resolve(
    Uri uri, {
    core.RouteExecutionSignal signal = const core.RouteNeverCancelledSignal(),
  }) {
    return _core.resolve(uri, signal: signal);
  }

  /// Returns adapter record from a core record when available.
  RouteRecord<R>? routeRecordOf(core.RouteRecord<R>? record) {
    if (record == null) {
      return null;
    }
    return _recordsByCore[record];
  }

  /// Underlying platform-agnostic core router.
  core.Unrouter<R> get coreRouter => _core;
}
