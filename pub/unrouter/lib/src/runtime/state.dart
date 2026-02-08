import 'package:unstory/unstory.dart';

import '../core/route_data.dart';

/// Normalized route resolution state shared by runtime snapshots.
enum RouteResolutionType {
  pending,
  matched,
  unmatched,
  redirect,
  blocked,
  error,
}

/// Immutable snapshot of current router state.
class StateSnapshot<R extends RouteData> {
  const StateSnapshot({
    required this.uri,
    required this.historyState,
    required this.route,
    required this.resolution,
    required this.routePath,
    required this.routeName,
    required this.error,
    required this.stackTrace,
    required this.lastAction,
    required this.lastDelta,
    required this.historyIndex,
  });

  final Uri uri;
  final Object? historyState;
  final R? route;
  final RouteResolutionType resolution;
  final String? routePath;
  final String? routeName;
  final Object? error;
  final StackTrace? stackTrace;
  final HistoryAction lastAction;
  final int? lastDelta;
  final int? historyIndex;

  /// Whether current resolution is pending.
  bool get isPending => resolution == RouteResolutionType.pending;
  bool get isMatched => resolution == RouteResolutionType.matched;
  bool get isUnmatched => resolution == RouteResolutionType.unmatched;
  bool get isBlocked => resolution == RouteResolutionType.blocked;
  bool get hasError => resolution == RouteResolutionType.error;

  /// Casts snapshot route type while preserving captured values.
  StateSnapshot<S> cast<S extends RouteData>() {
    return StateSnapshot<S>(
      uri: uri,
      historyState: historyState,
      route: route as S?,
      resolution: resolution,
      routePath: routePath,
      routeName: routeName,
      error: error,
      stackTrace: stackTrace,
      lastAction: lastAction,
      lastDelta: lastDelta,
      historyIndex: historyIndex,
    );
  }
}
