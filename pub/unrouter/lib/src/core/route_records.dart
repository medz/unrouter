import 'dart:async';

import 'route_data.dart';
import 'route_guards.dart';
import 'route_state.dart';

/// Parses a matched [RouteParserState] into a typed route object.
typedef RouteParser<T extends RouteData> = T Function(RouteState state);

/// Route-level redirect resolver.
typedef RouteRedirect<T extends RouteData> =
    FutureOr<Uri?> Function(RouteContext<T> context);

/// Asynchronous loader executed during route resolution.
typedef DataLoader<T extends RouteData, L> =
    FutureOr<L> Function(RouteContext<T> context);

abstract class RouteRecord<T extends RouteData> {
  const RouteRecord({required this.path, required this.parse, this.name});

  final String path;
  final String? name;
  final RouteParser<T> parse;

  Future<Uri?> runRedirect(RouteContext<RouteData> context);
  Future<RouteGuardResult> runGuards(RouteContext<RouteData> context);
}

/// Route definition without asynchronous loader data.
class Route<T extends RouteData> extends RouteRecord<T> {
  const Route({
    required super.path,
    required super.parse,
    super.name,
    this.guards = const [],
    this.redirect,
  });

  final List<RouteGuard<T>> guards;
  final RouteRedirect<T>? redirect;

  @override
  Future<Uri?> runRedirect(RouteContext<RouteData> context) async {
    final resolver = redirect;
    if (resolver == null) return null;

    context.signal.throwIfCancelled();
    try {
      return await resolver(context.cast<T>());
    } finally {
      context.signal.throwIfCancelled();
    }
  }

  @override
  Future<RouteGuardResult> runGuards(RouteContext<RouteData> context) {
    return runRouteGuards(guards, context.cast<T>());
  }
}

/// Route definition that resolves typed loader data before completion.
class DataRoute<T extends RouteData, L> extends Route<T> {
  const DataRoute({
    required super.path,
    required super.parse,
    required DataLoader<T, L> loader,
    super.name,
    super.guards,
    super.redirect,
  }) : _loader = loader;

  final DataLoader<T, L> _loader;

  Future<L> load(RouteContext<RouteData> context) async {
    context.signal.throwIfCancelled();
    try {
      return await _loader(context.cast<T>());
    } finally {
      context.signal.throwIfCancelled();
    }
  }
}
