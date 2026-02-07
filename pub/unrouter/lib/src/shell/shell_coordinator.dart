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
  int? _lastRecordedHistoryIndex;
  HistoryAction? _lastRecordedAction;
  String? _lastRecordedUri;
  String? _lastRestorationSignature;

  /// Restores branch stacks from encoded state envelope.
  void restoreFromState(Object? state) {
    final envelope = codec.tryParse(state);
    final snapshot = envelope?.shell;
    if (snapshot == null) {
      return;
    }

    final signature = snapshot.signature;
    if (_lastRestorationSignature == signature) {
      return;
    }
    _lastRestorationSignature = signature;

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

  /// Composes state envelope for next history write.
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

    final projectedStacks = _cloneStacks(_stacks);
    final branchIndex = branchIndexForUri(request.uri) ?? activeBranchIndex;
    final stack = _ensureStackIn(
      projectedStacks,
      branchIndex,
      seed: request.uri,
    );
    switch (request.action) {
      case HistoryAction.push:
        _applyPush(stack, request.uri);
      case HistoryAction.replace:
        _applyReplace(stack, request.uri);
      case HistoryAction.pop:
        _applyPop(stack, request.uri, null);
    }

    final snapshot = ShellRestorationSnapshot.fromStacks(
      activeBranchIndex: branchIndex,
      stacks: projectedStacks,
    );
    return codec.encode(
      ShellStateEnvelope(userState: userState, shell: snapshot),
    );
  }

  /// Records actual navigation applied by history provider.
  void recordNavigation({
    required int branchIndex,
    required ShellNavigationEvent event,
  }) {
    _assertBranchIndex(branchIndex);
    if (_isDuplicateEvent(event)) {
      return;
    }

    final stack = _ensureStack(branchIndex, seed: event.uri);
    switch (event.action) {
      case HistoryAction.push:
        _applyPush(stack, event.uri);
      case HistoryAction.replace:
        _applyReplace(stack, event.uri);
      case HistoryAction.pop:
        _applyPop(stack, event.uri, event.delta);
    }

    _lastRecordedHistoryIndex = event.historyIndex;
    _lastRecordedAction = event.action;
    _lastRecordedUri = event.uri.toString();
    _lastRestorationSignature = ShellRestorationSnapshot.fromStacks(
      activeBranchIndex: branchIndex,
      stacks: _stacks,
    ).signature;
  }

  /// Returns branch index matching [uri], if any.
  int? branchIndexForUri(Uri uri) {
    final path = _normalizePathForMatch(uri.path);
    for (final branch in branches) {
      for (final pattern in branch.routePatterns) {
        if (_pathMatchesRoutePattern(pattern, path)) {
          return branch.index;
        }
      }
    }
    return null;
  }

  /// Resolves the location a branch should navigate to when activated.
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

  /// Whether [branchIndex] can pop within its own stack.
  bool canPopBranch(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null) {
      return false;
    }
    return stack.index > 0;
  }

  /// Pops one step in branch stack and returns target uri.
  Uri? popBranch(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null || stack.index <= 0) {
      return null;
    }

    stack.index -= 1;
    return stack.entries[stack.index];
  }

  /// Immutable current history of branch.
  List<Uri> currentBranchHistory(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null || stack.entries.isEmpty) {
      return const <Uri>[];
    }
    return stack.snapshotEntries;
  }

  /// Snapshot of current branch stacks.
  ShellRestorationSnapshot snapshot({required int activeBranchIndex}) {
    _assertBranchIndex(activeBranchIndex);
    return ShellRestorationSnapshot.fromStacks(
      activeBranchIndex: activeBranchIndex,
      stacks: _stacks,
    );
  }

  ShellBranchStackState _ensureStack(int branchIndex, {required Uri seed}) {
    final existing = _stacks[branchIndex];
    if (existing != null) {
      return existing;
    }

    final stack = ShellBranchStackState(entries: <Uri>[seed], index: 0);
    _stacks[branchIndex] = stack;
    return stack;
  }

  ShellBranchStackState _ensureStackIn(
    Map<int, ShellBranchStackState> stacks,
    int branchIndex, {
    required Uri seed,
  }) {
    final existing = stacks[branchIndex];
    if (existing != null) {
      return existing;
    }
    final stack = ShellBranchStackState(entries: <Uri>[seed], index: 0);
    stacks[branchIndex] = stack;
    return stack;
  }

  Map<int, ShellBranchStackState> _cloneStacks(
    Map<int, ShellBranchStackState> source,
  ) {
    return source.map<int, ShellBranchStackState>(
      (branchIndex, stack) =>
          MapEntry<int, ShellBranchStackState>(branchIndex, stack.copy()),
    );
  }

  bool _isDuplicateEvent(ShellNavigationEvent event) {
    final uriString = event.uri.toString();
    if (event.historyIndex != null) {
      return _lastRecordedHistoryIndex == event.historyIndex &&
          _lastRecordedAction == event.action &&
          _lastRecordedUri == uriString;
    }

    return _lastRecordedAction == event.action && _lastRecordedUri == uriString;
  }

  void _applyPush(ShellBranchStackState stack, Uri uri) {
    if (_sameUri(stack.entries[stack.index], uri)) {
      return;
    }

    if (stack.index < stack.entries.length - 1) {
      stack.entries.removeRange(stack.index + 1, stack.entries.length);
    }
    stack.entries.add(uri);
    stack.index = stack.entries.length - 1;
  }

  void _applyReplace(ShellBranchStackState stack, Uri uri) {
    stack.entries[stack.index] = uri;
  }

  void _applyPop(ShellBranchStackState stack, Uri uri, int? delta) {
    final matchedIndex = _findPopMatchIndex(stack, uri, delta);
    if (matchedIndex != null) {
      stack.index = matchedIndex;
      return;
    }

    stack.entries[stack.index] = uri;
  }

  int? _findPopMatchIndex(ShellBranchStackState stack, Uri uri, int? delta) {
    if (delta != null && delta < 0) {
      for (var i = stack.index; i >= 0; i--) {
        if (_sameUri(stack.entries[i], uri)) {
          return i;
        }
      }
    } else if (delta != null && delta > 0) {
      for (var i = stack.index; i < stack.entries.length; i++) {
        if (_sameUri(stack.entries[i], uri)) {
          return i;
        }
      }
    }

    for (var i = 0; i < stack.entries.length; i++) {
      if (_sameUri(stack.entries[i], uri)) {
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

String _normalizePathForMatch(String path) {
  if (path.isEmpty) {
    return '/';
  }
  var normalized = path;
  if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }
  if (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

bool _pathMatchesRoutePattern(String pattern, String path) {
  final normalizedPattern = _normalizePathForMatch(pattern);
  final normalizedPath = _normalizePathForMatch(path);
  final patternSegments = _splitPathSegments(normalizedPattern);
  final pathSegments = _splitPathSegments(normalizedPath);
  if (patternSegments.length != pathSegments.length) {
    return false;
  }

  for (var i = 0; i < patternSegments.length; i++) {
    final patternSegment = patternSegments[i];
    final pathSegment = pathSegments[i];
    if (patternSegment.startsWith(':')) {
      if (pathSegment.isEmpty) {
        return false;
      }
      continue;
    }
    if (patternSegment != pathSegment) {
      return false;
    }
  }
  return true;
}

List<String> _splitPathSegments(String path) {
  if (path == '/') {
    return const <String>[];
  }
  return path.substring(1).split('/');
}
