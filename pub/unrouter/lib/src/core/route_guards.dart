import 'dart:async';

import 'route_data.dart';

typedef RouteGuard<T extends RouteData> =
    FutureOr<RouteGuardResult> Function(RouteContext<T> context);

/// Executes route guards in order and returns the first non-allow result.
Future<RouteGuardResult> runRouteGuards<T extends RouteData>(
  Iterable<RouteGuard<T>> guards,
  RouteContext<T> context,
) async {
  if (guards.isEmpty) return const .allow();
  for (final guard in guards) {
    context.signal.throwIfCancelled();

    final result = await guard(context);
    context.signal.throwIfCancelled();

    if (!result.isAllowed) return result;
  }

  return const .allow();
}

/// Context passed to guards, redirects, and loaders.
class RouteContext<T extends RouteData> {
  const RouteContext({
    required this.uri,
    required this.route,
    required this.signal,
  });

  final Uri uri;
  final T route;
  final RouteExecutionSignal signal;

  RouteContext<S> cast<S extends RouteData>() {
    return RouteContext<S>(uri: uri, route: route as S, signal: signal);
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
final class RouteGuardResult {
  const RouteGuardResult.allow() : type = .allow, uri = null;
  const RouteGuardResult.block() : type = .block, uri = null;

  RouteGuardResult.redirect({Uri? uri, RouteData? route})
    : assert(route != null || uri != null),
      type = .redirect,
      uri = uri ?? route?.toUri();

  final RouteGuardResultType type;
  final Uri? uri;

  bool get isAllowed => type == RouteGuardResultType.allow;
  bool get isBlocked => type == RouteGuardResultType.block;
  bool get isRedirect => type == RouteGuardResultType.redirect;
}
