import '../core/route_data.dart';
import '../core/route_records.dart';
import '../core/route_shell.dart';
import 'shell_coordinator.dart';

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
      required ShellCoordinator<R> coordinator,
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
  final coordinator = ShellCoordinator<R>(branches: immutableBranches);
  final wrapped = <TWrappedRecord>[];
  for (var i = 0; i < immutableBranches.length; i++) {
    final branch = immutableBranches[i];
    for (final record in branch.routes) {
      final adapterRecord = resolveRecord(record);
      wrapped.add(
        wrapRecord(
          record: adapterRecord,
          coordinator: coordinator,
          branchIndex: i,
        ),
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
