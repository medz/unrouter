import 'shell_stack_state.dart';

/// Serializable snapshot used by shell history-state restoration.
class ShellRestorationSnapshot {
  const ShellRestorationSnapshot({
    required this.activeBranchIndex,
    required this.stacks,
  });

  /// Active branch index when snapshot was captured.
  final int activeBranchIndex;

  /// Branch stacks keyed by branch index.
  final Map<int, ShellBranchStackState> stacks;

  /// Stable content signature used to skip duplicate restoration.
  String get signature {
    final indices = stacks.keys.toList()..sort();
    final buffer = StringBuffer('a:$activeBranchIndex');
    for (final branchIndex in indices) {
      final stack = stacks[branchIndex]!;
      buffer.write('|$branchIndex:${stack.index}');
      for (final uri in stack.entries) {
        buffer.write(':${uri.toString()}');
      }
    }
    return buffer.toString();
  }

  Map<String, Object?> toJson() {
    final indices = stacks.keys.toList()..sort();
    return <String, Object?>{
      'activeBranchIndex': activeBranchIndex,
      'stacks': indices.map((branchIndex) {
        return stacks[branchIndex]!.toJson(branchIndex);
      }).toList(),
    };
  }

  static ShellRestorationSnapshot fromStacks({
    required int activeBranchIndex,
    required Map<int, ShellBranchStackState> stacks,
  }) {
    final serialized = <int, ShellBranchStackState>{};
    stacks.forEach((branchIndex, stack) {
      if (stack.entries.isEmpty) {
        return;
      }
      final safeIndex = stack.index.clamp(0, stack.entries.length - 1);
      serialized[branchIndex] = ShellBranchStackState(
        entries: stack.entries,
        index: safeIndex,
      );
    });
    return ShellRestorationSnapshot(
      activeBranchIndex: activeBranchIndex,
      stacks: serialized,
    );
  }

  static ShellRestorationSnapshot? tryParse(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }

    final activeBranchIndex = value['activeBranchIndex'];
    if (activeBranchIndex is! int) {
      return null;
    }

    final stacksValue = value['stacks'];
    if (stacksValue is! List<Object?>) {
      return null;
    }

    final stacks = <int, ShellBranchStackState>{};
    for (final rawStack in stacksValue) {
      if (rawStack is! Map<Object?, Object?>) {
        continue;
      }
      final branchIndex = rawStack['branchIndex'];
      if (branchIndex is! int) {
        continue;
      }
      final stack = ShellBranchStackState.tryParse(rawStack);
      if (stack == null) {
        continue;
      }
      stacks[branchIndex] = stack;
    }

    return ShellRestorationSnapshot(
      activeBranchIndex: activeBranchIndex,
      stacks: stacks,
    );
  }
}
