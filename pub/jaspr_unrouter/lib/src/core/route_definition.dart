import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart'
    hide
        LoadedRouteDefinition,
        RouteDefinition,
        RouteRecord,
        branch,
        route,
        routeWithLoader,
        shell;
import 'package:unrouter/unrouter.dart'
    as core
    show
        LoadedRouteDefinition,
        RouteDefinition,
        RouteRecord,
        ShellRuntimeBinding,
        branch;

import '../runtime/navigation.dart';

/// Builds a route component without loader data.
typedef RouteComponentBuilder<T extends RouteData> =
    Component Function(BuildContext context, T route);

/// Builds a route component with resolved loader data.
typedef RouteLoadedComponentBuilder<T extends RouteData, L> =
    Component Function(BuildContext context, T route, L data);

/// Shell frame builder used by [shell].
typedef ShellBuilder<R extends RouteData> =
    Component Function(
      BuildContext context,
      ShellState<R> shell,
      Component child,
    );

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

/// Creates a [ShellBranch].
ShellBranch<R> branch<R extends RouteData>({
  required List<RouteRecord<R>> routes,
  required Uri initialLocation,
  String? name,
}) {
  return core.branch<R>(
    routes: routes.cast<core.RouteRecord<R>>(),
    initialLocation: initialLocation,
    name: name,
  );
}

/// Wraps branch routes into a shared shell.
List<RouteRecord<R>> shell<R extends RouteData>({
  required ShellBuilder<R> builder,
  required List<ShellBranch<R>> branches,
  String? name,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  final immutableBranches = List<ShellBranch<R>>.unmodifiable(branches);
  final runtime = core.ShellRuntimeBinding<R>(branches: immutableBranches);
  final wrapped = <RouteRecord<R>>[];
  for (var i = 0; i < immutableBranches.length; i++) {
    final branch = immutableBranches[i];
    for (final record in branch.routes) {
      final adapterRecord = _asAdapterRouteRecord(record);
      wrapped.add(
        _ShellRouteRecord<R>(
          record: adapterRecord,
          runtime: runtime,
          shellBuilder: builder,
          branchIndex: i,
          shellName: name,
        ),
      );
    }
  }
  return wrapped;
}

class _ShellRouteRecord<R extends RouteData>
    extends ShellRouteRecordBinding<R, RouteRecord<R>>
    implements RouteRecord<R>, ShellRouteRecordHost<R> {
  _ShellRouteRecord({
    required super.record,
    required super.runtime,
    required super.branchIndex,
    super.shellName,
    required ShellBuilder<R> shellBuilder,
  }) : _shellBuilder = shellBuilder;

  final ShellBuilder<R> _shellBuilder;

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    final child = record.build(context, route, loaderData);
    final controller = context.unrouter;
    restoreShellState(controller.historyState);
    final currentUri = controller.uri;
    recordShellNavigation(
      uri: currentUri,
      action: controller.lastAction,
      delta: controller.lastDelta,
      historyIndex: controller.historyIndex,
    );
    controller.setHistoryStateComposer((request) {
      return composeShellHistoryState(
        uri: request.uri,
        action: request.action,
        state: request.state,
        currentState: request.currentState,
      );
    });

    final shellState = createShellState(
      currentUri: currentUri,
      onGoBranch:
          (
            index, {
            initialLocation = false,
            completePendingResult = false,
            result,
          }) {
            controller.switchBranch(
              index,
              initialLocation: initialLocation,
              completePendingResult: completePendingResult,
              result: result,
            );
          },
      canPopBranch: canPopBranch,
      onPopBranch: (result) => controller.popBranch(result),
    );

    return _shellBuilder(context, shellState, child);
  }
}

RouteRecord<R> _asAdapterRouteRecord<R extends RouteData>(
  core.RouteRecord<R> record,
) {
  if (record case RouteRecord<R> adapterRecord) {
    return adapterRecord;
  }
  throw StateError(
    'Shell branch route "${record.path}" does not implement jaspr RouteRecord. '
    'Build shell routes with jaspr_unrouter route()/routeWithLoader().',
  );
}
