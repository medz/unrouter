import 'package:unstory/unstory.dart';
import 'package:unrouter_machine/unrouter_machine.dart';

import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';

part 'navigation_machine_commands_actions.dart';
part 'navigation_machine_api.dart';

/// Normalized route resolution state shared by runtime and machine timelines.
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

/// Source that produced a machine transition.
enum UnrouterMachineSource { controller, navigation, route }

/// Semantic group for machine event filtering.
enum UnrouterMachineEventGroup { lifecycle, navigation, shell, routeResolution }

/// Event name recorded in machine timeline entries.
enum UnrouterMachineEvent {
  initialized,
  controllerRouteMachineConfigured,
  controllerHistoryStateComposerChanged,
  controllerShellResolversChanged,
  controllerDisposed,
  goUri,
  replaceUri,
  pushUri,
  pop,
  popToUri,
  back,
  forward,
  goDelta,
  switchBranch,
  popBranch,
  request,
  requestDeduplicated,
  resolveStart,
  resolveCancelled,
  resolveCancelledSignal,
  resolveFinished,
  redirectMissingTarget,
  redirectDiagnosticsError,
  redirectAccepted,
  blockedFallback,
  blockedNoop,
  blockedUnmatched,
  commit,
  redirectRegistered,
  redirectChainCleared,
}

/// Maps machine events to semantic [UnrouterMachineEventGroup] values.
extension UnrouterMachineEventGrouping on UnrouterMachineEvent {
  UnrouterMachineEventGroup get group {
    switch (this) {
      case UnrouterMachineEvent.initialized:
      case UnrouterMachineEvent.controllerRouteMachineConfigured:
      case UnrouterMachineEvent.controllerHistoryStateComposerChanged:
      case UnrouterMachineEvent.controllerShellResolversChanged:
      case UnrouterMachineEvent.controllerDisposed:
        return UnrouterMachineEventGroup.lifecycle;
      case UnrouterMachineEvent.goUri:
      case UnrouterMachineEvent.replaceUri:
      case UnrouterMachineEvent.pushUri:
      case UnrouterMachineEvent.pop:
      case UnrouterMachineEvent.popToUri:
      case UnrouterMachineEvent.back:
      case UnrouterMachineEvent.forward:
      case UnrouterMachineEvent.goDelta:
        return UnrouterMachineEventGroup.navigation;
      case UnrouterMachineEvent.switchBranch:
      case UnrouterMachineEvent.popBranch:
        return UnrouterMachineEventGroup.shell;
      case UnrouterMachineEvent.request:
      case UnrouterMachineEvent.requestDeduplicated:
      case UnrouterMachineEvent.resolveStart:
      case UnrouterMachineEvent.resolveCancelled:
      case UnrouterMachineEvent.resolveCancelledSignal:
      case UnrouterMachineEvent.resolveFinished:
      case UnrouterMachineEvent.redirectMissingTarget:
      case UnrouterMachineEvent.redirectDiagnosticsError:
      case UnrouterMachineEvent.redirectAccepted:
      case UnrouterMachineEvent.blockedFallback:
      case UnrouterMachineEvent.blockedNoop:
      case UnrouterMachineEvent.blockedUnmatched:
      case UnrouterMachineEvent.commit:
      case UnrouterMachineEvent.redirectRegistered:
      case UnrouterMachineEvent.redirectChainCleared:
        return UnrouterMachineEventGroup.routeResolution;
    }
  }
}

/// Canonical machine state captured in each transition.
class UnrouterMachineState {
  const UnrouterMachineState({
    required this.uri,
    required this.resolution,
    required this.routePath,
    required this.routeName,
    required this.historyAction,
    required this.historyDelta,
    required this.historyIndex,
    required this.canGoBack,
  });

  static const Object _unset = Object();

  final Uri uri;
  final UnrouterResolutionState resolution;
  final String? routePath;
  final String? routeName;
  final HistoryAction historyAction;
  final int? historyDelta;
  final int? historyIndex;
  final bool canGoBack;

  /// Returns a copy with selected fields replaced.
  UnrouterMachineState copyWith({
    Uri? uri,
    UnrouterResolutionState? resolution,
    Object? routePath = _unset,
    Object? routeName = _unset,
    HistoryAction? historyAction,
    Object? historyDelta = _unset,
    Object? historyIndex = _unset,
    bool? canGoBack,
  }) {
    return UnrouterMachineState(
      uri: uri ?? this.uri,
      resolution: resolution ?? this.resolution,
      routePath: routePath == _unset ? this.routePath : routePath as String?,
      routeName: routeName == _unset ? this.routeName : routeName as String?,
      historyAction: historyAction ?? this.historyAction,
      historyDelta: historyDelta == _unset
          ? this.historyDelta
          : historyDelta as int?,
      historyIndex: historyIndex == _unset
          ? this.historyIndex
          : historyIndex as int?,
      canGoBack: canGoBack ?? this.canGoBack,
    );
  }

  /// Serializes state to JSON-like map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'uri': uri.toString(),
      'resolution': resolution.name,
      'routePath': routePath,
      'routeName': routeName,
      'historyAction': historyAction.name,
      'historyDelta': historyDelta,
      'historyIndex': historyIndex,
      'canGoBack': canGoBack,
    };
  }
}

/// Raw machine transition entry.
class UnrouterMachineTransitionEntry {
  const UnrouterMachineTransitionEntry({
    required this.sequence,
    required this.recordedAt,
    required this.source,
    required this.event,
    required this.from,
    required this.to,
    required this.payload,
  });

  final int sequence;
  final DateTime recordedAt;
  final UnrouterMachineSource source;
  final UnrouterMachineEvent event;
  final UnrouterMachineState from;
  final UnrouterMachineState to;
  final Map<String, Object?> payload;

  /// Typed projection of this transition entry.
  UnrouterMachineTypedTransition get typed {
    return UnrouterMachineTypedTransition.fromEntry(this);
  }

  /// Serializes transition entry to JSON-like map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'recordedAt': recordedAt.toIso8601String(),
      'source': source.name,
      'event': event.name,
      'eventGroup': event.group.name,
      'from': from.toJson(),
      'to': to.toJson(),
      'fromUri': from.uri.toString(),
      'toUri': to.uri.toString(),
      'payloadKind': typed.payload.kind.name,
      'payload': payload,
    };
  }
}

/// Discriminator for typed machine payload models.
enum UnrouterMachineTypedPayloadKind { generic, navigation, route, controller }

/// Base type for typed machine payload projections.
sealed class UnrouterMachineTypedPayload {
  const UnrouterMachineTypedPayload();

  UnrouterMachineTypedPayloadKind get kind;

  Map<String, Object?> toJson();
}

/// Fallback payload model when no specialized parser applies.
class UnrouterMachineGenericTypedPayload extends UnrouterMachineTypedPayload {
  const UnrouterMachineGenericTypedPayload(this.raw);

  final Map<String, Object?> raw;

  @override
  UnrouterMachineTypedPayloadKind get kind {
    return UnrouterMachineTypedPayloadKind.generic;
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{'kind': kind.name, 'raw': raw};
  }
}

/// Typed payload parser for navigation transitions.
class UnrouterMachineNavigationTypedPayload
    extends UnrouterMachineTypedPayload {
  const UnrouterMachineNavigationTypedPayload({
    required this.raw,
    required this.beforeAction,
    required this.afterAction,
    required this.beforeDelta,
    required this.afterDelta,
    required this.beforeHistoryIndex,
    required this.afterHistoryIndex,
    required this.beforeCanGoBack,
    required this.afterCanGoBack,
    required this.metadata,
  });

  factory UnrouterMachineNavigationTypedPayload.fromPayload(
    Map<String, Object?> payload,
  ) {
    final metadata = <String, Object?>{...payload}
      ..remove('beforeAction')
      ..remove('afterAction')
      ..remove('beforeDelta')
      ..remove('afterDelta')
      ..remove('beforeHistoryIndex')
      ..remove('afterHistoryIndex')
      ..remove('beforeCanGoBack')
      ..remove('afterCanGoBack');
    return UnrouterMachineNavigationTypedPayload(
      raw: Map<String, Object?>.unmodifiable(payload),
      beforeAction: _parseHistoryAction(payload['beforeAction']?.toString()),
      afterAction: _parseHistoryAction(payload['afterAction']?.toString()),
      beforeDelta: _toInt(payload['beforeDelta']),
      afterDelta: _toInt(payload['afterDelta']),
      beforeHistoryIndex: _toInt(payload['beforeHistoryIndex']),
      afterHistoryIndex: _toInt(payload['afterHistoryIndex']),
      beforeCanGoBack: _toBool(payload['beforeCanGoBack']),
      afterCanGoBack: _toBool(payload['afterCanGoBack']),
      metadata: Map<String, Object?>.unmodifiable(metadata),
    );
  }

  final Map<String, Object?> raw;
  final HistoryAction? beforeAction;
  final HistoryAction? afterAction;
  final int? beforeDelta;
  final int? afterDelta;
  final int? beforeHistoryIndex;
  final int? afterHistoryIndex;
  final bool? beforeCanGoBack;
  final bool? afterCanGoBack;
  final Map<String, Object?> metadata;

  @override
  UnrouterMachineTypedPayloadKind get kind {
    return UnrouterMachineTypedPayloadKind.navigation;
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.name,
      'beforeAction': beforeAction?.name,
      'afterAction': afterAction?.name,
      'beforeDelta': beforeDelta,
      'afterDelta': afterDelta,
      'beforeHistoryIndex': beforeHistoryIndex,
      'afterHistoryIndex': afterHistoryIndex,
      'beforeCanGoBack': beforeCanGoBack,
      'afterCanGoBack': afterCanGoBack,
      'metadata': metadata,
    };
  }

  static HistoryAction? _parseHistoryAction(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final action in HistoryAction.values) {
      if (action.name == value) {
        return action;
      }
    }
    return null;
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool? _toBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }
}

/// Typed payload parser for route-resolution transitions.
class UnrouterMachineRouteTypedPayload extends UnrouterMachineTypedPayload {
  const UnrouterMachineRouteTypedPayload({
    required this.raw,
    required this.generation,
    required this.requestUri,
    required this.targetUri,
    required this.toResolution,
    required this.reason,
    required this.hop,
    required this.maxHops,
    required this.metadata,
  });

  factory UnrouterMachineRouteTypedPayload.fromTransition(
    UnrouterMachineTransitionEntry entry,
  ) {
    final payload = entry.payload;
    final metadata = <String, Object?>{...payload}
      ..remove('generation')
      ..remove('reason')
      ..remove('hop')
      ..remove('maxHops');
    return UnrouterMachineRouteTypedPayload(
      raw: Map<String, Object?>.unmodifiable(payload),
      generation: _toInt(payload['generation']),
      requestUri: entry.from.uri,
      targetUri: entry.to.uri,
      toResolution: entry.to.resolution,
      reason: payload['reason']?.toString(),
      hop: _toInt(payload['hop']),
      maxHops: _toInt(payload['maxHops']),
      metadata: Map<String, Object?>.unmodifiable(metadata),
    );
  }

  final Map<String, Object?> raw;
  final int? generation;
  final Uri requestUri;
  final Uri targetUri;
  final UnrouterResolutionState toResolution;
  final String? reason;
  final int? hop;
  final int? maxHops;
  final Map<String, Object?> metadata;

  @override
  UnrouterMachineTypedPayloadKind get kind {
    return UnrouterMachineTypedPayloadKind.route;
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.name,
      'generation': generation,
      'requestUri': requestUri.toString(),
      'targetUri': targetUri.toString(),
      'toResolution': toResolution.name,
      'reason': reason,
      'hop': hop,
      'maxHops': maxHops,
      'metadata': metadata,
    };
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

/// Typed payload parser for controller lifecycle transitions.
class UnrouterMachineControllerTypedPayload
    extends UnrouterMachineTypedPayload {
  const UnrouterMachineControllerTypedPayload({
    required this.raw,
    required this.event,
    required this.historyAction,
    required this.historyDelta,
    required this.historyIndex,
    required this.canGoBack,
    required this.resolution,
    required this.enabled,
    required this.maxRedirectHops,
    required this.redirectLoopPolicy,
    required this.redirectDiagnosticsEnabled,
    required this.hadRouteMachine,
    required this.hadHistoryStateComposer,
    required this.hadCustomShellResolvers,
    required this.metadata,
  });

  factory UnrouterMachineControllerTypedPayload.fromTransition(
    UnrouterMachineTransitionEntry entry,
  ) {
    final payload = entry.payload;
    final metadata = <String, Object?>{...payload}
      ..remove('historyIndex')
      ..remove('enabled')
      ..remove('maxRedirectHops')
      ..remove('redirectLoopPolicy')
      ..remove('redirectDiagnosticsEnabled')
      ..remove('hadRouteMachine')
      ..remove('hadHistoryStateComposer')
      ..remove('hadCustomShellResolvers');
    return UnrouterMachineControllerTypedPayload(
      raw: Map<String, Object?>.unmodifiable(payload),
      event: entry.event,
      historyAction: entry.to.historyAction,
      historyDelta: entry.to.historyDelta,
      historyIndex: _toInt(payload['historyIndex']) ?? entry.to.historyIndex,
      canGoBack: entry.to.canGoBack,
      resolution: entry.to.resolution,
      enabled: _toBool(payload['enabled']),
      maxRedirectHops: _toInt(payload['maxRedirectHops']),
      redirectLoopPolicy: _parseRedirectLoopPolicy(
        payload['redirectLoopPolicy']?.toString(),
      ),
      redirectDiagnosticsEnabled: _toBool(
        payload['redirectDiagnosticsEnabled'],
      ),
      hadRouteMachine: _toBool(payload['hadRouteMachine']),
      hadHistoryStateComposer: _toBool(payload['hadHistoryStateComposer']),
      hadCustomShellResolvers: _toBool(payload['hadCustomShellResolvers']),
      metadata: Map<String, Object?>.unmodifiable(metadata),
    );
  }

  final Map<String, Object?> raw;
  final UnrouterMachineEvent event;
  final HistoryAction historyAction;
  final int? historyDelta;
  final int? historyIndex;
  final bool canGoBack;
  final UnrouterResolutionState resolution;
  final bool? enabled;
  final int? maxRedirectHops;
  final RedirectLoopPolicy? redirectLoopPolicy;
  final bool? redirectDiagnosticsEnabled;
  final bool? hadRouteMachine;
  final bool? hadHistoryStateComposer;
  final bool? hadCustomShellResolvers;
  final Map<String, Object?> metadata;

  @override
  UnrouterMachineTypedPayloadKind get kind {
    return UnrouterMachineTypedPayloadKind.controller;
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.name,
      'event': event.name,
      'historyAction': historyAction.name,
      'historyDelta': historyDelta,
      'historyIndex': historyIndex,
      'canGoBack': canGoBack,
      'resolution': resolution.name,
      'enabled': enabled,
      'maxRedirectHops': maxRedirectHops,
      'redirectLoopPolicy': redirectLoopPolicy?.name,
      'redirectDiagnosticsEnabled': redirectDiagnosticsEnabled,
      'hadRouteMachine': hadRouteMachine,
      'hadHistoryStateComposer': hadHistoryStateComposer,
      'hadCustomShellResolvers': hadCustomShellResolvers,
      'metadata': metadata,
    };
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool? _toBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  static RedirectLoopPolicy? _parseRedirectLoopPolicy(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final policy in RedirectLoopPolicy.values) {
      if (policy.name == value) {
        return policy;
      }
    }
    return null;
  }
}

/// Typed projection of [UnrouterMachineTransitionEntry].
class UnrouterMachineTypedTransition {
  const UnrouterMachineTypedTransition({
    required this.sequence,
    required this.recordedAt,
    required this.source,
    required this.event,
    required this.eventGroup,
    required this.from,
    required this.to,
    required this.payload,
  });

  factory UnrouterMachineTypedTransition.fromEntry(
    UnrouterMachineTransitionEntry entry,
  ) {
    final payload = switch (entry.source) {
      UnrouterMachineSource.navigation =>
        UnrouterMachineNavigationTypedPayload.fromPayload(entry.payload),
      UnrouterMachineSource.route =>
        UnrouterMachineRouteTypedPayload.fromTransition(entry),
      UnrouterMachineSource.controller =>
        UnrouterMachineControllerTypedPayload.fromTransition(entry),
    };
    return UnrouterMachineTypedTransition(
      sequence: entry.sequence,
      recordedAt: entry.recordedAt,
      source: entry.source,
      event: entry.event,
      eventGroup: entry.event.group,
      from: entry.from,
      to: entry.to,
      payload: payload,
    );
  }

  final int sequence;
  final DateTime recordedAt;
  final UnrouterMachineSource source;
  final UnrouterMachineEvent event;
  final UnrouterMachineEventGroup eventGroup;
  final UnrouterMachineState from;
  final UnrouterMachineState to;
  final UnrouterMachineTypedPayload payload;

  /// Serializes typed transition to JSON-like map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'recordedAt': recordedAt.toIso8601String(),
      'source': source.name,
      'event': event.name,
      'eventGroup': eventGroup.name,
      'from': from.toJson(),
      'to': to.toJson(),
      'fromUri': from.uri.toString(),
      'toUri': to.uri.toString(),
      'payload': payload.toJson(),
    };
  }
}

/// Runtime contract required by machine commands.
abstract interface class UnrouterMachineCommandRuntime
    implements MachineCommandRuntime {
  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult,
    Object? result,
  });

  void replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult,
    Object? result,
  });

  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state});

  bool pop([Object? result]);

  void popToUri(Uri uri, {Object? state, Object? result});

  bool back();

  void forward();

  void goDelta(int delta);

  bool switchBranch(
    int index, {
    bool initialLocation,
    bool completePendingResult,
    Object? result,
  });

  bool popBranch([Object? result]);
}

/// Host contract required by [UnrouterMachine].
abstract interface class UnrouterMachineHost<R extends RouteData>
    implements UnrouterMachineCommandRuntime {
  UnrouterMachineState get machineState;

  List<UnrouterMachineTransitionEntry> get machineTimeline;
}
