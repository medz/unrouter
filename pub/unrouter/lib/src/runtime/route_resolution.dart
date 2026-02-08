import '../core/route_data.dart';
import '../core/route_records.dart';
import 'state.dart';

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
