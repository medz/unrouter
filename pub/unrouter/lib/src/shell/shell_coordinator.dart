import 'package:unstory/unstory.dart';

import 'shell_branch_descriptor.dart';
import 'shell_restoration_snapshot.dart';
import 'shell_stack_state.dart';
import 'shell_state_envelope_codec.dart';

/// Input payload used when composing `history.state`.
class ShellHistoryStateRequest {
  const ShellHistoryStateRequest({
    required this.uri,
    required this.action,
    required this.state,
    required this.currentState,
  });

  final Uri uri;
  final HistoryAction action;
  final Object? state;
  final Object? currentState;
}

/// Navigation event observed by shell coordinator.
class ShellNavigationEvent {
  const ShellNavigationEvent({
    required this.uri,
    required this.action,
    required this.delta,
    required this.historyIndex,
  });

  final Uri uri;
  final HistoryAction action;
  final int? delta;
  final int? historyIndex;
}

/// Platform-agnostic coordinator for shell branch stacks and restoration state.
class ShellCoordinator {
  ShellCoordinator({
    required List<ShellBranchDescriptor> branches,
    ShellStateEnvelopeCodec? codec,
  }) : branches = List<ShellBranchDescriptor>.unmodifiable(branches),
       codec = codec ?? const ShellStateEnvelopeCodec();

  final List<ShellBranchDescriptor> branches;
  final ShellStateEnvelopeCodec codec;

  final Map<int, ShellBranchStackState> _stacks =
      <int, ShellBranchStackState>{};
  String? _lastRestorationSignature;

  void restoreFromState(Object? state) {
    final envelope = codec.tryParse(state);
    final snapshot = envelope?.shell;
    if (snapshot == null) {
      return;
    }

    if (_lastRestorationSignature == snapshot.signature) {
      return;
    }
    _lastRestorationSignature = snapshot.signature;

    _stacks.clear();
    snapshot.stacks.forEach((branchIndex, stack) {
      if (branchIndex < 0 || branchIndex >= branches.length) {
        return;
      }
      if (stack.entries.isEmpty) {
        return;
      }
      final safeIndex = stack.index.clamp(0, stack.entries.length - 1);
      _stacks[branchIndex] = ShellBranchStackState(
        entries: stack.entries,
        index: safeIndex,
      );
    });
  }

  Object? composeHistoryState({
    required ShellHistoryStateRequest request,
    required int activeBranchIndex,
  }) {
    _assertBranchIndex(activeBranchIndex);
    final requested = codec.parseOrRaw(request.state);
    final current = codec.parseOrRaw(request.currentState);
    final userState = request.state == null
        ? current.userState
        : requested.userState;

    final snapshot = ShellRestorationSnapshot(
      activeBranchIndex: activeBranchIndex,
      stacks: _cloneStacks(),
    );
    return codec.encode(
      ShellStateEnvelope(userState: userState, shell: snapshot),
    );
  }

  void recordNavigation({
    required int branchIndex,
    required ShellNavigationEvent event,
  }) {
    _assertBranchIndex(branchIndex);
    final stack = _ensureStack(branchIndex, seed: event.uri);
    switch (event.action) {
      case HistoryAction.push:
        if (!_sameUri(stack.entries[stack.index], event.uri)) {
          if (stack.index < stack.entries.length - 1) {
            stack.entries.removeRange(stack.index + 1, stack.entries.length);
          }
          stack.entries.add(event.uri);
          stack.index = stack.entries.length - 1;
        }
      case HistoryAction.replace:
        stack.entries[stack.index] = event.uri;
      case HistoryAction.pop:
        final match = _findMatch(stack.entries, event.uri);
        if (match == null) {
          stack.entries[stack.index] = event.uri;
        } else {
          stack.index = match;
        }
    }
  }

  Uri resolveBranchTarget(int branchIndex, {required bool initialLocation}) {
    _assertBranchIndex(branchIndex);
    if (initialLocation) {
      final initial = branches[branchIndex].initialLocation;
      _stacks[branchIndex] = ShellBranchStackState(
        entries: <Uri>[initial],
        index: 0,
      );
      return initial;
    }

    final stack = _stacks[branchIndex];
    if (stack == null || stack.entries.isEmpty) {
      final initial = branches[branchIndex].initialLocation;
      _stacks[branchIndex] = ShellBranchStackState(
        entries: <Uri>[initial],
        index: 0,
      );
      return initial;
    }
    return stack.entries[stack.index];
  }

  bool canPopBranch(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null) {
      return false;
    }
    return stack.index > 0;
  }

  Uri? popBranch(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null || stack.index <= 0) {
      return null;
    }
    stack.index -= 1;
    return stack.entries[stack.index];
  }

  List<Uri> currentBranchHistory(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null || stack.entries.isEmpty) {
      return const <Uri>[];
    }
    return stack.snapshotEntries;
  }

  ShellRestorationSnapshot snapshot({required int activeBranchIndex}) {
    _assertBranchIndex(activeBranchIndex);
    return ShellRestorationSnapshot(
      activeBranchIndex: activeBranchIndex,
      stacks: _cloneStacks(),
    );
  }

  Map<int, ShellBranchStackState> _cloneStacks() {
    return _stacks.map<int, ShellBranchStackState>(
      (index, stack) =>
          MapEntry<int, ShellBranchStackState>(index, stack.copy()),
    );
  }

  ShellBranchStackState _ensureStack(int branchIndex, {required Uri seed}) {
    final existing = _stacks[branchIndex];
    if (existing != null) {
      return existing;
    }
    final created = ShellBranchStackState(entries: <Uri>[seed], index: 0);
    _stacks[branchIndex] = created;
    return created;
  }

  int? _findMatch(List<Uri> entries, Uri uri) {
    for (var i = 0; i < entries.length; i++) {
      if (_sameUri(entries[i], uri)) {
        return i;
      }
    }
    return null;
  }

  bool _sameUri(Uri a, Uri b) {
    return a.toString() == b.toString();
  }

  void _assertBranchIndex(int branchIndex) {
    if (branchIndex < 0 || branchIndex >= branches.length) {
      throw RangeError.index(branchIndex, branches, 'branchIndex');
    }
  }
}
