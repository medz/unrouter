import 'package:roux/roux.dart';
import 'package:unstory/unstory.dart';

import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';
import '../core/route_guards.dart';
import '../core/route_records.dart';
import '../core/route_state.dart';
import 'route_resolution.dart';

/// Platform-agnostic router configuration entrypoint for typed URL-first
/// resolution.
class Unrouter<R extends RouteData> {
  Unrouter({
    required List<RouteRecord<R>> routes,
    this.maxRedirectHops = 8,
    this.redirectLoopPolicy = RedirectLoopPolicy.error,
    this.onRedirectDiagnostics,
  }) : assert(routes.isNotEmpty, 'Unrouter routes must not be empty.'),
       assert(
         maxRedirectHops > 0,
         'Unrouter maxRedirectHops must be greater than zero.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       _matcher = _createMatcher(routes);

  /// Immutable route table consumed by the matcher.
  final List<RouteRecord<R>> routes;
  final RouterContext<RouteRecord<R>> _matcher;

  /// Redirect hop limit used to prevent infinite redirect chains.
  final int maxRedirectHops;

  /// Policy used when redirect loops are detected.
  final RedirectLoopPolicy redirectLoopPolicy;

  /// Callback invoked when redirect safety checks emit diagnostics.
  final RedirectDiagnosticsCallback? onRedirectDiagnostics;

  /// Resolves [uri] to a typed route, redirect, block, or error result.
  Future<RouteResolution<R>> resolve(
    Uri uri, {
    RouteExecutionSignal signal = const RouteNeverCancelledSignal(),
  }) async {
    final normalizedUri = _normalizeUri(uri);
    final lookupPath = _normalizeLookupPath(normalizedUri.path);
    final matched = findRoute<RouteRecord<R>>(_matcher, null, lookupPath);
    if (matched == null) {
      return RouteResolution.unmatched(normalizedUri);
    }

    final params = matched.params ?? const <String, String>{};
    final state = RouteState(
      location: HistoryLocation(normalizedUri),
      params: params,
    );

    late final R route;
    try {
      route = matched.data.parse(state);
    } catch (error, stackTrace) {
      return RouteResolution.error(
        uri: normalizedUri,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final context = RouteContext<RouteData>(
      uri: normalizedUri,
      route: route,
      signal: signal,
    );

    try {
      signal.throwIfCancelled();

      final redirectUri = await matched.data.runRedirect(context);
      signal.throwIfCancelled();
      if (redirectUri != null) {
        return RouteResolution.redirect(
          uri: normalizedUri,
          redirectUri: _normalizeUri(redirectUri),
        );
      }

      final guardResult = await matched.data.runGuards(context);
      signal.throwIfCancelled();
      if (guardResult.isRedirect) {
        final target = guardResult.uri;
        if (target == null) {
          return RouteResolution.error(
            uri: normalizedUri,
            error: StateError(
              'Route guard returned redirect without target uri for path '
              '"${matched.data.path}".',
            ),
            stackTrace: StackTrace.current,
          );
        }

        return RouteResolution.redirect(
          uri: normalizedUri,
          redirectUri: _normalizeUri(target),
        );
      }

      if (guardResult.isBlocked) {
        return RouteResolution.blocked(normalizedUri);
      }

      Object? loaderData;
      final record = matched.data;
      if (record case DataRouteDefinition<R, Object?> dataRoute) {
        loaderData = await dataRoute.load(context);
      }
      signal.throwIfCancelled();

      return RouteResolution.matched(
        uri: normalizedUri,
        route: route,
        record: matched.data,
        loaderData: loaderData,
      );
    } on RouteExecutionCancelledException {
      rethrow;
    } catch (error, stackTrace) {
      return RouteResolution.error(
        uri: normalizedUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static RouterContext<RouteRecord<R>> _createMatcher<R extends RouteData>(
    List<RouteRecord<R>> routes,
  ) {
    final matcher = createRouter<RouteRecord<R>>(caseSensitive: true);
    for (final route in routes) {
      addRoute<RouteRecord<R>>(matcher, null, route.path, route);
    }
    return matcher;
  }

  static Uri _normalizeUri(Uri uri) {
    final normalizedPath = _normalizeLookupPath(uri.path);
    if (normalizedPath == uri.path) {
      return uri;
    }

    return uri.replace(path: normalizedPath);
  }

  static String _normalizeLookupPath(String path) {
    if (path.isEmpty) {
      return '/';
    }

    if (!path.startsWith('/')) {
      return '/$path';
    }

    return path;
  }
}
