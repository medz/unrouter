/// Immutable shell branch metadata used by adapter-specific shell integrations.
class ShellBranchDescriptor {
  ShellBranchDescriptor({
    required this.index,
    required this.initialLocation,
    required List<String> routePatterns,
    this.name,
  }) : routePatterns = List<String>.unmodifiable(routePatterns);

  /// Stable branch index.
  final int index;

  /// Initial location used when a branch stack is reset.
  final Uri initialLocation;

  /// Route path patterns that belong to this branch.
  final List<String> routePatterns;

  /// Optional branch name for diagnostics or tooling.
  final String? name;
}
