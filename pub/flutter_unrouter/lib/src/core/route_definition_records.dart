part of 'route_definition.dart';

/// Builds a route widget without loader data.
typedef RouteWidgetBuilder<T extends RouteData> =
    Widget Function(BuildContext context, T route);

/// Builds a route widget with resolved loader data.
typedef RouteLoadedWidgetBuilder<T extends RouteData, L> =
    Widget Function(BuildContext context, T route, L data);

/// Shell frame builder used by [shell].
typedef ShellBuilder<R extends RouteData> =
    Widget Function(BuildContext context, ShellState<R> shell, Widget child);

/// Custom transition builder used by route pages.
typedef RouteTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    );

/// Custom page builder used to wrap route children into [Page] instances.
typedef RoutePageBuilder = Page<void> Function(RoutePageBuilderState state);

/// Input payload for [RoutePageBuilder].
class RoutePageBuilderState {
  const RoutePageBuilderState({
    required this.key,
    required this.name,
    required this.child,
  });

  final LocalKey key;
  final String name;
  final Widget child;
}

abstract interface class RouteRecord<T extends RouteData>
    implements unrouter_core.RouteRecord<T> {
  @override
  String get path;

  @override
  String? get name;

  unrouter_core.RouteRecord<T> get core;

  Widget build(BuildContext context, RouteData route, Object? loaderData);

  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  });
}

/// Route definition without asynchronous loader data.
class RouteDefinition<T extends RouteData>
    extends unrouter_core.RouteDefinition<T>
    implements RouteRecord<T> {
  RouteDefinition({
    required super.path,
    required super.parse,
    required RouteWidgetBuilder<T> builder,
    super.name,
    super.guards = const [],
    super.redirect,
    this.pageBuilder,
    this.transitionBuilder,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  }) : _builder = builder;

  final RouteWidgetBuilder<T> _builder;
  final RoutePageBuilder? pageBuilder;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  unrouter_core.RouteRecord<T> get core => this;

  @override
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
    return _builder(context, route as T);
  }

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return _createRoutePage(
      key: key,
      name: name,
      child: child,
      pageBuilder: pageBuilder,
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
}

/// Route definition that resolves typed loader data before build.
class LoadedRouteDefinition<T extends RouteData, L>
    extends unrouter_core.LoadedRouteDefinition<T, L>
    implements RouteRecord<T> {
  LoadedRouteDefinition({
    required super.path,
    required super.parse,
    required super.loader,
    required RouteLoadedWidgetBuilder<T, L> builder,
    super.name,
    super.guards = const [],
    super.redirect,
    this.pageBuilder,
    this.transitionBuilder,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  }) : _builder = builder;

  final RouteLoadedWidgetBuilder<T, L> _builder;
  final RoutePageBuilder? pageBuilder;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  unrouter_core.RouteRecord<T> get core => this;

  @override
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
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

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return _createRoutePage(
      key: key,
      name: name,
      child: child,
      pageBuilder: pageBuilder,
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
}

/// Creates a [RouteDefinition].
RouteDefinition<T> route<T extends RouteData>({
  required String path,
  required unrouter_core.RouteParser<T> parse,
  required RouteWidgetBuilder<T> builder,
  String? name,
  List<unrouter_core.RouteGuard<T>> guards = const [],
  unrouter_core.RouteRedirect<T>? redirect,
  RoutePageBuilder? pageBuilder,
  RouteTransitionBuilder? transitionBuilder,
  Duration transitionDuration = Duration.zero,
  Duration reverseTransitionDuration = Duration.zero,
}) {
  return RouteDefinition<T>(
    path: path,
    parse: parse,
    builder: builder,
    name: name,
    guards: guards,
    redirect: redirect,
    pageBuilder: pageBuilder,
    transitionBuilder: transitionBuilder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

/// Creates a [LoadedRouteDefinition].
LoadedRouteDefinition<T, L> routeWithLoader<T extends RouteData, L>({
  required String path,
  required unrouter_core.RouteParser<T> parse,
  required unrouter_core.RouteLoader<T, L> loader,
  required RouteLoadedWidgetBuilder<T, L> builder,
  String? name,
  List<unrouter_core.RouteGuard<T>> guards = const [],
  unrouter_core.RouteRedirect<T>? redirect,
  RoutePageBuilder? pageBuilder,
  RouteTransitionBuilder? transitionBuilder,
  Duration transitionDuration = Duration.zero,
  Duration reverseTransitionDuration = Duration.zero,
}) {
  return LoadedRouteDefinition<T, L>(
    path: path,
    parse: parse,
    loader: loader,
    builder: builder,
    name: name,
    guards: guards,
    redirect: redirect,
    pageBuilder: pageBuilder,
    transitionBuilder: transitionBuilder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

Page<void> _createRoutePage({
  required LocalKey key,
  required String name,
  required Widget child,
  required RoutePageBuilder? pageBuilder,
  required RouteTransitionBuilder? transitionBuilder,
  required Duration transitionDuration,
  required Duration reverseTransitionDuration,
}) {
  final builder = pageBuilder;
  if (builder != null) {
    return builder(RoutePageBuilderState(key: key, name: name, child: child));
  }

  return _RouteTransitionPage(
    key: key,
    name: name,
    child: child,
    transitionBuilder: transitionBuilder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

class _RouteTransitionPage extends Page<void> {
  const _RouteTransitionPage({
    required this.child,
    required this.transitionBuilder,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    super.key,
    super.name,
  });

  final Widget child;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  Route<void> createRoute(BuildContext context) {
    final builder = transitionBuilder;
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: builder ?? (_, _, _, child) => child,
    );
  }
}
