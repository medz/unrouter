import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';
import '../platform/route_information_provider.dart';

part 'navigation_machine_commands_actions.dart';
part 'navigation_machine_envelope.dart';
part 'navigation_machine_api.dart';
part 'navigation_machine_runtime.dart';
part 'navigation_inspector.dart';
part 'navigation_state.dart';

enum UnrouterResolutionState {
  unknown,
  pending,
  matched,
  unmatched,
  redirect,
  blocked,
  error,
}

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

  bool get isPending => resolution == UnrouterResolutionState.pending;

  bool get isMatched => resolution == UnrouterResolutionState.matched;

  bool get isUnmatched => resolution == UnrouterResolutionState.unmatched;

  bool get isBlocked => resolution == UnrouterResolutionState.blocked;

  bool get hasError => resolution == UnrouterResolutionState.error;

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

class UnrouterStateTimelineEntry<R extends RouteData> {
  const UnrouterStateTimelineEntry({
    required this.sequence,
    required this.recordedAt,
    required this.snapshot,
  });

  final int sequence;
  final DateTime recordedAt;
  final UnrouterStateSnapshot<R> snapshot;

  UnrouterStateTimelineEntry<S> cast<S extends RouteData>() {
    return UnrouterStateTimelineEntry<S>(
      sequence: sequence,
      recordedAt: recordedAt,
      snapshot: snapshot.cast<S>(),
    );
  }
}

enum UnrouterMachineSource { controller, navigation, route }

enum UnrouterMachineEventGroup { lifecycle, navigation, shell, routeResolution }

enum UnrouterMachineEvent {
  initialized,
  controllerRouteMachineConfigured,
  controllerHistoryStateComposerChanged,
  controllerShellResolversChanged,
  controllerDisposed,
  actionEnvelope,
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

extension UnrouterMachineEventGrouping on UnrouterMachineEvent {
  UnrouterMachineEventGroup get group {
    switch (this) {
      case UnrouterMachineEvent.initialized:
      case UnrouterMachineEvent.controllerRouteMachineConfigured:
      case UnrouterMachineEvent.controllerHistoryStateComposerChanged:
      case UnrouterMachineEvent.controllerShellResolversChanged:
      case UnrouterMachineEvent.controllerDisposed:
      case UnrouterMachineEvent.actionEnvelope:
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

  UnrouterMachineTypedTransition get typed {
    return UnrouterMachineTypedTransition.fromEntry(this);
  }

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

enum UnrouterMachineTypedPayloadKind {
  generic,
  actionEnvelope,
  navigation,
  route,
  controller,
}

sealed class UnrouterMachineTypedPayload {
  const UnrouterMachineTypedPayload();

  UnrouterMachineTypedPayloadKind get kind;

  Map<String, Object?> toJson();
}

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

class UnrouterMachineActionEnvelopeTypedPayload
    extends UnrouterMachineTypedPayload {
  const UnrouterMachineActionEnvelopeTypedPayload({
    required this.raw,
    required this.schemaVersion,
    required this.eventVersion,
    required this.producer,
    required this.phase,
    required this.actionEvent,
    required this.actionState,
    required this.envelope,
    required this.failure,
    required this.rejectCode,
    required this.rejectReason,
    required this.metadata,
  });

  factory UnrouterMachineActionEnvelopeTypedPayload.fromPayload(
    Map<String, Object?> payload,
  ) {
    final envelope = _asMap(payload['actionEnvelope']);
    final actionEvent = _parseMachineEvent(
      payload['actionEvent']?.toString() ?? envelope?['event']?.toString(),
    );
    final actionState = _parseActionEnvelopeState(
      payload['actionState']?.toString() ?? envelope?['state']?.toString(),
    );
    final failure =
        UnrouterMachineActionFailure.tryParse(payload['actionFailure']) ??
        UnrouterMachineActionFailure.tryParse(envelope?['failure']);
    final metadata = <String, Object?>{...payload}
      ..remove('actionEnvelopeSchemaVersion')
      ..remove('actionEnvelopeEventVersion')
      ..remove('actionEnvelopeProducer')
      ..remove('actionEnvelopePhase')
      ..remove('actionEnvelope')
      ..remove('actionEvent')
      ..remove('actionState')
      ..remove('actionFailure')
      ..remove('actionFailureCategory')
      ..remove('actionFailureRetryable')
      ..remove('actionRejectCode')
      ..remove('actionRejectReason');
    return UnrouterMachineActionEnvelopeTypedPayload(
      raw: Map<String, Object?>.unmodifiable(payload),
      schemaVersion:
          _toInt(payload['actionEnvelopeSchemaVersion']) ??
          _toInt(envelope?['schemaVersion']),
      eventVersion:
          _toInt(payload['actionEnvelopeEventVersion']) ??
          _toInt(envelope?['eventVersion']),
      producer:
          payload['actionEnvelopeProducer']?.toString() ??
          envelope?['producer']?.toString(),
      phase: payload['actionEnvelopePhase']?.toString(),
      actionEvent: actionEvent,
      actionState: actionState,
      envelope: envelope == null
          ? null
          : Map<String, Object?>.unmodifiable(envelope),
      failure: failure,
      rejectCode:
          UnrouterMachineActionFailure.tryParseCode(
            payload['actionRejectCode']?.toString(),
          ) ??
          UnrouterMachineActionFailure.tryParseCode(
            envelope?['rejectCode']?.toString(),
          ),
      rejectReason:
          payload['actionRejectReason']?.toString() ??
          envelope?['rejectReason']?.toString(),
      metadata: Map<String, Object?>.unmodifiable(metadata),
    );
  }

  final Map<String, Object?> raw;
  final int? schemaVersion;
  final int? eventVersion;
  final String? producer;
  final String? phase;
  final UnrouterMachineEvent? actionEvent;
  final UnrouterMachineActionEnvelopeState? actionState;
  final Map<String, Object?>? envelope;
  final UnrouterMachineActionFailure? failure;
  final UnrouterMachineActionRejectCode? rejectCode;
  final String? rejectReason;
  final Map<String, Object?> metadata;

  @override
  UnrouterMachineTypedPayloadKind get kind {
    return UnrouterMachineTypedPayloadKind.actionEnvelope;
  }

  bool get isSchemaCompatible {
    final version = schemaVersion;
    if (version == null) {
      return true;
    }
    return UnrouterMachineActionEnvelope.isSchemaVersionCompatible(version);
  }

  bool get isEventCompatible {
    final version = eventVersion;
    if (version == null) {
      return true;
    }
    return UnrouterMachineActionEnvelope.isEventVersionCompatible(version);
  }

  @override
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.name,
      'schemaVersion': schemaVersion,
      'eventVersion': eventVersion,
      'producer': producer,
      'phase': phase,
      'actionEvent': actionEvent?.name,
      'actionState': actionState?.name,
      'isSchemaCompatible': isSchemaCompatible,
      'isEventCompatible': isEventCompatible,
      'rejectCode': rejectCode?.name,
      'rejectReason': rejectReason,
      'failure': failure?.toJson(),
      'envelope': envelope,
      'metadata': metadata,
    };
  }

  static Map<String, Object?>? _asMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    final next = <String, Object?>{};
    for (final entry in value.entries) {
      next['${entry.key}'] = entry.value;
    }
    return next;
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

  static UnrouterMachineEvent? _parseMachineEvent(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final event in UnrouterMachineEvent.values) {
      if (event.name == value) {
        return event;
      }
    }
    return null;
  }

  static UnrouterMachineActionEnvelopeState? _parseActionEnvelopeState(
    String? value,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final state in UnrouterMachineActionEnvelopeState.values) {
      if (state.name == value) {
        return state;
      }
    }
    return null;
  }
}

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
    final payload = switch (entry.event) {
      UnrouterMachineEvent.actionEnvelope =>
        UnrouterMachineActionEnvelopeTypedPayload.fromPayload(entry.payload),
      _ => switch (entry.source) {
        UnrouterMachineSource.navigation =>
          UnrouterMachineNavigationTypedPayload.fromPayload(entry.payload),
        UnrouterMachineSource.route =>
          UnrouterMachineRouteTypedPayload.fromTransition(entry),
        UnrouterMachineSource.controller =>
          UnrouterMachineControllerTypedPayload.fromTransition(entry),
      },
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

class UnrouterHistoryStateRequest {
  const UnrouterHistoryStateRequest({
    required this.uri,
    required this.action,
    required this.state,
    required this.currentState,
  });

  final Uri uri;
  final HistoryAction action;
  final Object? state;
  final Object? currentState;
}

typedef UnrouterHistoryStateComposer =
    Object? Function(UnrouterHistoryStateRequest request);

abstract interface class UnrouterInspectorSource<R extends RouteData> {
  UnrouterStateSnapshot<R> get state;

  ValueListenable<UnrouterStateSnapshot<R>> get stateListenable;

  List<UnrouterStateTimelineEntry<R>> get stateTimeline;

  UnrouterMachineState get machineState;

  List<UnrouterMachineTransitionEntry> get machineTimeline;
}

abstract interface class _UnrouterMachineCommandRuntime {
  Future<void> _dispatchRouteRequest(Uri uri, {Object? state});

  void _goUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult,
    Object? result,
  });

  void _replaceUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult,
    Object? result,
  });

  Future<T?> _pushUriViaRuntime<T extends Object?>(Uri uri, {Object? state});

  bool _popViaRuntime([Object? result]);

  void _popToUriViaRuntime(Uri uri, {Object? state, Object? result});

  bool _backViaRuntime();

  void _forwardViaRuntime();

  void _goDeltaViaRuntime(int delta);

  bool _switchBranchViaRuntime(
    int index, {
    bool initialLocation,
    bool completePendingResult,
    Object? result,
  });

  bool _popBranchViaRuntime([Object? result]);
}

abstract interface class _UnrouterMachineHost<R extends RouteData>
    implements _UnrouterMachineCommandRuntime {
  UnrouterMachineState get machineState;

  List<UnrouterMachineTransitionEntry> get machineTimeline;

  T dispatchMachineCommand<T>(UnrouterMachineCommand<T> command);

  void recordActionEnvelope<T>(
    UnrouterMachineActionEnvelope<T> envelope, {
    String phase,
    Map<String, Object?> metadata,
  });
}

class UnrouterController<R extends RouteData>
    implements UnrouterInspectorSource<R>, _UnrouterMachineHost<R> {
  UnrouterController({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required R? Function() routeGetter,
    required Uri Function() uriGetter,
    UnrouterStateSnapshot<RouteData> Function()? stateGetter,
    int stateTimelineLimit = 64,
    int machineTimelineLimit = 256,
  }) : this._(
         routeInformationProvider: routeInformationProvider,
         routeGetter: () => routeGetter(),
         uriGetter: uriGetter,
         stateGetter:
             stateGetter ??
             () => UnrouterStateSnapshot<RouteData>(
               uri: uriGetter(),
               route: routeGetter(),
               resolution: UnrouterResolutionState.unknown,
               routePath: null,
               routeName: null,
               error: null,
               stackTrace: null,
               lastAction: routeInformationProvider.lastAction,
               lastDelta: routeInformationProvider.lastDelta,
               historyIndex: routeInformationProvider.historyIndex,
             ),
         stateStore: _UnrouterStateStore(
           stateGetter:
               stateGetter ??
               () => UnrouterStateSnapshot<RouteData>(
                 uri: uriGetter(),
                 route: routeGetter(),
                 resolution: UnrouterResolutionState.unknown,
                 routePath: null,
                 routeName: null,
                 error: null,
                 stackTrace: null,
                 lastAction: routeInformationProvider.lastAction,
                 lastDelta: routeInformationProvider.lastDelta,
                 historyIndex: routeInformationProvider.historyIndex,
               ),
           timelineLimit: stateTimelineLimit,
         ),
         navigationState: _UnrouterNavigationState(routeInformationProvider),
         machineStore: _UnrouterMachineTransitionStore(
           limit: machineTimelineLimit,
         ),
       );

  UnrouterController._({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required RouteData? Function() routeGetter,
    required Uri Function() uriGetter,
    required UnrouterStateSnapshot<RouteData> Function() stateGetter,
    required _UnrouterStateStore stateStore,
    required _UnrouterNavigationState navigationState,
    required _UnrouterMachineTransitionStore machineStore,
    _UnrouterRouteMachineDriver? routeMachine,
    Uri? Function(int index, {required bool initialLocation})?
    shellBranchTargetResolver,
    Uri? Function()? shellBranchPopResolver,
    _UnrouterNavigationMachine? navigationMachine,
  }) : _routeInformationProvider = routeInformationProvider,
       _routeGetter = routeGetter,
       _uriGetter = uriGetter,
       _stateGetter = stateGetter,
       _stateStore = stateStore,
       _navigationState = navigationState,
       _machineStore = machineStore {
    if (shellBranchTargetResolver != null) {
      _shellBranchTargetResolver = shellBranchTargetResolver;
    }
    if (shellBranchPopResolver != null) {
      _shellBranchPopResolver = shellBranchPopResolver;
    }
    _routeMachine = routeMachine;
    _machineReducer = _UnrouterMachineReducer(
      stateGetter: _captureMachineState,
      transitionStore: _machineStore,
    );
    _navigationMachine =
        navigationMachine ??
        _UnrouterNavigationMachine(
          routeInformationProvider: _routeInformationProvider,
          navigationState: _navigationState,
          composeHistoryState: _composeHistoryStateAsMachine,
          resolveShellBranchTarget: _resolveShellBranchTarget,
          popShellBranchTarget: _popShellBranchTarget,
          onTransition: _recordNavigationMachineTransition,
        );
    _navigationDispatch = _UnrouterNavigationDispatchAdapter(
      _navigationMachine,
    );
    if (_machineStore.entries.isEmpty) {
      final current = _captureMachineState();
      recordMachineTransition(
        source: UnrouterMachineSource.controller,
        event: UnrouterMachineEvent.initialized,
        from: current,
        to: current,
        payload: <String, Object?>{
          'historyIndex': _routeInformationProvider.historyIndex,
        },
      );
    }
  }

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final RouteData? Function() _routeGetter;
  final Uri Function() _uriGetter;
  final UnrouterStateSnapshot<RouteData> Function() _stateGetter;
  final _UnrouterStateStore _stateStore;
  final _UnrouterNavigationState _navigationState;
  final _UnrouterMachineTransitionStore _machineStore;
  late final _UnrouterMachineReducer _machineReducer;
  late final _UnrouterNavigationMachine _navigationMachine;
  late final _UnrouterNavigationDispatchAdapter _navigationDispatch;
  UnrouterHistoryStateComposer? _historyStateComposer;
  _UnrouterRouteMachineDriver? _routeMachine;
  bool _isDisposed = false;
  Uri? Function(int index, {required bool initialLocation})
  _shellBranchTargetResolver = _defaultShellBranchTargetResolver;
  Uri? Function() _shellBranchPopResolver = _defaultShellBranchPopResolver;
  late final ValueListenable<UnrouterStateSnapshot<R>> _stateListenable =
      _UnrouterTypedStateListenable<R>(_stateStore.listenable);

  static Uri? _defaultShellBranchTargetResolver(
    int _, {
    required bool initialLocation,
  }) {
    return null;
  }

  static Uri? _defaultShellBranchPopResolver() {
    return null;
  }

  R? get route {
    final value = _routeGetter();
    if (value == null) {
      return null;
    }
    return value as R;
  }

  Uri get uri => _uriGetter();

  bool get canGoBack => _routeInformationProvider.canGoBack;

  HistoryAction get lastAction => _routeInformationProvider.lastAction;

  int? get lastDelta => _routeInformationProvider.lastDelta;

  int? get historyIndex => _routeInformationProvider.historyIndex;

  Object? get historyState => _routeInformationProvider.value.state;

  @override
  UnrouterStateSnapshot<R> get state => _stateStore.current.cast<R>();

  UnrouterInspector<R> get inspector => UnrouterInspector<R>(this);

  @override
  ValueListenable<UnrouterStateSnapshot<R>> get stateListenable {
    return _stateListenable;
  }

  @override
  List<UnrouterStateTimelineEntry<R>> get stateTimeline {
    return List<UnrouterStateTimelineEntry<R>>.unmodifiable(
      _stateStore.timeline.map((entry) => entry.cast<R>()),
    );
  }

  @override
  List<UnrouterMachineTransitionEntry> get machineTimeline {
    return _machineStore.entries;
  }

  @override
  UnrouterMachineState get machineState => _captureMachineState();

  UnrouterMachine<R> get machine => UnrouterMachine<R>._(this);

  void recordMachineTransition({
    required UnrouterMachineSource source,
    required UnrouterMachineEvent event,
    UnrouterMachineState? from,
    UnrouterMachineState? to,
    Uri? fromUri,
    Uri? toUri,
    UnrouterResolutionState? fromResolution,
    UnrouterResolutionState? toResolution,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    _machineReducer.reduce(
      source: source,
      event: event,
      from: from,
      to: to,
      fromUri: fromUri,
      toUri: toUri,
      fromResolution: fromResolution,
      toResolution: toResolution,
      payload: payload,
    );
  }

  @override
  void recordActionEnvelope<T>(
    UnrouterMachineActionEnvelope<T> envelope, {
    String phase = 'dispatch',
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final current = _captureMachineState();
    recordMachineTransition(
      source: UnrouterMachineSource.controller,
      event: UnrouterMachineEvent.actionEnvelope,
      from: current,
      to: current,
      payload: <String, Object?>{
        'actionEnvelopeSchemaVersion':
            UnrouterMachineActionEnvelope.schemaVersion,
        'actionEnvelopeEventVersion':
            UnrouterMachineActionEnvelope.eventVersion,
        'actionEnvelopeProducer': UnrouterMachineActionEnvelope.producer,
        'actionEnvelopePhase': phase,
        'actionEnvelope': envelope.toJson(),
        'actionEvent': envelope.event.name,
        'actionState': envelope.state.name,
        'actionFailure': envelope.failure?.toJson(),
        'actionFailureCategory': envelope.failure?.category.name,
        'actionFailureRetryable': envelope.failure?.retryable,
        'actionRejectCode': envelope.rejectCode?.name,
        'actionRejectReason': envelope.rejectReason,
        ...metadata,
      },
    );
  }

  @override
  T dispatchMachineCommand<T>(UnrouterMachineCommand<T> command) {
    return command._execute(this);
  }

  String href(R route) {
    return _routeInformationProvider.history.createHref(route.toUri());
  }

  String hrefUri(Uri uri) {
    return _routeInformationProvider.history.createHref(uri);
  }

  void go(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    goUri(
      route.toUri(),
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    dispatchMachineCommand<void>(
      UnrouterMachineCommand.goUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  void replace(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    replaceUri(
      route.toUri(),
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  void replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    dispatchMachineCommand<void>(
      UnrouterMachineCommand.replaceUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  Future<T?> push<T extends Object?>(R route, {Object? state}) {
    return pushUri<T>(route.toUri(), state: state);
  }

  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    return dispatchMachineCommand<Future<T?>>(
      UnrouterMachineCommand.pushUri<T>(uri, state: state),
    );
  }

  bool pop<T extends Object?>([T? result]) {
    return dispatchMachineCommand<bool>(UnrouterMachineCommand.pop(result));
  }

  void popToUri(Uri uri, {Object? state, Object? result}) {
    dispatchMachineCommand<void>(
      UnrouterMachineCommand.popToUri(uri, state: state, result: result),
    );
  }

  bool back() {
    return dispatchMachineCommand<bool>(UnrouterMachineCommand.back());
  }

  void forward() {
    dispatchMachineCommand<void>(UnrouterMachineCommand.forward());
  }

  void goDelta(int delta) {
    dispatchMachineCommand<void>(UnrouterMachineCommand.goDelta(delta));
  }

  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return dispatchMachineCommand<bool>(
      UnrouterMachineCommand.switchBranch(
        index,
        initialLocation: initialLocation,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  bool popBranch([Object? result]) {
    return dispatchMachineCommand<bool>(
      UnrouterMachineCommand.popBranch(result),
    );
  }

  UnrouterController<S> cast<S extends RouteData>() {
    return UnrouterController<S>._(
      routeInformationProvider: _routeInformationProvider,
      routeGetter: _routeGetter,
      uriGetter: _uriGetter,
      stateGetter: _stateGetter,
      stateStore: _stateStore,
      navigationState: _navigationState,
      machineStore: _machineStore,
      routeMachine: _routeMachine,
      shellBranchTargetResolver: _shellBranchTargetResolver,
      shellBranchPopResolver: _shellBranchPopResolver,
      navigationMachine: _navigationMachine,
    );
  }

  void setHistoryStateComposer(UnrouterHistoryStateComposer? composer) {
    _historyStateComposer = composer;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerHistoryStateComposerChanged,
      payload: <String, Object?>{'enabled': composer != null},
    );
  }

  void configureRouteMachine<Resolution, ResolutionType extends Enum>({
    required Future<Resolution?> Function(
      Uri uri, {
      required bool Function() isCancelled,
    })
    resolver,
    required ResolutionType Function() currentResolutionType,
    required Uri Function() currentResolutionUri,
    required ResolutionType Function(Resolution resolution) resolutionTypeOf,
    required Uri Function(Resolution resolution) resolutionUriOf,
    required Uri? Function(Resolution resolution) redirectUriOf,
    required bool Function(ResolutionType type) isRedirect,
    required bool Function(ResolutionType type) isBlocked,
    required Resolution Function(Uri uri) buildUnmatchedResolution,
    required Resolution Function(Uri uri, Object error, StackTrace stackTrace)
    buildErrorResolution,
    required UnrouterResolutionState Function(ResolutionType type)
    mapResolutionType,
    required void Function(Resolution resolution) onCommit,
    required int maxRedirectHops,
    required RedirectLoopPolicy redirectLoopPolicy,
    RedirectDiagnosticsCallback? onRedirectDiagnostics,
  }) {
    final hadRouteMachine = _routeMachine != null;
    _routeMachine?.dispose();
    _routeMachine = _UnrouterRouteMachineDriverImpl<Resolution, ResolutionType>(
      routeInformationProvider: _routeInformationProvider,
      resolver: resolver,
      currentResolutionType: currentResolutionType,
      currentResolutionUri: currentResolutionUri,
      resolutionTypeOf: resolutionTypeOf,
      resolutionUriOf: resolutionUriOf,
      redirectUriOf: redirectUriOf,
      isRedirect: isRedirect,
      isBlocked: isBlocked,
      buildUnmatchedResolution: buildUnmatchedResolution,
      buildErrorResolution: buildErrorResolution,
      mapResolutionType: mapResolutionType,
      onCommit: onCommit,
      onTransition: _recordRouteMachineTransition,
      maxRedirectHops: maxRedirectHops,
      redirectLoopPolicy: redirectLoopPolicy,
      onRedirectDiagnostics: onRedirectDiagnostics,
    );
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerRouteMachineConfigured,
      payload: <String, Object?>{
        'hadRouteMachine': hadRouteMachine,
        'maxRedirectHops': maxRedirectHops,
        'redirectLoopPolicy': redirectLoopPolicy.name,
        'redirectDiagnosticsEnabled': onRedirectDiagnostics != null,
      },
    );
  }

  void setShellBranchResolvers({
    required Uri? Function(int index, {required bool initialLocation})
    resolveTarget,
    required Uri? Function() popTarget,
  }) {
    _shellBranchTargetResolver = resolveTarget;
    _shellBranchPopResolver = popTarget;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerShellResolversChanged,
      payload: const <String, Object?>{'enabled': true},
    );
  }

  void clearShellBranchResolvers() {
    final hadCustomResolvers = _hasCustomShellBranchResolvers;
    _shellBranchTargetResolver = _defaultShellBranchTargetResolver;
    _shellBranchPopResolver = _defaultShellBranchPopResolver;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerShellResolversChanged,
      payload: <String, Object?>{
        'enabled': false,
        'hadCustomShellResolvers': hadCustomResolvers,
      },
    );
  }

  void clearHistoryStateComposer() {
    setHistoryStateComposer(null);
  }

  void publishState() {
    _stateStore.refresh();
  }

  void clearStateTimeline() {
    _stateStore.clearTimeline();
  }

  void clearMachineTimeline() {
    _machineStore.clear();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerDisposed,
      payload: <String, Object?>{
        'hadRouteMachine': _routeMachine != null,
        'hadHistoryStateComposer': _historyStateComposer != null,
        'hadCustomShellResolvers': _hasCustomShellBranchResolvers,
      },
    );
    _historyStateComposer = null;
    _routeMachine?.dispose();
    _routeMachine = null;
    _shellBranchTargetResolver = _defaultShellBranchTargetResolver;
    _shellBranchPopResolver = _defaultShellBranchPopResolver;
    _navigationMachine.dispose();
    _navigationState.dispose();
    _stateStore.dispose();
  }

  @override
  void _goUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _navigationDispatch.dispatch<void>(
      _UnrouterMachineGoUriEvent(
        uri: uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  @override
  void _replaceUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _navigationDispatch.dispatch<void>(
      _UnrouterMachineReplaceUriEvent(
        uri: uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  @override
  Future<T?> _pushUriViaRuntime<T extends Object?>(Uri uri, {Object? state}) {
    return _navigationDispatch.dispatch<Future<T?>>(
      _UnrouterMachinePushUriEvent<T>(uri: uri, state: state),
    );
  }

  @override
  bool _popViaRuntime([Object? result]) {
    return _navigationDispatch.dispatch<bool>(_UnrouterMachinePopEvent(result));
  }

  @override
  void _popToUriViaRuntime(Uri uri, {Object? state, Object? result}) {
    _navigationDispatch.dispatch<void>(
      _UnrouterMachinePopToUriEvent(state: state, uri: uri, result: result),
    );
  }

  @override
  bool _backViaRuntime() {
    return _navigationDispatch.dispatch<bool>(
      const _UnrouterMachineBackEvent(),
    );
  }

  @override
  void _forwardViaRuntime() {
    _navigationDispatch.dispatch<void>(const _UnrouterMachineForwardEvent());
  }

  @override
  void _goDeltaViaRuntime(int delta) {
    _navigationDispatch.dispatch<void>(_UnrouterMachineGoDeltaEvent(delta));
  }

  @override
  bool _switchBranchViaRuntime(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _navigationDispatch.dispatch<bool>(
      _UnrouterMachineSwitchBranchEvent(
        index: index,
        initialLocation: initialLocation,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  @override
  bool _popBranchViaRuntime([Object? result]) {
    return _navigationDispatch.dispatch<bool>(
      _UnrouterMachinePopBranchEvent(result),
    );
  }

  @override
  Future<void> _dispatchRouteRequest(Uri uri, {Object? state}) {
    final routeMachine = _routeMachine;
    if (routeMachine == null) {
      throw StateError('Route machine is not configured for this controller.');
    }
    return routeMachine.resolveRequest(uri, state: state);
  }

  Uri? _resolveShellBranchTarget(int index, {required bool initialLocation}) {
    return _shellBranchTargetResolver(index, initialLocation: initialLocation);
  }

  Uri? _popShellBranchTarget() {
    return _shellBranchPopResolver();
  }

  bool get _hasCustomShellBranchResolvers {
    return !identical(
          _shellBranchTargetResolver,
          _defaultShellBranchTargetResolver,
        ) ||
        !identical(_shellBranchPopResolver, _defaultShellBranchPopResolver);
  }

  void _recordControllerLifecycleTransition(
    UnrouterMachineEvent event, {
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    final current = _captureMachineState();
    recordMachineTransition(
      source: UnrouterMachineSource.controller,
      event: event,
      from: current,
      to: current,
      payload: payload,
    );
  }

  void _recordRouteMachineTransition(
    _UnrouterRouteMachineTransition transition,
  ) {
    recordMachineTransition(
      source: UnrouterMachineSource.route,
      event: transition.event,
      fromUri: transition.requestUri,
      toUri: transition.targetUri,
      toResolution: transition.toResolution,
      payload: <String, Object?>{
        'generation': transition.generation,
        ...transition.payload,
      },
    );
  }

  void _recordNavigationMachineTransition(
    _UnrouterNavigationMachineTransition transition,
  ) {
    final routeSnapshot = _stateStore.current;
    recordMachineTransition(
      source: UnrouterMachineSource.navigation,
      event: transition.event,
      from: _machineStateFromNavigation(
        transition.before,
        routeSnapshot: routeSnapshot,
      ),
      to: _machineStateFromNavigation(
        transition.after,
        routeSnapshot: routeSnapshot,
      ),
      payload: <String, Object?>{
        'beforeAction': transition.before.lastAction.name,
        'afterAction': transition.after.lastAction.name,
        'beforeDelta': transition.before.lastDelta,
        'afterDelta': transition.after.lastDelta,
        'beforeHistoryIndex': transition.before.historyIndex,
        'afterHistoryIndex': transition.after.historyIndex,
        'beforeCanGoBack': transition.before.canGoBack,
        'afterCanGoBack': transition.after.canGoBack,
      },
    );
  }

  UnrouterMachineState _captureMachineState() {
    final snapshot = _stateStore.current;
    return UnrouterMachineState(
      uri: snapshot.uri,
      resolution: snapshot.resolution,
      routePath: snapshot.routePath,
      routeName: snapshot.routeName,
      historyAction: snapshot.lastAction,
      historyDelta: snapshot.lastDelta,
      historyIndex: snapshot.historyIndex,
      canGoBack: _routeInformationProvider.canGoBack,
    );
  }

  UnrouterMachineState _machineStateFromNavigation(
    _UnrouterNavigationMachineState navigation, {
    required UnrouterStateSnapshot<RouteData> routeSnapshot,
  }) {
    return UnrouterMachineState(
      uri: navigation.uri,
      resolution: routeSnapshot.resolution,
      routePath: routeSnapshot.routePath,
      routeName: routeSnapshot.routeName,
      historyAction: navigation.lastAction,
      historyDelta: navigation.lastDelta,
      historyIndex: navigation.historyIndex,
      canGoBack: navigation.canGoBack,
    );
  }

  Object? _composeHistoryState({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
  }) {
    final composer = _historyStateComposer;
    if (composer == null) {
      return state;
    }

    return composer(
      UnrouterHistoryStateRequest(
        uri: uri,
        action: action,
        state: state,
        currentState: historyState,
      ),
    );
  }

  Object? _composeHistoryStateAsMachine({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
  }) {
    return _composeHistoryState(uri: uri, action: action, state: state);
  }
}
