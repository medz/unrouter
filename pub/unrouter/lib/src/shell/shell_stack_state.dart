/// Mutable stack state of a shell branch.
class ShellBranchStackState {
  ShellBranchStackState({required List<Uri> entries, required this.index})
    : entries = List<Uri>.from(entries);

  /// History-like entries for one branch.
  final List<Uri> entries;

  /// Current active entry index inside [entries].
  int index;

  /// Immutable snapshot of current entries.
  List<Uri> get snapshotEntries => List<Uri>.unmodifiable(entries);

  ShellBranchStackState copy() {
    return ShellBranchStackState(entries: entries, index: index);
  }

  Map<String, Object?> toJson(int branchIndex) {
    return <String, Object?>{
      'branchIndex': branchIndex,
      'index': index,
      'entries': entries.map((entry) => entry.toString()).toList(),
    };
  }

  static ShellBranchStackState? tryParse(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }

    final entriesValue = value['entries'];
    if (entriesValue is! List<Object?> || entriesValue.isEmpty) {
      return null;
    }

    final entries = <Uri>[];
    for (final raw in entriesValue) {
      if (raw is! String) {
        return null;
      }
      entries.add(Uri.parse(raw));
    }

    final rawIndex = value['index'];
    if (rawIndex is! int) {
      return null;
    }
    final safeIndex = rawIndex.clamp(0, entries.length - 1);
    return ShellBranchStackState(entries: entries, index: safeIndex);
  }
}
