import 'package:unrouter/src/core/route_data.dart';
import 'package:unrouter/src/core/route_records.dart';
import 'package:unrouter/src/core/route_shell.dart';
import 'package:unrouter/src/runtime/unrouter.dart';

/// Casts a core route record to an adapter-specific route record type.
TRecord? castRouteRecord<R extends RouteData, TRecord extends RouteRecord<R>>(
  RouteRecord<R>? record,
) {
  if (record case TRecord typedRecord) {
    return typedRecord;
  }
  return null;
}

/// Casts a core route record to a shell host record when available.
ShellRouteRecordHost<R>? castShellRouteRecordHost<R extends RouteData>(
  RouteRecord<R>? record,
) {
  if (record case ShellRouteRecordHost<R> shellHost) {
    return shellHost;
  }
  return null;
}

/// Pulls current controller resolution and clears shell composer when active
/// record is not shell-aware.
RouteResolution<R> syncControllerResolution<R extends RouteData>(
  UnrouterController<R> controller,
) {
  final resolution = controller.resolution;
  final record = resolution.record;
  if (record is! ShellRouteRecordHost<R>) {
    controller.clearHistoryStateComposer();
  }
  return resolution;
}

/// Resolves [resolution] into adapter output via lifecycle callbacks.
TResult resolveRouteResolution<R extends RouteData, TResult>({
  required RouteResolution<R> resolution,
  required TResult Function(RouteResolution<R> resolution) onPending,
  required TResult Function(RouteResolution<R> resolution) onMatched,
  required TResult Function(RouteResolution<R> resolution) onBlocked,
  required TResult Function(RouteResolution<R> resolution) onUnmatched,
  required TResult Function(RouteResolution<R> resolution) onError,
  TResult Function(RouteResolution<R> resolution)? onRedirect,
}) {
  if (resolution.isPending) {
    return onPending(resolution);
  }

  if (resolution.hasError) {
    return onError(resolution);
  }

  if (resolution.isBlocked) {
    return onBlocked(resolution);
  }

  if (resolution.isMatched) {
    return onMatched(resolution);
  }

  if (resolution.isRedirect) {
    final redirectHandler = onRedirect;
    if (redirectHandler != null) {
      return redirectHandler(resolution);
    }
  }

  return onUnmatched(resolution);
}
