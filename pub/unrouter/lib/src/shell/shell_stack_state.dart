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
}
