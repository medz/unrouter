import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart' as jaspr_router;
import 'package:unrouter/unrouter.dart'
    as core
    show
        RedirectDiagnosticsCallback,
        RedirectLoopPolicy,
        RouteExecutionSignal,
        RouteGuardResult,
        RouteHookContext,
        RouteNeverCancelledSignal,
        RouteParserState,
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

/// Builds fallback UI for unmatched locations.
typedef UnknownRouteBuilder = Component Function(BuildContext context, Uri uri);

/// Builds fallback UI for resolution errors.
typedef RouteErrorBuilder =
    Component Function(
      BuildContext context,
      Object error,
      StackTrace stackTrace,
    );

/// Jaspr adapter router configuration.
///
/// This adapter wraps the platform-agnostic `unrouter` core and can be mounted
/// through [UnrouterRouter]. Runtime navigation/history is delegated to
/// `jaspr_router`.
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

/// Jaspr component that mounts an [Unrouter] using `jaspr_router`.
///
/// Current MVP behavior:
/// - Route parsing + redirect/guard redirect use `unrouter` core hooks.
/// - Guard block is rendered by [blocked] if provided.
/// - `routeWithLoader` is not yet executed in this runtime binding and renders
///   [onError] (or a default error component).
class UnrouterRouter<R extends RouteData> extends StatelessComponent {
  const UnrouterRouter({
    required this.router,
    this.unknown,
    this.onError,
    this.blocked,
    super.key,
  });

  final Unrouter<R> router;
  final UnknownRouteBuilder? unknown;
  final RouteErrorBuilder? onError;
  final UnknownRouteBuilder? blocked;

  @override
  Component build(BuildContext context) {
    return jaspr_router.Router(
      routes: _toJasprRoutes(),
      errorBuilder: (context, state) {
        final uri = Uri.parse(state.location);
        final fallback = unknown;
        if (fallback != null) {
          return fallback(context, uri);
        }
        return _buildError(
          context,
          state.error ?? StateError('Unknown route for "$uri".'),
          StackTrace.current,
        );
      },
    );
  }

  List<jaspr_router.RouteBase> _toJasprRoutes() {
    return router.routes
        .map<jaspr_router.RouteBase>((record) {
          return jaspr_router.Route(
            path: record.path,
            name: record.name,
            redirect: (context, state) =>
                _runRouteRedirect(context, state, record),
            builder: (context, state) =>
                _buildRouteComponent(context, state, record),
          );
        })
        .toList(growable: false);
  }

  FutureOr<String?> _runRouteRedirect(
    BuildContext context,
    jaspr_router.RouteState state,
    RouteRecord<R> record,
  ) async {
    final parsed = _tryParseRoute(state, record);
    if (parsed == null) {
      return null;
    }

    final hook = core.RouteHookContext<RouteData>(
      uri: parsed.$1,
      route: parsed.$2,
      signal: const core.RouteNeverCancelledSignal(),
    );

    final redirect = await record.core.runRedirect(hook);
    if (redirect != null) {
      return redirect.toString();
    }

    final guardResult = await record.core.runGuards(hook);
    if (guardResult.isRedirect) {
      return guardResult.redirectUri?.toString();
    }
    if (guardResult.isBlocked) {
      return null;
    }
    return null;
  }

  Component _buildRouteComponent(
    BuildContext context,
    jaspr_router.RouteState state,
    RouteRecord<R> record,
  ) {
    final parsed = _tryParseRoute(state, record);
    if (parsed == null) {
      return _buildError(
        context,
        StateError('Failed to parse route "${record.path}".'),
        StackTrace.current,
      );
    }

    final uri = parsed.$1;
    final route = parsed.$2;
    final hook = core.RouteHookContext<RouteData>(
      uri: uri,
      route: route,
      signal: const core.RouteNeverCancelledSignal(),
    );

    if (!context.binding.isClient) {
      if (record is LoadedRouteDefinition<R, dynamic>) {
        return _buildError(
          context,
          UnsupportedError(
            'jaspr_unrouter runtime binding does not support routeWithLoader yet.',
          ),
          StackTrace.current,
        );
      }
      try {
        return record.build(context, route, null);
      } catch (error, stackTrace) {
        return _buildError(context, error, stackTrace);
      }
    }

    return FutureBuilder<core.RouteGuardResult>(
      future: _runGuards(record, hook),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Component.empty();
        }
        if (snapshot.hasError) {
          return _buildError(
            context,
            snapshot.error!,
            snapshot.stackTrace ?? StackTrace.current,
          );
        }

        final guard = snapshot.data ?? core.RouteGuardResult.allow();
        if (guard.isBlocked) {
          final blockedBuilder = blocked;
          if (blockedBuilder != null) {
            return blockedBuilder(context, uri);
          }
          return _buildError(
            context,
            StateError('Route blocked for "$uri".'),
            StackTrace.current,
          );
        }

        if (record is LoadedRouteDefinition<R, dynamic>) {
          return _buildError(
            context,
            UnsupportedError(
              'jaspr_unrouter runtime binding does not support routeWithLoader yet.',
            ),
            StackTrace.current,
          );
        }

        try {
          return record.build(context, route, null);
        } catch (error, stackTrace) {
          return _buildError(context, error, stackTrace);
        }
      },
    );
  }

  Future<core.RouteGuardResult> _runGuards(
    RouteRecord<R> record,
    core.RouteHookContext<RouteData> hook,
  ) {
    return record.core.runGuards(hook);
  }

  (Uri, R)? _tryParseRoute(
    jaspr_router.RouteState state,
    RouteRecord<R> record,
  ) {
    final uri = Uri.parse(state.location);
    final parser = core.RouteParserState(
      uri: uri,
      pathParameters: state.params,
    );
    try {
      final route = record.core.parse(parser);
      return (uri, route);
    } catch (_) {
      return null;
    }
  }

  Component _buildError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final fallback = onError;
    if (fallback != null) {
      return fallback(context, error, stackTrace);
    }
    return Component.text('jaspr_unrouter error: $error');
  }
}
