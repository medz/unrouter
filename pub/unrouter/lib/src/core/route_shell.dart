import 'route_data.dart';
import 'route_records.dart';

/// A branch in a shell route tree.
class ShellBranch<T extends RouteData> {
  const ShellBranch({required this.routes, required this.initialLocation});

  final Iterable<RouteRecord<T>> routes;
  final Uri initialLocation;
}

/// Contract implemented by shell-aware route records.
///
/// Adapter packages can implement this interface and wire it to
/// `UnrouterController.switchBranch/popBranch`.
abstract interface class ShellRouteRecordHost {
  Uri resolveBranchTarget(int index, {bool initialLocation = false});
  bool canPopBranch();
  Uri? popBranch();
}

typedef GoBranchHandler =
    void Function(
      int index, {
      required bool initialLocation,
      required bool completePendingResult,
      Object? result,
    });

typedef PopBranchHandler = bool Function([Object? result]);
typedef CanPopBranchHandler = bool Function();

/// Runtime state passed to shell builders.
///
/// This type is platform-agnostic and can be reused by adapter packages.
class ShellState<R extends RouteData> {
  const ShellState({
    required this.activeBranchIndex,
    required this.branches,
    required this.currentUri,
    required this.currentBranchHistory,
    required GoBranchHandler onGoBranch,
    required PopBranchHandler onPopBranch,
    required CanPopBranchHandler onCanPopBranch,
  }) : _onGoBranch = onGoBranch,
       _onPopBranch = onPopBranch,
       _onCanPopBranch = onCanPopBranch;

  final int activeBranchIndex;
  final Iterable<ShellBranch<R>> branches;
  final Uri currentUri;

  final Iterable<Uri> currentBranchHistory;

  final GoBranchHandler _onGoBranch;
  final PopBranchHandler _onPopBranch;
  final CanPopBranchHandler _onCanPopBranch;

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

  bool popBranch([Object? result]) {
    return _onPopBranch(result);
  }

  bool canPopBranch() {
    return _onCanPopBranch();
  }

  int get branchCount => branches.length;
}

ShellBranch<T> branch<T extends RouteData>({
  required Iterable<RouteRecord<T>> routes,
  required Uri initialLocation,
}) {
  return ShellBranch<T>(routes: routes, initialLocation: initialLocation);
}

/// Flattens branch routes into a single route list for shell-aware adapters.
Iterable<RouteRecord<R>> shell<R extends RouteData>({
  required Iterable<ShellBranch<R>> branches,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  return branches.expand((e) => e.routes);
}
