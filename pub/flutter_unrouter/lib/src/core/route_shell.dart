import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    show
        RouteData,
        ShellBranch,
        ShellRuntimeBinding,
        ShellRouteRecordBinding,
        buildShellRouteRecords,
        requireShellRouteRecord;
import 'package:unrouter/unrouter.dart' as core show RouteRecord;

import '../runtime/navigation.dart';
import 'route_records.dart';

/// Creates a [ShellBranch].
ShellBranch<R> branch<R extends RouteData>({
  required List<RouteRecord<R>> routes,
  required Uri initialLocation,
  String? name,
}) {
  return ShellBranch<R>(
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
  return buildShellRouteRecords<R, RouteRecord<R>, RouteRecord<R>>(
    branches: branches,
    shellName: name,
    resolveRecord: (record) {
      return requireShellRouteRecord<R, RouteRecord<R>>(
        record,
        adapterLabel: 'flutter',
        buildHint: 'flutter_unrouter route()/dataRoute()',
      );
    },
    wrapRecord:
        ({
          required RouteRecord<R> record,
          required ShellRuntimeBinding<R> runtime,
          required int branchIndex,
          String? shellName,
        }) {
          return _ShellRouteRecord<R>(
            record: record,
            runtime: runtime,
            shellBuilder: builder,
            branchIndex: branchIndex,
            shellName: shellName,
          );
        },
  );
}

class _ShellRouteRecord<R extends RouteData>
    extends ShellRouteRecordBinding<R, RouteRecord<R>>
    implements RouteRecord<R> {
  _ShellRouteRecord({
    required super.record,
    required super.runtime,
    required super.branchIndex,
    super.shellName,
    required ShellBuilder<R> shellBuilder,
  }) : _shellBuilder = shellBuilder;

  final ShellBuilder<R> _shellBuilder;

  @override
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
    final child = record.build(context, route, loaderData);
    final controller = context.unrouter;
    final snapshot = controller.state;
    restoreShellState(snapshot.historyState);
    final currentUri = snapshot.uri;
    recordShellNavigation(
      uri: currentUri,
      action: snapshot.lastAction,
      delta: snapshot.lastDelta,
      historyIndex: snapshot.historyIndex,
    );

    final shellState = createShellState(
      currentUri: currentUri,
      goBranch:
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
      popBranch: (result) => controller.popBranch(result),
    );

    return _shellBuilder(context, shellState, child);
  }

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return record.createPage(key: key, name: name, child: child);
  }
}
