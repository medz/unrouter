part of 'route_definition.dart';

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

abstract interface class RouteExecutionSignal {
  bool get isCancelled;

  void throwIfCancelled();
}

class RouteNeverCancelledSignal implements RouteExecutionSignal {
  const RouteNeverCancelledSignal();

  @override
  bool get isCancelled => false;

  @override
  void throwIfCancelled() {}
}

class RouteExecutionCancelledException implements Exception {
  const RouteExecutionCancelledException();

  @override
  String toString() {
    return 'RouteExecutionCancelledException()';
  }
}

enum RouteGuardResultType { allow, block, redirect }

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

  static RouteGuardResult allow() => _allow;

  static RouteGuardResult block() => _block;

  factory RouteGuardResult.redirect(Uri uri) {
    return RouteGuardResult._(RouteGuardResultType.redirect, uri);
  }

  factory RouteGuardResult.redirectTo(RouteData route) {
    return RouteGuardResult.redirect(route.toUri());
  }
}
