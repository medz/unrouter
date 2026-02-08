import 'package:unstory/unstory.dart';

import '../core/route_data.dart';
import '../core/route_shell.dart';
import 'shell_stack_state.dart';

/// Platform-agnostic coordinator for shell branch stacks.
class ShellCoordinator<R extends RouteData> {
  ShellCoordinator({required List<ShellBranch<R>> branches})
    : branches = List<ShellBranch<R>>.unmodifiable(branches);

  final List<ShellBranch<R>> branches;

  final Map<int, ShellBranchStackState> _stacks =
      <int, ShellBranchStackState>{};
  int? _lastRecordedHistoryIndex;
  HistoryAction? _lastRecordedAction;
  String? _lastRecordedUri;

  /// Records actual navigation applied by history provider.
  void recordNavigation({
    required int branchIndex,
    required Uri uri,
    required HistoryAction action,
    required int? delta,
    required int? historyIndex,
  }) {
    _assertBranchIndex(branchIndex);
    if (_isDuplicateEvent(
      uri: uri,
      action: action,
      historyIndex: historyIndex,
    )) {
      return;
    }

    final stack = _ensureStack(branchIndex, seed: uri);
    switch (action) {
      case HistoryAction.push:
        _applyPush(stack, uri);
      case HistoryAction.replace:
        _applyReplace(stack, uri);
      case HistoryAction.pop:
        _applyPop(stack, uri, delta);
    }

    _lastRecordedHistoryIndex = historyIndex;
    _lastRecordedAction = action;
    _lastRecordedUri = uri.toString();
  }

  /// Returns branch index matching [uri], if any.
  int? branchIndexForUri(Uri uri) {
    final path = _normalizePathForMatch(uri.path);
    for (var i = 0; i < branches.length; i++) {
      final branch = branches[i];
      for (final route in branch.routes) {
        if (_pathMatchesRoutePattern(route.path, path)) {
          return i;
        }
      }
    }
    return null;
  }

  /// Resolves the location a branch should navigate to when activated.
  Uri resolveBranchTarget(int branchIndex, {required bool initialLocation}) {
    _assertBranchIndex(branchIndex);
    final branch = branches[branchIndex];
    if (initialLocation) {
      final initial = branch.initialLocation;
      _stacks[branchIndex] = ShellBranchStackState(
        entries: <Uri>[initial],
        index: 0,
      );
      return initial;
    }

    final stack = _stacks[branchIndex];
    if (stack == null || stack.entries.isEmpty) {
      final initial = branch.initialLocation;
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

  ShellBranchStackState _ensureStack(int branchIndex, {required Uri seed}) {
    final existing = _stacks[branchIndex];
    if (existing != null) {
      return existing;
    }

    final stack = ShellBranchStackState(entries: <Uri>[seed], index: 0);
    _stacks[branchIndex] = stack;
    return stack;
  }

  bool _isDuplicateEvent({
    required Uri uri,
    required HistoryAction action,
    required int? historyIndex,
  }) {
    final uriString = uri.toString();
    if (historyIndex != null) {
      return _lastRecordedHistoryIndex == historyIndex &&
          _lastRecordedAction == action &&
          _lastRecordedUri == uriString;
    }

    return _lastRecordedAction == action && _lastRecordedUri == uriString;
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
