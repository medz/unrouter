import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart'
    as core
    show
        LoadedRouteDefinition,
        RouteDefinition,
        RouteGuard,
        RouteLoader,
        RouteParser,
        RouteRecord,
        RouteRedirect;

import 'route_data.dart';

typedef CoreRouteRecord<T extends RouteData> = core.RouteRecord<T>;
typedef _CoreRouteDefinition<T extends RouteData> = core.RouteDefinition<T>;
typedef _CoreLoadedRouteDefinition<T extends RouteData, L> =
    core.LoadedRouteDefinition<T, L>;
typedef _CoreRouteGuard<T extends RouteData> = core.RouteGuard<T>;
typedef _CoreRouteRedirect<T extends RouteData> = core.RouteRedirect<T>;
typedef _CoreRouteLoader<T extends RouteData, L> = core.RouteLoader<T, L>;
typedef _CoreRouteParser<T extends RouteData> = core.RouteParser<T>;

/// Parses a matched [RouteParserState] into a typed route object.
typedef RouteParser<T extends RouteData> = _CoreRouteParser<T>;

/// Builds a route component without loader data.
typedef RouteComponentBuilder<T extends RouteData> =
    Component Function(BuildContext context, T route);

/// Builds a route component with resolved loader data.
typedef RouteLoadedComponentBuilder<T extends RouteData, L> =
    Component Function(BuildContext context, T route, L data);

/// Route guard that can allow, block, or redirect navigation.
typedef RouteGuard<T extends RouteData> = _CoreRouteGuard<T>;

/// Route-level redirect resolver.
typedef RouteRedirect<T extends RouteData> = _CoreRouteRedirect<T>;

/// Asynchronous loader executed before route build.
typedef RouteLoader<T extends RouteData, L> = _CoreRouteLoader<T, L>;

abstract interface class RouteRecord<T extends RouteData> {
  String get path;

  String? get name;

  CoreRouteRecord<T> get core;

  Component build(BuildContext context, RouteData route, Object? loaderData);
}

/// Route definition without asynchronous loader data.
class RouteDefinition<T extends RouteData> implements RouteRecord<T> {
  RouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    required RouteComponentBuilder<T> builder,
    this.name,
    List<RouteGuard<T>> guards = const [],
    RouteRedirect<T>? redirect,
  }) : _coreRecord = _CoreRouteDefinition<T>(
         path: path,
         parse: parse,
         name: name,
         guards: guards,
         redirect: redirect,
       ),
       _builder = builder;

  @override
  final String path;

  @override
  final String? name;

  final _CoreRouteDefinition<T> _coreRecord;
  final RouteComponentBuilder<T> _builder;

  @override
  CoreRouteRecord<T> get core => _coreRecord;

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    return _builder(context, route as T);
  }
}

/// Route definition that resolves typed loader data before build.
class LoadedRouteDefinition<T extends RouteData, L> implements RouteRecord<T> {
  LoadedRouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    required RouteLoader<T, L> loader,
    required RouteLoadedComponentBuilder<T, L> builder,
    this.name,
    List<RouteGuard<T>> guards = const [],
    RouteRedirect<T>? redirect,
  }) : _coreRecord = _CoreLoadedRouteDefinition<T, L>(
         path: path,
         parse: parse,
         loader: loader,
         name: name,
         guards: guards,
         redirect: redirect,
       ),
       _builder = builder;

  @override
  final String path;

  @override
  final String? name;

  final _CoreLoadedRouteDefinition<T, L> _coreRecord;
  final RouteLoadedComponentBuilder<T, L> _builder;

  @override
  CoreRouteRecord<T> get core => _coreRecord;

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    if (loaderData is! L) {
      final actualType = loaderData == null
          ? 'null'
          : loaderData.runtimeType.toString();
      throw StateError(
        'Route "$path" expected loader data of type "$L" '
        'but got "$actualType".',
      );
    }

    return _builder(context, route as T, loaderData);
  }
}

/// Creates a [RouteDefinition].
RouteDefinition<T> route<T extends RouteData>({
  required String path,
  required RouteParser<T> parse,
  required RouteComponentBuilder<T> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
}) {
  return RouteDefinition<T>(
    path: path,
    parse: parse,
    builder: builder,
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
  required RouteLoadedComponentBuilder<T, L> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
}) {
  return LoadedRouteDefinition<T, L>(
    path: path,
    parse: parse,
    loader: loader,
    builder: builder,
    name: name,
    guards: guards,
    redirect: redirect,
  );
}
