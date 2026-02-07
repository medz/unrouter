part of 'route_definition.dart';

/// Executes route guards in order and returns the first non-allow result.
Future<RouteGuardResult> runRouteGuards<T extends RouteData>(
  List<RouteGuard<T>> guards,
  RouteHookContext<T> context,
) async {
  if (guards.isEmpty) {
    return RouteGuardResult.allow();
  }

  for (final guard in guards) {
    context.signal.throwIfCancelled();
    final result = await guard(context);
    context.signal.throwIfCancelled();

    if (!result.isAllowed) {
      return result;
    }
  }

  return RouteGuardResult.allow();
}

/// Context passed to guards, redirects, and loaders.
class RouteHookContext<T extends RouteData> {
  const RouteHookContext({
    required this.uri,
    required this.route,
    required this.signal,
  });

  final Uri uri;
  final T route;
  final RouteExecutionSignal signal;

  RouteHookContext<S> cast<S extends RouteData>() {
    return RouteHookContext<S>(uri: uri, route: route as S, signal: signal);
  }
}

/// Cooperative cancellation signal used by async route hooks.
abstract interface class RouteExecutionSignal {
  bool get isCancelled;

  void throwIfCancelled();
}

/// [RouteExecutionSignal] implementation that never cancels.
class RouteNeverCancelledSignal implements RouteExecutionSignal {
  const RouteNeverCancelledSignal();

  @override
  bool get isCancelled => false;

  @override
  void throwIfCancelled() {}
}

/// Thrown when route execution is cancelled.
class RouteExecutionCancelledException implements Exception {
  const RouteExecutionCancelledException();

  @override
  String toString() {
    return 'RouteExecutionCancelledException()';
  }
}

/// Outcome category for a route guard.
enum RouteGuardResultType { allow, block, redirect }

/// Guard decision used by route resolution.
class RouteGuardResult {
  const RouteGuardResult._(this.type, [this.redirectUri]);

  static const RouteGuardResult _allow = RouteGuardResult._(
    RouteGuardResultType.allow,
  );
  static const RouteGuardResult _block = RouteGuardResult._(
    RouteGuardResultType.block,
  );

  final RouteGuardResultType type;
  final Uri? redirectUri;

  bool get isAllowed => type == RouteGuardResultType.allow;

  bool get isBlocked => type == RouteGuardResultType.block;

  bool get isRedirect => type == RouteGuardResultType.redirect;

  /// Allows the request to continue.
  static RouteGuardResult allow() => _allow;

  /// Blocks the request and keeps the current location.
  static RouteGuardResult block() => _block;

  /// Redirects to the provided [uri].
  factory RouteGuardResult.redirect(Uri uri) {
    return RouteGuardResult._(RouteGuardResultType.redirect, uri);
  }

  /// Redirects to a typed [RouteData] target.
  factory RouteGuardResult.redirectTo(RouteData route) {
    return RouteGuardResult.redirect(route.toUri());
  }
}
