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
