part of 'route_definition.dart';

/// Parses a matched [RouteParserState] into a typed route object.
typedef RouteParser<T extends RouteData> = T Function(RouteParserState state);

/// Route guard that can allow, block, or redirect navigation.
typedef RouteGuard<T extends RouteData> =
    FutureOr<RouteGuardResult> Function(RouteHookContext<T> context);

/// Route-level redirect resolver.
typedef RouteRedirect<T extends RouteData> =
    FutureOr<Uri?> Function(RouteHookContext<T> context);

/// Asynchronous loader executed during route resolution.
typedef RouteLoader<T extends RouteData, L> =
    FutureOr<L> Function(RouteHookContext<T> context);

abstract interface class RouteRecord<T extends RouteData> {
  String get path;

  String? get name;

  T parse(RouteParserState state);

  Future<Uri?> runRedirect(RouteHookContext<RouteData> context);

  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context);

  Future<Object?> load(RouteHookContext<RouteData> context);
}

/// Route definition without asynchronous loader data.
class RouteDefinition<T extends RouteData> implements RouteRecord<T> {
  RouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    this.name,
    List<RouteGuard<T>> guards = const [],
    this.redirect,
  }) : _parse = parse,
       _guards = List<RouteGuard<T>>.unmodifiable(guards);

  @override
  final String path;

  @override
  final String? name;

  final RouteParser<T> _parse;
  final List<RouteGuard<T>> _guards;
  final RouteRedirect<T>? redirect;

  @override
  T parse(RouteParserState state) => _parse(state);

  @override
  Future<Uri?> runRedirect(RouteHookContext<RouteData> context) async {
    final resolver = redirect;
    if (resolver == null) {
      return null;
    }

    context.signal.throwIfCancelled();
    final uri = await resolver(context.cast<T>());
    context.signal.throwIfCancelled();
    return uri;
  }

  @override
  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context) {
    return runRouteGuards(_guards, context.cast<T>());
  }

  @override
  Future<Object?> load(RouteHookContext<RouteData> context) async => null;
}

/// Route definition that resolves typed loader data before completion.
class LoadedRouteDefinition<T extends RouteData, L> implements RouteRecord<T> {
  LoadedRouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    required RouteLoader<T, L> loader,
    this.name,
    List<RouteGuard<T>> guards = const [],
    this.redirect,
  }) : _parse = parse,
       _loader = loader,
       _guards = List<RouteGuard<T>>.unmodifiable(guards);

  @override
  final String path;

  @override
  final String? name;

  final RouteParser<T> _parse;
  final RouteLoader<T, L> _loader;
  final List<RouteGuard<T>> _guards;
  final RouteRedirect<T>? redirect;

  @override
  T parse(RouteParserState state) => _parse(state);

  @override
  Future<Uri?> runRedirect(RouteHookContext<RouteData> context) async {
    final resolver = redirect;
    if (resolver == null) {
      return null;
    }

    context.signal.throwIfCancelled();
    final uri = await resolver(context.cast<T>());
    context.signal.throwIfCancelled();
    return uri;
  }

  @override
  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context) {
    return runRouteGuards(_guards, context.cast<T>());
  }

  @override
  Future<Object?> load(RouteHookContext<RouteData> context) async {
    final typedContext = context.cast<T>();
    context.signal.throwIfCancelled();
    final data = await _loader(typedContext);
    context.signal.throwIfCancelled();
    return data;
  }
}

/// Creates a [RouteDefinition].
RouteDefinition<T> route<T extends RouteData>({
  required String path,
  required RouteParser<T> parse,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
}) {
  return RouteDefinition<T>(
    path: path,
    parse: parse,
    name: name,
    guards: guards,
    redirect: redirect,
  );
}

/// Creates a [LoadedRouteDefinition].
LoadedRouteDefinition<T, L> routeWithLoader<T extends RouteData, L>({
  required String path,
  required RouteParser<T> parse,
  required RouteLoader<T, L> loader,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
}) {
  return LoadedRouteDefinition<T, L>(
    path: path,
    parse: parse,
    loader: loader,
    name: name,
    guards: guards,
    redirect: redirect,
  );
}
