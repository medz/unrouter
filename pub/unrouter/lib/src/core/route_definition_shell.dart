part of 'route_definition.dart';

/// A branch in a shell route tree.
class ShellBranch<R extends RouteData> {
  ShellBranch({
    required List<RouteRecord<R>> routes,
    required Uri initialLocation,
    this.name,
  }) : assert(
         routes.isNotEmpty,
         'A shell branch must define at least one route.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       initialLocation = _normalizeShellLocation(initialLocation);

  final List<RouteRecord<R>> routes;
  final Uri initialLocation;
  final String? name;
}

/// Creates a [ShellBranch].
ShellBranch<R> branch<R extends RouteData>({
  required List<RouteRecord<R>> routes,
  required Uri initialLocation,
  String? name,
}) {
  return ShellBranch<R>(
    routes: routes,
    initialLocation: initialLocation,
    name: name,
  );
}

/// Contract implemented by shell-aware route records.
///
/// Adapter packages can implement this interface and wire it to
/// `UnrouterController.switchBranch/popBranch`.
abstract interface class ShellRouteRecordHost<R extends RouteData> {
  Uri resolveBranchTarget(int index, {bool initialLocation = false});

  bool canPopBranch();

  Uri? popBranch({Object? result});
}

/// Runtime state passed to shell builders.
///
/// This type is platform-agnostic and can be reused by adapter packages.
class ShellState<R extends RouteData> {
  const ShellState({
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

/// Flattens branch routes into a single route list for shell-aware adapters.
List<RouteRecord<R>> shell<R extends RouteData>({
  required List<ShellBranch<R>> branches,
  String? name,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  final wrapped = <RouteRecord<R>>[];
  for (final branch in branches) {
    wrapped.addAll(branch.routes);
  }
  return wrapped;
}

Uri _normalizeShellLocation(Uri uri) {
  if (uri.path.isEmpty) {
    return uri.replace(path: '/');
  }
  if (uri.path.startsWith('/')) {
    return uri;
  }
  return uri.replace(path: '/${uri.path}');
}
