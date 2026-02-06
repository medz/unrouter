import 'package:flutter/widgets.dart';
import 'package:roux/roux.dart';
import 'package:unrouter/src/router_delegate.dart';
import 'package:unstory/unstory.dart';

import 'route_data.dart';
import 'redirect_diagnostics.dart';
import 'route_definition.dart';
import 'route_information_parser.dart';
import 'route_information_provider.dart';

export 'redirect_diagnostics.dart';

typedef UnknownRouteBuilder = Widget Function(BuildContext context, Uri uri);
typedef RouteErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace stackTrace);

class Unrouter<R extends RouteData> extends StatelessWidget
    implements RouterConfig<HistoryLocation> {
  Unrouter({
    super.key,
    required List<RouteRecord<R>> routes,
    this.restorationScopeId,
    this.unknown,
    this.onError,
    this.loading,
    this.stateTimelineLimit = 64,
    this.machineTimelineLimit = 256,
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
       assert(
         stateTimelineLimit > 0,
         'Unrouter stateTimelineLimit must be greater than zero.',
       ),
       assert(
         machineTimelineLimit > 0,
         'Unrouter machineTimelineLimit must be greater than zero.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       _matcher = _createMatcher(routes),
       routeInformationProvider = UnrouterRouteInformationProvider(
         history ?? createHistory(base: base, strategy: strategy),
       );

  final List<RouteRecord<R>> routes;
  final RouterContext<RouteRecord<R>> _matcher;

  final UnknownRouteBuilder? unknown;
  final RouteErrorBuilder? onError;
  final WidgetBuilder? loading;
  final int stateTimelineLimit;
  final int machineTimelineLimit;
  final int maxRedirectHops;
  final RedirectLoopPolicy redirectLoopPolicy;
  final RedirectDiagnosticsCallback? onRedirectDiagnostics;

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

  Future<RouteResolution<R>> resolve(
    Uri uri, {
    required RouteExecutionSignal signal,
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

  @override
  Widget build(BuildContext context) {
    return Router.withConfig(
      config: this,
      restorationScopeId: restorationScopeId,
    );
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

enum RouteResolutionType {
  pending,
  matched,
  unmatched,
  redirect,
  blocked,
  error,
}

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
