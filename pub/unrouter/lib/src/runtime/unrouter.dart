import 'package:roux/roux.dart';

import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';
import '../core/route_definition.dart';

export '../core/redirect_diagnostics.dart';

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
    final state = RouteParserState(uri: normalizedUri, pathParameters: params);

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

    final context = RouteHookContext<RouteData>(
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
        final target = guardResult.redirectUri;
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

      final loaderData = await matched.data.load(context);
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

/// Route resolution lifecycle state.
enum RouteResolutionType {
  pending,
  matched,
  unmatched,
  redirect,
  blocked,
  error,
}

/// Result returned by [Unrouter.resolve].
class RouteResolution<R extends RouteData> {
  const RouteResolution._({
    required this.type,
    required this.uri,
    this.record,
    this.route,
    this.loaderData,
    this.redirectUri,
    this.error,
    this.stackTrace,
  });

  factory RouteResolution.pending(Uri uri) {
    return RouteResolution._(type: RouteResolutionType.pending, uri: uri);
  }

  factory RouteResolution.matched({
    required Uri uri,
    required RouteRecord<R> record,
    required R route,
    Object? loaderData,
  }) {
    return RouteResolution._(
      type: RouteResolutionType.matched,
      uri: uri,
      record: record,
      route: route,
      loaderData: loaderData,
    );
  }

  factory RouteResolution.unmatched(Uri uri) {
    return RouteResolution._(type: RouteResolutionType.unmatched, uri: uri);
  }

  factory RouteResolution.redirect({
    required Uri uri,
    required Uri redirectUri,
  }) {
    return RouteResolution._(
      type: RouteResolutionType.redirect,
      uri: uri,
      redirectUri: redirectUri,
    );
  }

  factory RouteResolution.blocked(Uri uri) {
    return RouteResolution._(type: RouteResolutionType.blocked, uri: uri);
  }

  factory RouteResolution.error({
    required Uri uri,
    required Object error,
    required StackTrace stackTrace,
  }) {
    return RouteResolution._(
      type: RouteResolutionType.error,
      uri: uri,
      error: error,
      stackTrace: stackTrace,
    );
  }

  final RouteResolutionType type;
  final Uri uri;
  final RouteRecord<R>? record;
  final R? route;
  final Object? loaderData;
  final Uri? redirectUri;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isPending => type == RouteResolutionType.pending;

  bool get isMatched => type == RouteResolutionType.matched;

  bool get isUnmatched => type == RouteResolutionType.unmatched;

  bool get isRedirect => type == RouteResolutionType.redirect;

  bool get isBlocked => type == RouteResolutionType.blocked;

  bool get hasError => type == RouteResolutionType.error;
}
