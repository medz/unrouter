part of 'route_definition.dart';

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

/// Contract implemented by shell-aware route records.
abstract interface class ShellRouteRecordHost<R extends RouteData> {
  Uri resolveBranchTarget(int index, {bool initialLocation = false});

  bool canPopBranch();

  Uri? popBranch({Object? result});
}

/// Runtime state passed to shell builders.
class ShellState<R extends RouteData> {
  const ShellState._({
    required this.activeBranchIndex,
    required this.branches,
    required this.currentUri,
    required List<Uri> currentBranchHistory,
    required void Function(
      int index, {
      bool initialLocation,
      bool completePendingResult,
      Object? result,
    })
    onGoBranch,
    required bool Function() canPopBranch,
    required bool Function(Object? result) onPopBranch,
  }) : _currentBranchHistory = currentBranchHistory,
       _onGoBranch = onGoBranch,
       _canPopBranch = canPopBranch,
       _onPopBranch = onPopBranch;

  final int activeBranchIndex;
  final List<ShellBranch<R>> branches;
  final Uri currentUri;
  final List<Uri> _currentBranchHistory;
  final void Function(
    int index, {
    bool initialLocation,
    bool completePendingResult,
    Object? result,
  })
  _onGoBranch;
  final bool Function() _canPopBranch;
  final bool Function(Object? result) _onPopBranch;

  int get branchCount => branches.length;

  List<Uri> get currentBranchHistory {
    return UnmodifiableListView(_currentBranchHistory);
  }

  bool get canPopBranch => _canPopBranch();

  /// Switches active branch.
  ///
  /// Set [initialLocation] to reset the target branch stack, and optionally
  /// complete an active push result with [completePendingResult]/[result].
  void goBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    _onGoBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Pops the active branch stack and optionally completes push result.
  bool popBranch<T extends Object?>([T? result]) {
    return _onPopBranch(result);
  }
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
    implements RouteRecord<R>, ShellRouteRecordHost<R> {
  _ShellRouteRecord({
    required RouteRecord<R> record,
    required core.ShellRuntimeBinding<R> runtime,
    required ShellBuilder<R> shellBuilder,
    required int branchIndex,
    String? shellName,
  }) : _record = record,
       _runtime = runtime,
       _shellBuilder = shellBuilder,
       _branchIndex = branchIndex,
       _shellName = shellName;

  final RouteRecord<R> _record;
  final core.ShellRuntimeBinding<R> _runtime;
  final ShellBuilder<R> _shellBuilder;
  final int _branchIndex;
  final String? _shellName;

  @override
  String get path => _record.path;

  @override
  String? get name {
    if (_shellName == null) {
      return _record.name;
    }
    final routeName = _record.name;
    if (routeName == null || routeName.isEmpty) {
      return _shellName;
    }
    return '$_shellName.$routeName';
  }

  @override
  R parse(RouteParserState state) => _record.parse(state);

  @override
  Future<Uri?> runRedirect(RouteHookContext<RouteData> context) {
    return _record.runRedirect(context);
  }

  @override
  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context) {
    return _record.runGuards(context);
  }

  @override
  Future<Object?> load(RouteHookContext<RouteData> context) {
    return _record.load(context);
  }

  @override
  Uri resolveBranchTarget(int index, {bool initialLocation = false}) {
    return _runtime.resolveTargetUri(index, initialLocation: initialLocation);
  }

  @override
  bool canPopBranch() {
    return _runtime.canPopBranch(_branchIndex);
  }

  @override
  Uri? popBranch({Object? result}) {
    return _runtime.popBranch(_branchIndex);
  }

  @override
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
    final child = _record.build(context, route, loaderData);
    final controller = context.unrouter;
    _runtime.restoreFromState(controller.historyState);
    final currentUri = controller.uri;
    _runtime.recordNavigation(
      branchIndex: _branchIndex,
      uri: currentUri,
      action: controller.lastAction,
      delta: controller.lastDelta,
      historyIndex: controller.historyIndex,
    );
    controller.setHistoryStateComposer((request) {
      return _runtime.composeHistoryState(
        uri: request.uri,
        action: request.action,
        state: request.state,
        currentState: request.currentState,
        activeBranchIndex: _branchIndex,
      );
    });

    final shellState = ShellState<R>._(
      activeBranchIndex: _branchIndex,
      branches: _runtime.branches,
      currentUri: currentUri,
      currentBranchHistory: _runtime.currentBranchHistory(_branchIndex),
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
      canPopBranch: () => _runtime.canPopBranch(_branchIndex),
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
    return _record.createPage(key: key, name: name, child: child);
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
