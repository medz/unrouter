import 'package:unstory/unstory.dart';

import '../core/route_data.dart';
import '../core/route_guards.dart';
import '../core/route_records.dart';
import '../core/route_shell.dart';
import 'shell_branch_descriptor.dart';
import 'shell_coordinator.dart';

/// Shared shell runtime bridge for adapter packages.
///
/// This class centralizes branch stack coordination so adapters only bind
/// UI/runtime callbacks.
class ShellRuntimeBinding<R extends RouteData> {
  ShellRuntimeBinding({required List<ShellBranch<R>> branches})
    : branches = List<ShellBranch<R>>.unmodifiable(branches),
      _coordinator = ShellCoordinator(
        branches: List<ShellBranchDescriptor>.generate(branches.length, (
          index,
        ) {
          final branch = branches[index];
          return ShellBranchDescriptor(
            index: index,
            initialLocation: branch.initialLocation,
            routePatterns: branch.routes
                .map<String>((route) => route.path)
                .toList(growable: false),
          );
        }),
      );

  final List<ShellBranch<R>> branches;
  final ShellCoordinator _coordinator;

  void recordNavigation({
    required int branchIndex,
    required Uri uri,
    required HistoryAction action,
    required int? delta,
    required int? historyIndex,
  }) {
    _coordinator.recordNavigation(
      branchIndex: branchIndex,
      uri: uri,
      action: action,
      delta: delta,
      historyIndex: historyIndex,
    );
  }

  Uri resolveTargetUri(int branchIndex, {required bool initialLocation}) {
    return _coordinator.resolveBranchTarget(
      branchIndex,
      initialLocation: initialLocation,
    );
  }

  List<Uri> currentBranchHistory(int branchIndex) {
    return _coordinator.currentBranchHistory(branchIndex);
  }

  bool canPopBranch(int branchIndex) {
    return _coordinator.canPopBranch(branchIndex);
  }

  Uri? popBranch(int branchIndex) {
    return _coordinator.popBranch(branchIndex);
  }
}

/// Resolves a shell branch route record to an adapter-specific record type.
typedef ShellRouteRecordResolver<
  R extends RouteData,
  TAdapterRecord extends RouteRecord<R>
> = TAdapterRecord Function(RouteRecord<R> record);

/// Wraps a resolved adapter route record into a shell-aware route record.
typedef ShellRouteRecordWrapper<
  R extends RouteData,
  TAdapterRecord extends RouteRecord<R>,
  TWrappedRecord extends RouteRecord<R>
> =
    TWrappedRecord Function({
      required TAdapterRecord record,
      required ShellRuntimeBinding<R> runtime,
      required int branchIndex,
    });

/// Builds shell-aware wrapped route records for adapter packages.
///
/// This helper owns branch flattening and shared runtime construction so
/// adapter packages only provide record resolution and wrapping behavior.
List<TWrappedRecord> buildShellRouteRecords<
  R extends RouteData,
  TAdapterRecord extends RouteRecord<R>,
  TWrappedRecord extends RouteRecord<R>
>({
  required List<ShellBranch<R>> branches,
  required ShellRouteRecordResolver<R, TAdapterRecord> resolveRecord,
  required ShellRouteRecordWrapper<R, TAdapterRecord, TWrappedRecord>
  wrapRecord,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  final immutableBranches = List<ShellBranch<R>>.unmodifiable(branches);
  final runtime = ShellRuntimeBinding<R>(branches: immutableBranches);
  final wrapped = <TWrappedRecord>[];
  for (var i = 0; i < immutableBranches.length; i++) {
    final branch = immutableBranches[i];
    for (final record in branch.routes) {
      final adapterRecord = resolveRecord(record);
      wrapped.add(
        wrapRecord(record: adapterRecord, runtime: runtime, branchIndex: i),
      );
    }
  }
  return wrapped;
}

/// Casts a core shell route record to an adapter-specific route record type.
///
/// Throws with an adapter-oriented error message when record type does not
/// match the expected adapter route contract.
TAdapterRecord requireShellRouteRecord<
  R extends RouteData,
  TAdapterRecord extends RouteRecord<R>
>(
  RouteRecord<R> record, {
  required String adapterLabel,
  required String buildHint,
}) {
  if (record case TAdapterRecord adapterRecord) {
    return adapterRecord;
  }
  throw StateError(
    'Shell branch route "${record.path}" does not implement $adapterLabel '
    'RouteRecord. Build shell routes with $buildHint.',
  );
}

/// Shared base for adapter shell route wrappers.
///
/// Adapter packages can extend this type and only implement rendering concerns.
abstract class ShellRouteRecordBinding<
  R extends RouteData,
  TRecord extends RouteRecord<R>
>
    implements RouteRecord<R>, ShellRouteRecordHost {
  ShellRouteRecordBinding({
    required this.record,
    required ShellRuntimeBinding<R> runtime,
    required int branchIndex,
  }) : _runtime = runtime,
       _branchIndex = branchIndex;

  final TRecord record;
  final ShellRuntimeBinding<R> _runtime;
  final int _branchIndex;

  @override
  String get path => record.path;

  @override
  String? get name => record.name;

  @override
  RouteParser<R> get parse => record.parse;

  @override
  Future<Uri?> runRedirect(RouteContext<RouteData> context) {
    return record.runRedirect(context);
  }

  @override
  Future<RouteGuardResult> runGuards(RouteContext<RouteData> context) {
    return record.runGuards(context);
  }

  @override
  Uri resolveBranchTarget(int index, {bool initialLocation = false}) {
    return _runtime.resolveTargetUri(index, initialLocation: initialLocation);
  }

  @override
  bool canPopBranch() {
    return _runtime.canPopBranch(_branchIndex);
  }

  @override
  Uri? popBranch() {
    return _runtime.popBranch(_branchIndex);
  }

  void recordShellNavigation({
    required Uri uri,
    required HistoryAction action,
    required int? delta,
    required int? historyIndex,
  }) {
    _runtime.recordNavigation(
      branchIndex: _branchIndex,
      uri: uri,
      action: action,
      delta: delta,
      historyIndex: historyIndex,
    );
  }

  ShellState<R> createShellState({
    required Uri currentUri,
    required void Function(
      int index, {
      required bool initialLocation,
      required bool completePendingResult,
      Object? result,
    })
    goBranch,
    required bool Function() canPopBranch,
    required bool Function([Object? result]) popBranch,
  }) {
    return ShellState<R>(
      activeBranchIndex: _branchIndex,
      branches: _runtime.branches,
      currentUri: currentUri,
      currentBranchHistory: _runtime.currentBranchHistory(_branchIndex),
      onGoBranch:
          (
            index, {
            required initialLocation,
            required completePendingResult,
            result,
          }) {
            goBranch(
              index,
              initialLocation: initialLocation,
              completePendingResult: completePendingResult,
              result: result,
            );
          },
      onPopBranch: ([result]) => popBranch(result),
      onCanPopBranch: canPopBranch,
    );
  }
}
