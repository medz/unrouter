import 'package:unstory/unstory.dart';

import '../core/route_data.dart';
import '../core/route_definition.dart';
import 'shell_branch_descriptor.dart';
import 'shell_coordinator.dart';

/// Shared shell runtime bridge for adapter packages.
///
/// This class centralizes branch stack coordination and history-state envelope
/// composition so adapters only bind UI/runtime callbacks.
class ShellRuntimeBinding<R extends RouteData> {
  ShellRuntimeBinding({required List<ShellBranch<R>> branches})
    : branches = List<ShellBranch<R>>.unmodifiable(branches),
      _coordinator = ShellCoordinator(
        branches: List<ShellBranchDescriptor>.generate(branches.length, (
          index,
        ) {
          final branch = branches[index];
          return ShellBranchDescriptor(
            index: index,
            name: branch.name,
            initialLocation: branch.initialLocation,
            routePatterns: branch.routes
                .map<String>((route) => route.path)
                .toList(growable: false),
          );
        }),
      );

  final List<ShellBranch<R>> branches;
  final ShellCoordinator _coordinator;

  void restoreFromState(Object? state) {
    _coordinator.restoreFromState(state);
  }

  Object? composeHistoryState({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
    required Object? currentState,
    required int activeBranchIndex,
  }) {
    return _coordinator.composeHistoryState(
      request: ShellHistoryStateRequest(
        uri: uri,
        action: action,
        state: state,
        currentState: currentState,
      ),
      activeBranchIndex: activeBranchIndex,
    );
  }

  void recordNavigation({
    required int branchIndex,
    required Uri uri,
    required HistoryAction action,
    required int? delta,
    required int? historyIndex,
  }) {
    _coordinator.recordNavigation(
      branchIndex: branchIndex,
      event: ShellNavigationEvent(
        uri: uri,
        action: action,
        delta: delta,
        historyIndex: historyIndex,
      ),
    );
  }

  Uri resolveTargetUri(int branchIndex, {required bool initialLocation}) {
    return _coordinator.resolveBranchTarget(
      branchIndex,
      initialLocation: initialLocation,
    );
  }

  List<Uri> currentBranchHistory(int branchIndex) {
    return _coordinator.currentBranchHistory(branchIndex);
  }

  bool canPopBranch(int branchIndex) {
    return _coordinator.canPopBranch(branchIndex);
  }

  Uri? popBranch(int branchIndex) {
    return _coordinator.popBranch(branchIndex);
  }
}

/// Shared base for adapter shell route wrappers.
///
/// Adapter packages can extend this type and only implement rendering concerns.
abstract class ShellRouteRecordBinding<
  R extends RouteData,
  TRecord extends RouteRecord<R>
>
    implements RouteRecord<R>, ShellRouteRecordHost<R> {
  ShellRouteRecordBinding({
    required this.record,
    required ShellRuntimeBinding<R> runtime,
    required int branchIndex,
    String? shellName,
  }) : _runtime = runtime,
       _branchIndex = branchIndex,
       _shellName = shellName;

  final TRecord record;
  final ShellRuntimeBinding<R> _runtime;
  final int _branchIndex;
  final String? _shellName;

  @override
  String get path => record.path;

  @override
  String? get name {
    if (_shellName == null) {
      return record.name;
    }
    final routeName = record.name;
    if (routeName == null || routeName.isEmpty) {
      return _shellName;
    }
    return '$_shellName.$routeName';
  }

  @override
  R parse(RouteParserState state) => record.parse(state);

  @override
  Future<Uri?> runRedirect(RouteHookContext<RouteData> context) {
    return record.runRedirect(context);
  }

  @override
  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context) {
    return record.runGuards(context);
  }

  @override
  Future<Object?> load(RouteHookContext<RouteData> context) {
    return record.load(context);
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

  void restoreShellState(Object? state) {
    _runtime.restoreFromState(state);
  }

  void recordShellNavigation({
    required Uri uri,
    required HistoryAction action,
    required int? delta,
    required int? historyIndex,
  }) {
    _runtime.recordNavigation(
      branchIndex: _branchIndex,
      uri: uri,
      action: action,
      delta: delta,
      historyIndex: historyIndex,
    );
  }

  Object? composeShellHistoryState({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
    required Object? currentState,
  }) {
    return _runtime.composeHistoryState(
      uri: uri,
      action: action,
      state: state,
      currentState: currentState,
      activeBranchIndex: _branchIndex,
    );
  }

  ShellState<R> createShellState({
    required Uri currentUri,
    required void Function(
      int index, {
      bool initialLocation,
      bool completePendingResult,
      Object? result,
    })
    onGoBranch,
    required bool Function() canPopBranch,
    required bool Function(Object? result) onPopBranch,
  }) {
    return ShellState<R>(
      activeBranchIndex: _branchIndex,
      branches: _runtime.branches,
      currentUri: currentUri,
      currentBranchHistory: _runtime.currentBranchHistory(_branchIndex),
      onGoBranch: onGoBranch,
      canPopBranch: canPopBranch,
      onPopBranch: onPopBranch,
    );
  }
}
