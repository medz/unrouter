part of 'route_definition.dart';

/// Parses a matched [RouteParserState] into a typed route object.
typedef RouteParser<T extends RouteData> = T Function(RouteParserState state);

/// Builds a route widget without loader data.
typedef RouteWidgetBuilder<T extends RouteData> =
    Widget Function(BuildContext context, T route);

/// Builds a route widget with resolved loader data.
typedef RouteLoadedWidgetBuilder<T extends RouteData, L> =
    Widget Function(BuildContext context, T route, L data);

/// Route guard that can allow, block, or redirect navigation.
typedef RouteGuard<T extends RouteData> =
    FutureOr<RouteGuardResult> Function(RouteHookContext<T> context);

/// Route-level redirect resolver.
typedef RouteRedirect<T extends RouteData> =
    FutureOr<Uri?> Function(RouteHookContext<T> context);

/// Asynchronous loader executed before route build.
typedef RouteLoader<T extends RouteData, L> =
    FutureOr<L> Function(RouteHookContext<T> context);

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

abstract interface class RouteRecord<T extends RouteData> {
  String get path;

  String? get name;

  T parse(RouteParserState state);

  Future<Uri?> runRedirect(RouteHookContext<RouteData> context);

  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context);

  Future<Object?> load(RouteHookContext<RouteData> context);

  Widget build(BuildContext context, RouteData route, Object? loaderData);

  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  });
}

/// Route definition without asynchronous loader data.
class RouteDefinition<T extends RouteData> implements RouteRecord<T> {
  RouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    required RouteWidgetBuilder<T> builder,
    this.name,
    List<RouteGuard<T>> guards = const [],
    this.redirect,
    this.pageBuilder,
    this.transitionBuilder,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  }) : _parse = parse,
       _builder = builder,
       _guards = List<RouteGuard<T>>.unmodifiable(guards);

  @override
  final String path;

  @override
  final String? name;

  final RouteParser<T> _parse;
  final RouteWidgetBuilder<T> _builder;
  final List<RouteGuard<T>> _guards;
  final RouteRedirect<T>? redirect;
  final RoutePageBuilder? pageBuilder;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

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
class LoadedRouteDefinition<T extends RouteData, L> implements RouteRecord<T> {
  LoadedRouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    required RouteLoader<T, L> loader,
    required RouteLoadedWidgetBuilder<T, L> builder,
    this.name,
    List<RouteGuard<T>> guards = const [],
    this.redirect,
    this.pageBuilder,
    this.transitionBuilder,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  }) : _parse = parse,
       _loader = loader,
       _builder = builder,
       _guards = List<RouteGuard<T>>.unmodifiable(guards);

  @override
  final String path;

  @override
  final String? name;

  final RouteParser<T> _parse;
  final RouteLoader<T, L> _loader;
  final RouteLoadedWidgetBuilder<T, L> _builder;
  final List<RouteGuard<T>> _guards;
  final RouteRedirect<T>? redirect;
  final RoutePageBuilder? pageBuilder;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

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
  required RouteParser<T> parse,
  required RouteWidgetBuilder<T> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
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
  required RouteParser<T> parse,
  required RouteLoader<T, L> loader,
  required RouteLoadedWidgetBuilder<T, L> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
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
