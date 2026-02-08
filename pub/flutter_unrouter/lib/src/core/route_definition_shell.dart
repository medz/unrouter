part of 'route_definition.dart';

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
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  final immutableBranches = List<ShellBranch<R>>.unmodifiable(branches);
  final runtime = ShellRuntimeBinding<R>(branches: immutableBranches);
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
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
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

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return record.createPage(key: key, name: name, child: child);
  }
}

RouteRecord<R> _asAdapterRouteRecord<R extends RouteData>(
  core.RouteRecord<R> record,
) {
  if (record case RouteRecord<R> adapterRecord) {
    return adapterRecord;
  }
  throw StateError(
    'Shell branch route "${record.path}" does not implement flutter '
    'RouteRecord. Build shell routes with flutter_unrouter route()/'
    'routeWithLoader().',
  );
}
