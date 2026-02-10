import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart'
    hide DataRouteDefinition, RouteDefinition, RouteRecord, branch, shell;
import 'package:unrouter/unrouter.dart'
    as core
    show DataRouteDefinition, RouteDefinition, RouteRecord;

import '../runtime/navigation.dart';

/// Builds a route component without loader data.
typedef RouteComponentBuilder<T extends RouteData> =
    Component Function(BuildContext context, T route);

/// Builds a route component with resolved loader data.
typedef DataRouteComponentBuilder<T extends RouteData, L> =
    Component Function(BuildContext context, T route, L data);

/// Shell frame builder used by [shell].
typedef ShellBuilder<R extends RouteData> =
    Component Function(
      BuildContext context,
      ShellState<R> shell,
      Component child,
    );

abstract class RouteRecord<T extends RouteData> extends core.RouteRecord<T> {
  RouteRecord({required super.path, required super.parse, super.name});

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
class DataRouteDefinition<T extends RouteData, L>
    extends core.DataRouteDefinition<T, L>
    implements RouteRecord<T> {
  DataRouteDefinition({
    required String path,
    required RouteParser<T> parse,
    required DataLoader<T, L> loader,
    required DataRouteComponentBuilder<T, L> builder,
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

  final DataRouteComponentBuilder<T, L> _builder;

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

/// Creates a [DataRouteDefinition].
DataRouteDefinition<T, L> dataRoute<T extends RouteData, L>({
  required String path,
  required RouteParser<T> parse,
  required DataLoader<T, L> loader,
  required DataRouteComponentBuilder<T, L> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
}) {
  return DataRouteDefinition<T, L>(
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
}) {
  return ShellBranch<R>(
    routes: routes.cast<core.RouteRecord<R>>(),
    initialLocation: initialLocation,
  );
}

/// Wraps branch routes into a shared shell.
List<RouteRecord<R>> shell<R extends RouteData>({
  required ShellBuilder<R> builder,
  required List<ShellBranch<R>> branches,
}) {
  return buildShellRouteRecords<R, RouteRecord<R>, RouteRecord<R>>(
    branches: branches,
    resolveRecord: (record) {
      return requireShellRouteRecord<R, RouteRecord<R>>(
        record,
        adapterLabel: 'jaspr',
        buildHint: 'jaspr_unrouter route()/dataRoute()',
      );
    },
    wrapRecord:
        ({
          required RouteRecord<R> record,
          required ShellCoordinator<R> coordinator,
          required int branchIndex,
        }) {
          return _ShellRouteRecord<R>(
            record: record,
            coordinator: coordinator,
            shellBuilder: builder,
            branchIndex: branchIndex,
          );
        },
  );
}

class _ShellRouteRecord<R extends RouteData> extends RouteRecord<R>
    implements ShellRouteRecordHost {
  _ShellRouteRecord({
    required this.record,
    required this.coordinator,
    required this.branchIndex,
    required ShellBuilder<R> shellBuilder,
  }) : _shellBuilder = shellBuilder,
       super(path: record.path, parse: record.parse, name: record.name);

  final RouteRecord<R> record;
  final ShellCoordinator<R> coordinator;
  final int branchIndex;
  final ShellBuilder<R> _shellBuilder;

  @override
  Future<Uri?> runRedirect(RouteContext<RouteData> context) {
    return record.runRedirect(context);
  }

  @override
  Future<RouteGuardResult> runGuards(RouteContext<RouteData> context) {
    return record.runGuards(context);
  }

  @override
  Future<Object?> runLoader(RouteContext<RouteData> context) {
    return record.runLoader(context);
  }

  @override
  Uri resolveBranchTarget(int index, {bool initialLocation = false}) {
    return coordinator.resolveBranchTarget(
      index,
      initialLocation: initialLocation,
    );
  }

  @override
  bool canPopBranch() {
    return coordinator.canPopBranch(branchIndex);
  }

  @override
  Uri? popBranch() {
    return coordinator.popBranch(branchIndex);
  }

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    final child = record.build(context, route, loaderData);
    final controller = context.unrouter;
    final snapshot = controller.state;
    final currentUri = snapshot.uri;
    coordinator.recordNavigation(
      branchIndex: branchIndex,
      uri: currentUri,
      action: snapshot.lastAction,
      delta: snapshot.lastDelta,
      historyIndex: snapshot.historyIndex,
    );

    final shellState = ShellState<R>(
      activeBranchIndex: branchIndex,
      branches: coordinator.branches,
      currentUri: currentUri,
      currentBranchHistory: coordinator.currentBranchHistory(branchIndex),
      onGoBranch:
          (
            index, {
            required initialLocation,
            required completePendingResult,
            result,
          }) {
            controller.switchBranch(
              index,
              initialLocation: initialLocation,
              completePendingResult: completePendingResult,
              result: result,
            );
          },
      onPopBranch: ([result]) => controller.popBranch(result),
      onCanPopBranch: canPopBranch,
    );

    return _shellBuilder(context, shellState, child);
  }
}
