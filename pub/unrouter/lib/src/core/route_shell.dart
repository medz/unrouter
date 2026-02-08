import 'route_data.dart';
import 'route_records.dart';

/// A branch in a shell route tree.
class ShellBranch<T extends RouteData> {
  const ShellBranch({
    required this.routes,
    required this.initialLocation,
    this.name,
  });

  final Iterable<RouteRecord<T>> routes;
  final Uri initialLocation;
  final String? name;
}

/// Contract implemented by shell-aware route records.
///
/// Adapter packages can implement this interface and wire it to
/// `UnrouterController.switchBranch/popBranch`.
abstract interface class ShellRouteRecordHost {
  Uri resolveBranchTarget(int index, {bool initialLocation = false});
  bool canPopBranch();
  Uri? popBranch({Object? result});
}

typedef GoBranchHandler =
    void Function(
      int index, {
      bool? initialLocation,
      bool? completePendingResult,
      Object? result,
    });

/// Runtime state passed to shell builders.
///
/// This type is platform-agnostic and can be reused by adapter packages.
class ShellState<R extends RouteData> {
  const ShellState({
    required this.activeBranchIndex,
    required this.branches,
    required this.currentUri,
    required this.currentBranchHistory,
    required this.goBranch,
    required this.popBranch,
    required this.canPopBranch,
  });

  final int activeBranchIndex;
  final Iterable<ShellBranch<R>> branches;
  final Uri currentUri;

  final Iterable<Uri> currentBranchHistory;

  final GoBranchHandler goBranch;
  final bool Function(Object value) popBranch;
  final void Function() canPopBranch;

  int get branchCount => branches.length;
}

ShellBranch<T> branch<T extends RouteData>({
  required Iterable<RouteRecord<T>> routes,
  required Uri initialLocation,
  String? name,
}) {
  return ShellBranch<T>(
    routes: routes,
    initialLocation: initialLocation,
    name: name,
  );
}

/// Flattens branch routes into a single route list for shell-aware adapters.
Iterable<RouteRecord<R>> shell<R extends RouteData>({
  required Iterable<ShellBranch<R>> branches,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  return branches.expand((e) => e.routes);
}
