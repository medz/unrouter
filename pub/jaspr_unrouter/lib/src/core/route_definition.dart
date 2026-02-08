import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart' show RouteData;
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

/// Parses a matched [RouteParserState] into a typed route object.
typedef RouteParser<T extends RouteData> = core.RouteParser<T>;

/// Builds a route component without loader data.
typedef RouteComponentBuilder<T extends RouteData> =
    Component Function(BuildContext context, T route);

/// Builds a route component with resolved loader data.
typedef RouteLoadedComponentBuilder<T extends RouteData, L> =
    Component Function(BuildContext context, T route, L data);

/// Route guard that can allow, block, or redirect navigation.
typedef RouteGuard<T extends RouteData> = core.RouteGuard<T>;

/// Route-level redirect resolver.
typedef RouteRedirect<T extends RouteData> = core.RouteRedirect<T>;

/// Asynchronous loader executed before route build.
typedef RouteLoader<T extends RouteData, L> = core.RouteLoader<T, L>;

abstract interface class RouteRecord<T extends RouteData>
    implements core.RouteRecord<T> {
  Component build(BuildContext context, RouteData route, Object? loaderData);
}

/// Route definition without asynchronous loader data.
class RouteDefinition<T extends RouteData> extends core.RouteDefinition<T>
    implements RouteRecord<T> {
  RouteDefinition({
    required String path,
    required RouteParser<T> parse,
    required RouteComponentBuilder<T> builder,
    String? name,
    List<RouteGuard<T>> guards = const [],
    RouteRedirect<T>? redirect,
  }) : _builder = builder,
       super(
         path: path,
         parse: parse,
         name: name,
         guards: guards,
         redirect: redirect,
       );

  final RouteComponentBuilder<T> _builder;

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    return _builder(context, route as T);
  }
}

/// Route definition that resolves typed loader data before build.
class LoadedRouteDefinition<T extends RouteData, L>
    extends core.LoadedRouteDefinition<T, L>
    implements RouteRecord<T> {
  LoadedRouteDefinition({
    required String path,
    required RouteParser<T> parse,
    required RouteLoader<T, L> loader,
    required RouteLoadedComponentBuilder<T, L> builder,
    String? name,
    List<RouteGuard<T>> guards = const [],
    RouteRedirect<T>? redirect,
  }) : _builder = builder,
       super(
         path: path,
         parse: parse,
         loader: loader,
         name: name,
         guards: guards,
         redirect: redirect,
       );

  final RouteLoadedComponentBuilder<T, L> _builder;

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
