import 'package:unstory/unstory.dart';

import '../core/route_data.dart';

/// Normalized route resolution state shared by runtime snapshots.
enum UnrouterResolutionState {
  unknown,
  pending,
  matched,
  unmatched,
  redirect,
  blocked,
  error,
}

/// Immutable snapshot of current router state.
class UnrouterStateSnapshot<R extends RouteData> {
  const UnrouterStateSnapshot({
    required this.uri,
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
  final R? route;
  final UnrouterResolutionState resolution;
  final String? routePath;
  final String? routeName;
  final Object? error;
  final StackTrace? stackTrace;
  final HistoryAction lastAction;
  final int? lastDelta;
  final int? historyIndex;

  /// Whether current resolution is pending.
  bool get isPending => resolution == UnrouterResolutionState.pending;

  bool get isMatched => resolution == UnrouterResolutionState.matched;

  bool get isUnmatched => resolution == UnrouterResolutionState.unmatched;

  bool get isBlocked => resolution == UnrouterResolutionState.blocked;

  bool get hasError => resolution == UnrouterResolutionState.error;

  /// Casts snapshot route type while preserving captured values.
  UnrouterStateSnapshot<S> cast<S extends RouteData>() {
    return UnrouterStateSnapshot<S>(
      uri: uri,
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

/// Timeline entry wrapper for [UnrouterStateSnapshot].
class UnrouterStateTimelineEntry<R extends RouteData> {
  const UnrouterStateTimelineEntry({
    required this.sequence,
    required this.recordedAt,
    required this.snapshot,
  });

  final int sequence;
  final DateTime recordedAt;
  final UnrouterStateSnapshot<R> snapshot;

  /// Casts timeline route type.
  UnrouterStateTimelineEntry<S> cast<S extends RouteData>() {
    return UnrouterStateTimelineEntry<S>(
      sequence: sequence,
      recordedAt: recordedAt,
      snapshot: snapshot.cast<S>(),
    );
  }
}
