import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    show
        RouteData,
        RouteGuardResult,
        RouteContext,
        ShellBranch,
        ShellCoordinator,
        ShellRouteRecordHost,
        ShellState,
        buildShellRouteRecords,
        requireShellRouteRecord;
import 'package:unrouter/unrouter.dart' as core show RouteRecord;

import '../runtime/navigation.dart';
import 'route_records.dart';

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
        adapterLabel: 'flutter',
        buildHint: 'flutter_unrouter route()/dataRoute()',
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
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
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

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return record.createPage(key: key, name: name, child: child);
  }
}
