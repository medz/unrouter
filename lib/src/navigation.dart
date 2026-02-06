import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

import 'redirect_diagnostics.dart';
import 'route_data.dart';
import 'route_information_provider.dart';

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

sealed class UnrouterMachineCommand<T> {
  const UnrouterMachineCommand();

  static UnrouterMachineCommand<Future<void>> routeRequest(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachineRouteRequestCommand(uri, state: state);
  }

  static UnrouterMachineCommand<void> goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineGoUriCommand(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  static UnrouterMachineCommand<void> replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineReplaceUriCommand(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  static UnrouterMachineCommand<Future<T?>> pushUri<T extends Object?>(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachinePushUriCommand<T>(uri, state: state);
  }

  static UnrouterMachineCommand<bool> pop([Object? result]) {
    return _UnrouterMachinePopCommand(result);
  }

  static UnrouterMachineCommand<void> popToUri(
    Uri uri, {
    Object? state,
    Object? result,
  }) {
    return _UnrouterMachinePopToUriCommand(uri, state: state, result: result);
  }

  static UnrouterMachineCommand<bool> back() {
    return const _UnrouterMachineBackCommand();
  }

  static UnrouterMachineCommand<void> forward() {
    return const _UnrouterMachineForwardCommand();
  }

  static UnrouterMachineCommand<void> goDelta(int delta) {
    return _UnrouterMachineGoDeltaCommand(delta);
  }

  static UnrouterMachineCommand<bool> switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineSwitchBranchCommand(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  static UnrouterMachineCommand<bool> popBranch([Object? result]) {
    return _UnrouterMachinePopBranchCommand(result);
  }

  UnrouterMachineEvent get event;

  T execute(UnrouterController<dynamic> controller);
}

final class _UnrouterMachineRouteRequestCommand
    extends UnrouterMachineCommand<Future<void>> {
  const _UnrouterMachineRouteRequestCommand(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.request;

  @override
  Future<void> execute(UnrouterController<dynamic> controller) {
    return controller._dispatchRouteRequest(uri, state: state);
  }
}

final class _UnrouterMachineGoUriCommand extends UnrouterMachineCommand<void> {
  const _UnrouterMachineGoUriCommand(
    this.uri, {
    this.state,
    this.completePendingResult = false,
    this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goUri;

  @override
  void execute(UnrouterController<dynamic> controller) {
    controller.goUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachineReplaceUriCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachineReplaceUriCommand(
    this.uri, {
    this.state,
    this.completePendingResult = false,
    this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.replaceUri;

  @override
  void execute(UnrouterController<dynamic> controller) {
    controller.replaceUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachinePushUriCommand<T extends Object?>
    extends UnrouterMachineCommand<Future<T?>> {
  const _UnrouterMachinePushUriCommand(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;

  @override
  Future<T?> execute(UnrouterController<dynamic> controller) {
    return controller.pushUri<T>(uri, state: state);
  }
}

final class _UnrouterMachinePopCommand extends UnrouterMachineCommand<bool> {
  const _UnrouterMachinePopCommand([this.result]);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pop;

  @override
  bool execute(UnrouterController<dynamic> controller) {
    return controller.pop<Object?>(result);
  }
}

final class _UnrouterMachinePopToUriCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachinePopToUriCommand(this.uri, {this.state, this.result});

  final Uri uri;
  final Object? state;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popToUri;

  @override
  void execute(UnrouterController<dynamic> controller) {
    controller.popToUri(uri, state: state, result: result);
  }
}

final class _UnrouterMachineBackCommand extends UnrouterMachineCommand<bool> {
  const _UnrouterMachineBackCommand();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.back;

  @override
  bool execute(UnrouterController<dynamic> controller) {
    return controller.back();
  }
}

final class _UnrouterMachineForwardCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachineForwardCommand();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.forward;

  @override
  void execute(UnrouterController<dynamic> controller) {
    controller.forward();
  }
}

final class _UnrouterMachineGoDeltaCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachineGoDeltaCommand(this.delta);

  final int delta;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goDelta;

  @override
  void execute(UnrouterController<dynamic> controller) {
    controller.goDelta(delta);
  }
}

final class _UnrouterMachineSwitchBranchCommand
    extends UnrouterMachineCommand<bool> {
  const _UnrouterMachineSwitchBranchCommand(
    this.index, {
    this.initialLocation = false,
    this.completePendingResult = false,
    this.result,
  });

  final int index;
  final bool initialLocation;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.switchBranch;

  @override
  bool execute(UnrouterController<dynamic> controller) {
    return controller.switchBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachinePopBranchCommand
    extends UnrouterMachineCommand<bool> {
  const _UnrouterMachinePopBranchCommand([this.result]);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popBranch;

  @override
  bool execute(UnrouterController<dynamic> controller) {
    return controller.popBranch(result);
  }
}

enum UnrouterMachineNavigateMode { go, replace }

sealed class UnrouterMachineAction<T> {
  const UnrouterMachineAction();

  static UnrouterMachineAction<Future<void>> routeRequest(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachineRouteRequestAction(uri, state: state);
  }

  static UnrouterMachineAction<void> navigateToUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  static UnrouterMachineAction<void> navigateUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
    UnrouterMachineNavigateMode mode = UnrouterMachineNavigateMode.go,
  }) {
    return _UnrouterMachineNavigateToUriAction(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: mode,
    );
  }

  static UnrouterMachineAction<void> navigateToRoute<R extends RouteData>(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateRoute(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  static UnrouterMachineAction<void> navigateRoute<R extends RouteData>(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
    UnrouterMachineNavigateMode mode = UnrouterMachineNavigateMode.go,
  }) {
    return _UnrouterMachineNavigateToRouteAction<R>(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: mode,
    );
  }

  static UnrouterMachineAction<Future<T?>> pushUri<T extends Object?>(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachinePushUriAction<T>(uri, state: state);
  }

  static UnrouterMachineAction<Future<T?>>
  pushRoute<R extends RouteData, T extends Object?>(R route, {Object? state}) {
    return _UnrouterMachinePushRouteAction<R, T>(route, state: state);
  }

  static UnrouterMachineAction<void> replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: UnrouterMachineNavigateMode.replace,
    );
  }

  static UnrouterMachineAction<void> replaceRoute<R extends RouteData>(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateRoute(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: UnrouterMachineNavigateMode.replace,
    );
  }

  static UnrouterMachineAction<bool> pop([Object? result]) {
    return _UnrouterMachinePopAction(result);
  }

  static UnrouterMachineAction<void> popToUri(
    Uri uri, {
    Object? state,
    Object? result,
  }) {
    return _UnrouterMachinePopToUriAction(uri, state: state, result: result);
  }

  static UnrouterMachineAction<bool> back() {
    return const _UnrouterMachineBackAction();
  }

  static UnrouterMachineAction<void> forward() {
    return const _UnrouterMachineForwardAction();
  }

  static UnrouterMachineAction<void> goDelta(int delta) {
    return _UnrouterMachineGoDeltaAction(delta);
  }

  static UnrouterMachineAction<bool> switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineSwitchBranchAction(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  static UnrouterMachineAction<bool> popBranch([Object? result]) {
    return _UnrouterMachinePopBranchAction(result);
  }

  UnrouterMachineEvent get event;

  UnrouterMachineCommand<T> toCommand();
}

final class _UnrouterMachineRouteRequestAction
    extends UnrouterMachineAction<Future<void>> {
  const _UnrouterMachineRouteRequestAction(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.request;

  @override
  UnrouterMachineCommand<Future<void>> toCommand() {
    return UnrouterMachineCommand.routeRequest(uri, state: state);
  }
}

final class _UnrouterMachineNavigateToUriAction
    extends UnrouterMachineAction<void> {
  const _UnrouterMachineNavigateToUriAction(
    this.uri, {
    this.state,
    this.completePendingResult = false,
    this.result,
    this.mode = UnrouterMachineNavigateMode.go,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;
  final UnrouterMachineNavigateMode mode;

  @override
  UnrouterMachineEvent get event {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineEvent.goUri,
      UnrouterMachineNavigateMode.replace => UnrouterMachineEvent.replaceUri,
    };
  }

  @override
  UnrouterMachineCommand<void> toCommand() {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineCommand.goUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
      UnrouterMachineNavigateMode.replace => UnrouterMachineCommand.replaceUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    };
  }
}

final class _UnrouterMachineNavigateToRouteAction<R extends RouteData>
    extends UnrouterMachineAction<void> {
  const _UnrouterMachineNavigateToRouteAction(
    this.route, {
    this.state,
    this.completePendingResult = false,
    this.result,
    this.mode = UnrouterMachineNavigateMode.go,
  });

  final R route;
  final Object? state;
  final bool completePendingResult;
  final Object? result;
  final UnrouterMachineNavigateMode mode;

  @override
  UnrouterMachineEvent get event {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineEvent.goUri,
      UnrouterMachineNavigateMode.replace => UnrouterMachineEvent.replaceUri,
    };
  }

  @override
  UnrouterMachineCommand<void> toCommand() {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineCommand.goUri(
        route.toUri(),
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
      UnrouterMachineNavigateMode.replace => UnrouterMachineCommand.replaceUri(
        route.toUri(),
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    };
  }
}

final class _UnrouterMachinePushUriAction<T extends Object?>
    extends UnrouterMachineAction<Future<T?>> {
  const _UnrouterMachinePushUriAction(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;

  @override
  UnrouterMachineCommand<Future<T?>> toCommand() {
    return UnrouterMachineCommand.pushUri<T>(uri, state: state);
  }
}

final class _UnrouterMachinePushRouteAction<
  R extends RouteData,
  T extends Object?
>
    extends UnrouterMachineAction<Future<T?>> {
  const _UnrouterMachinePushRouteAction(this.route, {this.state});

  final R route;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;

  @override
  UnrouterMachineCommand<Future<T?>> toCommand() {
    return UnrouterMachineCommand.pushUri<T>(route.toUri(), state: state);
  }
}

final class _UnrouterMachinePopAction extends UnrouterMachineAction<bool> {
  const _UnrouterMachinePopAction(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pop;

  @override
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.pop(result);
  }
}

final class _UnrouterMachinePopToUriAction extends UnrouterMachineAction<void> {
  const _UnrouterMachinePopToUriAction(this.uri, {this.state, this.result});

  final Uri uri;
  final Object? state;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popToUri;

  @override
  UnrouterMachineCommand<void> toCommand() {
    return UnrouterMachineCommand.popToUri(uri, state: state, result: result);
  }
}

final class _UnrouterMachineBackAction extends UnrouterMachineAction<bool> {
  const _UnrouterMachineBackAction();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.back;

  @override
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.back();
  }
}

final class _UnrouterMachineForwardAction extends UnrouterMachineAction<void> {
  const _UnrouterMachineForwardAction();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.forward;

  @override
  UnrouterMachineCommand<void> toCommand() {
    return UnrouterMachineCommand.forward();
  }
}

final class _UnrouterMachineGoDeltaAction extends UnrouterMachineAction<void> {
  const _UnrouterMachineGoDeltaAction(this.delta);

  final int delta;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goDelta;

  @override
  UnrouterMachineCommand<void> toCommand() {
    return UnrouterMachineCommand.goDelta(delta);
  }
}

final class _UnrouterMachineSwitchBranchAction
    extends UnrouterMachineAction<bool> {
  const _UnrouterMachineSwitchBranchAction(
    this.index, {
    this.initialLocation = false,
    this.completePendingResult = false,
    this.result,
  });

  final int index;
  final bool initialLocation;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.switchBranch;

  @override
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.switchBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachinePopBranchAction
    extends UnrouterMachineAction<bool> {
  const _UnrouterMachinePopBranchAction(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popBranch;

  @override
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.popBranch(result);
  }
}

enum UnrouterMachineActionEnvelopeState {
  accepted,
  rejected,
  deferred,
  completed,
}

enum UnrouterMachineActionRejectCode {
  unknown,
  noBackHistory,
  popRejected,
  branchUnavailable,
  branchEmpty,
  deferredError,
}

enum UnrouterMachineActionFailureCategory {
  unknown,
  history,
  shell,
  asynchronous,
}

class UnrouterMachineActionFailure {
  const UnrouterMachineActionFailure({
    required this.code,
    required this.message,
    required this.category,
    this.retryable = false,
    this.metadata = const <String, Object?>{},
  });

  final UnrouterMachineActionRejectCode code;
  final String message;
  final UnrouterMachineActionFailureCategory category;
  final bool retryable;
  final Map<String, Object?> metadata;

  static UnrouterMachineActionFailure? tryParse(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    final map = <String, Object?>{};
    for (final entry in value.entries) {
      map['${entry.key}'] = entry.value;
    }
    final code =
        tryParseCode(map['code']?.toString()) ??
        UnrouterMachineActionRejectCode.unknown;
    final message = map['message']?.toString() ?? map['reason']?.toString();
    final category =
        tryParseCategory(map['category']?.toString()) ?? _inferCategory(code);
    final retryable = _toBool(map['retryable']) ?? _inferRetryable(code);
    return UnrouterMachineActionFailure(
      code: code,
      message: message ?? 'Machine command returned false.',
      category: category,
      retryable: retryable,
      metadata: _toMetadataMap(map['metadata']),
    );
  }

  static UnrouterMachineActionRejectCode? tryParseCode(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final code in UnrouterMachineActionRejectCode.values) {
      if (code.name == value) {
        return code;
      }
    }
    return null;
  }

  static UnrouterMachineActionFailureCategory? tryParseCategory(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final category in UnrouterMachineActionFailureCategory.values) {
      if (category.name == value) {
        return category;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code.name,
      'message': message,
      'category': category.name,
      'retryable': retryable,
      'metadata': metadata,
    };
  }

  static UnrouterMachineActionFailureCategory _inferCategory(
    UnrouterMachineActionRejectCode code,
  ) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return UnrouterMachineActionFailureCategory.unknown;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
        return UnrouterMachineActionFailureCategory.history;
      case UnrouterMachineActionRejectCode.branchUnavailable:
      case UnrouterMachineActionRejectCode.branchEmpty:
        return UnrouterMachineActionFailureCategory.shell;
      case UnrouterMachineActionRejectCode.deferredError:
        return UnrouterMachineActionFailureCategory.asynchronous;
    }
  }

  static bool _inferRetryable(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return false;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
      case UnrouterMachineActionRejectCode.branchEmpty:
      case UnrouterMachineActionRejectCode.deferredError:
        return true;
    }
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

  static Map<String, Object?> _toMetadataMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return const <String, Object?>{};
    }
    final metadata = <String, Object?>{};
    for (final entry in value.entries) {
      metadata['${entry.key}'] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(metadata);
  }
}

class UnrouterMachineActionEnvelope<T> {
  static const int schemaVersion = 2;
  static const int minimumCompatibleSchemaVersion = 1;
  static const int eventVersion = 2;
  static const int minimumCompatibleEventVersion = 1;
  static const String producer = 'unrouter.machine';

  static bool isSchemaVersionCompatible(int version) {
    return version >= minimumCompatibleSchemaVersion &&
        version <= schemaVersion;
  }

  static bool isEventVersionCompatible(int version) {
    return version >= minimumCompatibleEventVersion && version <= eventVersion;
  }

  const UnrouterMachineActionEnvelope._({
    required this.state,
    required this.event,
    this.value,
    this.rejectCode,
    this.rejectReason,
    this.failure,
  });

  factory UnrouterMachineActionEnvelope.accepted({
    required UnrouterMachineEvent event,
    T? value,
  }) {
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.accepted,
      event: event,
      value: value,
    );
  }

  factory UnrouterMachineActionEnvelope.rejected({
    required UnrouterMachineEvent event,
    T? value,
    UnrouterMachineActionRejectCode? rejectCode,
    String? rejectReason,
    UnrouterMachineActionFailure? failure,
  }) {
    final resolvedFailure =
        failure ??
        _legacyFailureFromRejectFields(
          rejectCode: rejectCode,
          rejectReason: rejectReason,
        );
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.rejected,
      event: event,
      value: value,
      rejectCode: resolvedFailure?.code ?? rejectCode,
      rejectReason: resolvedFailure?.message ?? rejectReason,
      failure: resolvedFailure,
    );
  }

  factory UnrouterMachineActionEnvelope.deferred({
    required UnrouterMachineEvent event,
    required T value,
  }) {
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.deferred,
      event: event,
      value: value,
    );
  }

  factory UnrouterMachineActionEnvelope.completed({
    required UnrouterMachineEvent event,
    required T value,
  }) {
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.completed,
      event: event,
      value: value,
    );
  }

  final UnrouterMachineActionEnvelopeState state;
  final UnrouterMachineEvent event;
  final T? value;
  final UnrouterMachineActionRejectCode? rejectCode;
  final String? rejectReason;
  final UnrouterMachineActionFailure? failure;

  bool get isAccepted {
    return state == UnrouterMachineActionEnvelopeState.accepted ||
        state == UnrouterMachineActionEnvelopeState.deferred ||
        state == UnrouterMachineActionEnvelopeState.completed;
  }

  bool get isRejected => state == UnrouterMachineActionEnvelopeState.rejected;

  bool get isDeferred => state == UnrouterMachineActionEnvelopeState.deferred;

  bool get isCompleted => state == UnrouterMachineActionEnvelopeState.completed;

  Map<String, Object?> toJson() {
    final value = this.value;
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'eventVersion': eventVersion,
      'producer': producer,
      'state': state.name,
      'event': event.name,
      'isAccepted': isAccepted,
      'isRejected': isRejected,
      'isDeferred': isDeferred,
      'isCompleted': isCompleted,
      'rejectCode': rejectCode?.name,
      'rejectReason': rejectReason,
      'failure': failure?.toJson(),
      'hasValue': value != null,
      'valueType': value?.runtimeType.toString(),
    };
  }

  static UnrouterMachineActionFailure? _legacyFailureFromRejectFields({
    required UnrouterMachineActionRejectCode? rejectCode,
    required String? rejectReason,
  }) {
    if (rejectCode == null && rejectReason == null) {
      return null;
    }
    final code = rejectCode ?? UnrouterMachineActionRejectCode.unknown;
    return UnrouterMachineActionFailure(
      code: code,
      message: rejectReason ?? 'Machine command returned false.',
      category: _defaultFailureCategory(code),
      retryable: _defaultRetryable(code),
    );
  }

  static UnrouterMachineActionFailureCategory _defaultFailureCategory(
    UnrouterMachineActionRejectCode code,
  ) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return UnrouterMachineActionFailureCategory.unknown;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
        return UnrouterMachineActionFailureCategory.history;
      case UnrouterMachineActionRejectCode.branchUnavailable:
      case UnrouterMachineActionRejectCode.branchEmpty:
        return UnrouterMachineActionFailureCategory.shell;
      case UnrouterMachineActionRejectCode.deferredError:
        return UnrouterMachineActionFailureCategory.asynchronous;
    }
  }

  static bool _defaultRetryable(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return false;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
      case UnrouterMachineActionRejectCode.branchEmpty:
      case UnrouterMachineActionRejectCode.deferredError:
        return true;
    }
  }
}

class UnrouterMachine<R extends RouteData> {
  const UnrouterMachine._(this._controller);

  final UnrouterController<R> _controller;

  UnrouterMachineState get state => _controller.machineState;

  List<UnrouterMachineTransitionEntry> get timeline {
    return _controller.machineTimeline;
  }

  List<UnrouterMachineTypedTransition> get typedTimeline {
    return _controller.machineTimeline
        .map((entry) => entry.typed)
        .toList(growable: false);
  }

  T dispatchTyped<T>(UnrouterMachineCommand<T> command) {
    return _controller.dispatchMachineCommand<T>(command);
  }

  Object? dispatch(UnrouterMachineCommand<dynamic> command) {
    return _controller.dispatchMachineCommand(command);
  }

  T dispatchAction<T>(UnrouterMachineAction<T> action) {
    return dispatchTyped(action.toCommand());
  }

  Object? dispatchActionUntyped(UnrouterMachineAction<dynamic> action) {
    return dispatch(action.toCommand());
  }

  UnrouterMachineActionEnvelope<T> dispatchActionEnvelope<T>(
    UnrouterMachineAction<T> action,
  ) {
    final value = dispatchAction<T>(action);
    final envelope = _resolveActionEnvelope(action.event, value);
    _controller.recordActionEnvelope(envelope);
    _recordDeferredSettlement(action.event, envelope);
    return envelope;
  }

  UnrouterMachineActionEnvelope<Object?> dispatchActionEnvelopeUntyped(
    UnrouterMachineAction<dynamic> action,
  ) {
    final value = dispatchActionUntyped(action);
    final envelope = _resolveActionEnvelope<Object?>(action.event, value);
    _controller.recordActionEnvelope(envelope);
    _recordDeferredSettlement(action.event, envelope);
    return envelope;
  }

  UnrouterMachineActionEnvelope<T> _resolveActionEnvelope<T>(
    UnrouterMachineEvent event,
    T value,
  ) {
    if (value is Future<Object?>) {
      return UnrouterMachineActionEnvelope<T>.deferred(
        event: event,
        value: value,
      );
    }
    if (value is bool && value == false) {
      return UnrouterMachineActionEnvelope<T>.rejected(
        event: event,
        value: value,
        failure: _resolveRejectFailure(event),
      );
    }
    if (value == null) {
      return UnrouterMachineActionEnvelope<T>.accepted(event: event);
    }
    return UnrouterMachineActionEnvelope<T>.completed(
      event: event,
      value: value,
    );
  }

  UnrouterMachineActionRejectCode _resolveRejectCode(
    UnrouterMachineEvent event,
  ) {
    switch (event) {
      case UnrouterMachineEvent.back:
        return UnrouterMachineActionRejectCode.noBackHistory;
      case UnrouterMachineEvent.pop:
        return UnrouterMachineActionRejectCode.popRejected;
      case UnrouterMachineEvent.switchBranch:
        return UnrouterMachineActionRejectCode.branchUnavailable;
      case UnrouterMachineEvent.popBranch:
        return UnrouterMachineActionRejectCode.branchEmpty;
      case UnrouterMachineEvent.initialized:
      case UnrouterMachineEvent.controllerRouteMachineConfigured:
      case UnrouterMachineEvent.controllerHistoryStateComposerChanged:
      case UnrouterMachineEvent.controllerShellResolversChanged:
      case UnrouterMachineEvent.controllerDisposed:
      case UnrouterMachineEvent.actionEnvelope:
      case UnrouterMachineEvent.goUri:
      case UnrouterMachineEvent.replaceUri:
      case UnrouterMachineEvent.pushUri:
      case UnrouterMachineEvent.popToUri:
      case UnrouterMachineEvent.forward:
      case UnrouterMachineEvent.goDelta:
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
        return UnrouterMachineActionRejectCode.unknown;
    }
  }

  String _resolveRejectReason(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return 'Machine command returned false.';
      case UnrouterMachineActionRejectCode.noBackHistory:
        return 'No history entry is available for back navigation.';
      case UnrouterMachineActionRejectCode.popRejected:
        return 'Pop was rejected because no pending push result can be completed.';
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return 'Target shell branch is unavailable.';
      case UnrouterMachineActionRejectCode.branchEmpty:
        return 'Active shell branch has no pop target.';
      case UnrouterMachineActionRejectCode.deferredError:
        return 'Deferred action future completed with an error.';
    }
  }

  UnrouterMachineActionFailure _resolveRejectFailure(
    UnrouterMachineEvent event,
  ) {
    final code = _resolveRejectCode(event);
    return UnrouterMachineActionFailure(
      code: code,
      message: _resolveRejectReason(code),
      category: _resolveRejectCategory(code),
      retryable: _resolveRejectRetryable(code),
    );
  }

  UnrouterMachineActionFailureCategory _resolveRejectCategory(
    UnrouterMachineActionRejectCode code,
  ) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return UnrouterMachineActionFailureCategory.unknown;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
        return UnrouterMachineActionFailureCategory.history;
      case UnrouterMachineActionRejectCode.branchUnavailable:
      case UnrouterMachineActionRejectCode.branchEmpty:
        return UnrouterMachineActionFailureCategory.shell;
      case UnrouterMachineActionRejectCode.deferredError:
        return UnrouterMachineActionFailureCategory.asynchronous;
    }
  }

  bool _resolveRejectRetryable(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return false;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
      case UnrouterMachineActionRejectCode.branchEmpty:
      case UnrouterMachineActionRejectCode.deferredError:
        return true;
    }
  }

  void _recordDeferredSettlement<T>(
    UnrouterMachineEvent event,
    UnrouterMachineActionEnvelope<T> envelope,
  ) {
    if (!envelope.isDeferred) {
      return;
    }
    final deferred = envelope.value;
    if (deferred is! Future<Object?>) {
      return;
    }
    final startedAt = DateTime.now();
    unawaited(
      deferred.then(
        (value) {
          _controller.recordActionEnvelope<Object?>(
            UnrouterMachineActionEnvelope<Object?>.completed(
              event: event,
              value: value,
            ),
            phase: 'settled',
            metadata: <String, Object?>{
              'deferredOutcome': 'completed',
              'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
            },
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          final failure = UnrouterMachineActionFailure(
            code: UnrouterMachineActionRejectCode.deferredError,
            message: '$error',
            category: UnrouterMachineActionFailureCategory.asynchronous,
            retryable: true,
            metadata: <String, Object?>{
              'errorType': error.runtimeType.toString(),
              'stackTrace': stackTrace.toString(),
            },
          );
          _controller.recordActionEnvelope<Object?>(
            UnrouterMachineActionEnvelope<Object?>.rejected(
              event: event,
              failure: failure,
            ),
            phase: 'settled',
            metadata: <String, Object?>{
              'deferredOutcome': 'rejected',
              'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
              'error': error.toString(),
              'errorType': error.runtimeType.toString(),
            },
          );
        },
      ),
    );
  }
}

sealed class _UnrouterNavigationMachineEvent {
  const _UnrouterNavigationMachineEvent();

  UnrouterMachineEvent get event;
}

final class _UnrouterMachineGoUriEvent extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineGoUriEvent({
    required this.uri,
    required this.state,
    required this.completePendingResult,
    required this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goUri;
}

final class _UnrouterMachineReplaceUriEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineReplaceUriEvent({
    required this.uri,
    required this.state,
    required this.completePendingResult,
    required this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.replaceUri;
}

final class _UnrouterMachinePushUriEvent<T extends Object?>
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePushUriEvent({required this.uri, required this.state});

  final Uri uri;
  final Object? state;

  Future<T?> execute(
    _UnrouterNavigationState navigationState,
    Object? composedState,
  ) {
    return navigationState.pushForResult<T>(uri, state: composedState);
  }

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;
}

final class _UnrouterMachinePopEvent extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePopEvent(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pop;
}

final class _UnrouterMachinePopToUriEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePopToUriEvent({
    required this.uri,
    required this.state,
    required this.result,
  });

  final Uri uri;
  final Object? state;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popToUri;
}

final class _UnrouterMachineBackEvent extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineBackEvent();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.back;
}

final class _UnrouterMachineForwardEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineForwardEvent();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.forward;
}

final class _UnrouterMachineGoDeltaEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineGoDeltaEvent(this.delta);

  final int delta;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goDelta;
}

final class _UnrouterMachineSwitchBranchEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineSwitchBranchEvent({
    required this.index,
    required this.initialLocation,
    required this.completePendingResult,
    required this.result,
  });

  final int index;
  final bool initialLocation;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.switchBranch;
}

final class _UnrouterMachinePopBranchEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePopBranchEvent(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popBranch;
}

class _UnrouterNavigationMachineState {
  const _UnrouterNavigationMachineState({
    required this.uri,
    required this.historyState,
    required this.lastAction,
    required this.lastDelta,
    required this.historyIndex,
    required this.canGoBack,
  });

  factory _UnrouterNavigationMachineState.fromProvider(
    UnrouterRouteInformationProvider provider,
  ) {
    return _UnrouterNavigationMachineState(
      uri: provider.value.uri,
      historyState: provider.value.state,
      lastAction: provider.lastAction,
      lastDelta: provider.lastDelta,
      historyIndex: provider.historyIndex,
      canGoBack: provider.canGoBack,
    );
  }

  final Uri uri;
  final Object? historyState;
  final HistoryAction lastAction;
  final int? lastDelta;
  final int? historyIndex;
  final bool canGoBack;
}

class _UnrouterNavigationMachineTransition {
  const _UnrouterNavigationMachineTransition({
    required this.sequence,
    required this.recordedAt,
    required this.event,
    required this.before,
    required this.after,
  });

  final int sequence;
  final DateTime recordedAt;
  final UnrouterMachineEvent event;
  final _UnrouterNavigationMachineState before;
  final _UnrouterNavigationMachineState after;
}

typedef _UnrouterHistoryStateComposerFn =
    Object? Function({
      required Uri uri,
      required HistoryAction action,
      required Object? state,
    });

class _UnrouterNavigationMachine {
  _UnrouterNavigationMachine({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required _UnrouterNavigationState navigationState,
    required _UnrouterHistoryStateComposerFn composeHistoryState,
    required Uri? Function(int index, {required bool initialLocation})
    resolveShellBranchTarget,
    required Uri? Function() popShellBranchTarget,
    required void Function(_UnrouterNavigationMachineTransition transition)
    onTransition,
    this.transitionLimit = 128,
  }) : assert(
         transitionLimit > 0,
         'Unrouter navigation machine transitionLimit must be greater than zero.',
       ),
       _routeInformationProvider = routeInformationProvider,
       _navigationState = navigationState,
       _composeHistoryState = composeHistoryState,
       _resolveShellBranchTarget = resolveShellBranchTarget,
       _popShellBranchTarget = popShellBranchTarget,
       _onTransition = onTransition,
       _state = _UnrouterNavigationMachineState.fromProvider(
         routeInformationProvider,
       ) {
    _appendTransition(
      _UnrouterNavigationMachineTransition(
        sequence: _sequence++,
        recordedAt: DateTime.now(),
        event: UnrouterMachineEvent.initialized,
        before: _state,
        after: _state,
      ),
    );
  }

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final _UnrouterNavigationState _navigationState;
  final _UnrouterHistoryStateComposerFn _composeHistoryState;
  final Uri? Function(int index, {required bool initialLocation})
  _resolveShellBranchTarget;
  final Uri? Function() _popShellBranchTarget;
  final void Function(_UnrouterNavigationMachineTransition transition)
  _onTransition;
  final int transitionLimit;
  final List<_UnrouterNavigationMachineTransition> _transitions =
      <_UnrouterNavigationMachineTransition>[];

  int _sequence = 0;
  _UnrouterNavigationMachineState _state;

  _UnrouterNavigationMachineState get state => _state;

  List<_UnrouterNavigationMachineTransition> get transitions {
    return List<_UnrouterNavigationMachineTransition>.unmodifiable(
      _transitions,
    );
  }

  Object? dispatch(_UnrouterNavigationMachineEvent event) {
    final before = _state;
    final result = switch (event) {
      _UnrouterMachineGoUriEvent() => _dispatchGo(event),
      _UnrouterMachineReplaceUriEvent() => _dispatchReplace(event),
      _UnrouterMachinePushUriEvent() => _dispatchPush(event),
      _UnrouterMachinePopEvent() => _dispatchPop(event),
      _UnrouterMachinePopToUriEvent() => _dispatchPopToUri(event),
      _UnrouterMachineBackEvent() => _dispatchBack(),
      _UnrouterMachineForwardEvent() => _dispatchForward(),
      _UnrouterMachineGoDeltaEvent() => _dispatchGoDelta(event),
      _UnrouterMachineSwitchBranchEvent() => _dispatchSwitchBranch(event),
      _UnrouterMachinePopBranchEvent() => _dispatchPopBranch(event),
    };

    _state = _UnrouterNavigationMachineState.fromProvider(
      _routeInformationProvider,
    );
    _appendTransition(
      _UnrouterNavigationMachineTransition(
        sequence: _sequence++,
        recordedAt: DateTime.now(),
        event: event.event,
        before: before,
        after: _state,
      ),
    );
    return result;
  }

  Object? _dispatchGo(_UnrouterMachineGoUriEvent event) {
    final composedState = _composeHistoryState(
      uri: event.uri,
      action: HistoryAction.replace,
      state: event.state,
    );
    if (event.completePendingResult) {
      _navigationState.replaceAsPop(
        event.uri,
        state: composedState,
        result: event.result,
      );
      return null;
    }

    _routeInformationProvider.replace(event.uri, state: composedState);
    return null;
  }

  Object? _dispatchReplace(_UnrouterMachineReplaceUriEvent event) {
    final composedState = _composeHistoryState(
      uri: event.uri,
      action: HistoryAction.replace,
      state: event.state,
    );
    if (event.completePendingResult) {
      _navigationState.replaceAsPop(
        event.uri,
        state: composedState,
        result: event.result,
      );
      return null;
    }

    _routeInformationProvider.replace(event.uri, state: composedState);
    return null;
  }

  Object _dispatchPush(_UnrouterMachinePushUriEvent event) {
    final composedState = _composeHistoryState(
      uri: event.uri,
      action: HistoryAction.push,
      state: event.state,
    );
    return event.execute(_navigationState, composedState);
  }

  bool _dispatchPop(_UnrouterMachinePopEvent event) {
    return _navigationState.popWithResult<Object?>(event.result);
  }

  Object? _dispatchPopToUri(_UnrouterMachinePopToUriEvent event) {
    _navigationState.replaceAsPop(
      event.uri,
      state: _composeHistoryState(
        uri: event.uri,
        action: HistoryAction.replace,
        state: event.state,
      ),
      result: event.result,
    );
    return null;
  }

  bool _dispatchBack() {
    if (!_routeInformationProvider.canGoBack) {
      return false;
    }
    _routeInformationProvider.back();
    return true;
  }

  Object? _dispatchForward() {
    _routeInformationProvider.forward();
    return null;
  }

  Object? _dispatchGoDelta(_UnrouterMachineGoDeltaEvent event) {
    _routeInformationProvider.go(event.delta);
    return null;
  }

  bool _dispatchSwitchBranch(_UnrouterMachineSwitchBranchEvent event) {
    Uri? target;
    try {
      target = _resolveShellBranchTarget(
        event.index,
        initialLocation: event.initialLocation,
      );
    } on RangeError {
      return false;
    } on ArgumentError {
      return false;
    }
    if (target == null) {
      return false;
    }

    final composedState = _composeHistoryState(
      uri: target,
      action: HistoryAction.replace,
      state: null,
    );
    if (event.completePendingResult) {
      _navigationState.replaceAsPop(
        target,
        state: composedState,
        result: event.result,
      );
      return true;
    }

    _routeInformationProvider.replace(target, state: composedState);
    return true;
  }

  bool _dispatchPopBranch(_UnrouterMachinePopBranchEvent event) {
    final target = _popShellBranchTarget();
    if (target == null) {
      return false;
    }

    _navigationState.replaceAsPop(
      target,
      state: _composeHistoryState(
        uri: target,
        action: HistoryAction.replace,
        state: null,
      ),
      result: event.result,
    );
    return true;
  }

  void _appendTransition(_UnrouterNavigationMachineTransition transition) {
    _transitions.add(transition);
    _onTransition(transition);
    if (_transitions.length > transitionLimit) {
      final removeCount = _transitions.length - transitionLimit;
      _transitions.removeRange(0, removeCount);
    }
  }

  void dispose() {
    _transitions.clear();
  }
}

class _UnrouterNavigationDispatchAdapter {
  const _UnrouterNavigationDispatchAdapter(this._machine);

  final _UnrouterNavigationMachine _machine;

  T dispatch<T>(_UnrouterNavigationMachineEvent event) {
    final result = _machine.dispatch(event);
    return result as T;
  }
}

class _UnrouterMachineTransitionStore {
  _UnrouterMachineTransitionStore({required this.limit})
    : assert(
        limit > 0,
        'Unrouter machineTimelineLimit must be greater than zero.',
      );

  final int limit;
  final List<UnrouterMachineTransitionEntry> _entries =
      <UnrouterMachineTransitionEntry>[];
  int _sequence = 0;

  List<UnrouterMachineTransitionEntry> get entries {
    return List<UnrouterMachineTransitionEntry>.unmodifiable(_entries);
  }

  void add({
    required UnrouterMachineSource source,
    required UnrouterMachineEvent event,
    required UnrouterMachineState from,
    required UnrouterMachineState to,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    _entries.add(
      UnrouterMachineTransitionEntry(
        sequence: _sequence++,
        recordedAt: DateTime.now(),
        source: source,
        event: event,
        from: from,
        to: to,
        payload: Map<String, Object?>.unmodifiable(
          Map<String, Object?>.from(payload),
        ),
      ),
    );
    if (_entries.length > limit) {
      final removeCount = _entries.length - limit;
      _entries.removeRange(0, removeCount);
    }
  }

  void clear() {
    _entries.clear();
  }
}

class _UnrouterMachineReducer {
  const _UnrouterMachineReducer({
    required UnrouterMachineState Function() stateGetter,
    required _UnrouterMachineTransitionStore transitionStore,
  }) : _stateGetter = stateGetter,
       _transitionStore = transitionStore;

  final UnrouterMachineState Function() _stateGetter;
  final _UnrouterMachineTransitionStore _transitionStore;

  void reduce({
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
    final baseline = _stateGetter();
    _transitionStore.add(
      source: source,
      event: event,
      from: _resolveMachineState(
        baseline,
        explicit: from,
        uri: fromUri,
        resolution: fromResolution,
      ),
      to: _resolveMachineState(
        baseline,
        explicit: to,
        uri: toUri,
        resolution: toResolution,
      ),
      payload: payload,
    );
  }

  UnrouterMachineState _resolveMachineState(
    UnrouterMachineState baseline, {
    required UnrouterMachineState? explicit,
    Uri? uri,
    UnrouterResolutionState? resolution,
  }) {
    final source = explicit ?? baseline;
    return source.copyWith(
      uri: uri ?? source.uri,
      resolution: resolution ?? source.resolution,
    );
  }
}

class _UnrouterRouteMachineTransition {
  const _UnrouterRouteMachineTransition({
    required this.event,
    required this.requestUri,
    required this.generation,
    this.targetUri,
    this.toResolution,
    this.payload = const <String, Object?>{},
  });

  final UnrouterMachineEvent event;
  final Uri requestUri;
  final int generation;
  final Uri? targetUri;
  final UnrouterResolutionState? toResolution;
  final Map<String, Object?> payload;
}

abstract interface class _UnrouterRouteMachineDriver {
  Future<void> resolveRequest(Uri uri, {Object? state});

  void dispose();
}

class _UnrouterRouteMachineDriverImpl<Resolution, ResolutionType extends Enum>
    implements _UnrouterRouteMachineDriver {
  _UnrouterRouteMachineDriverImpl({
    required UnrouterRouteInformationProvider routeInformationProvider,
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
    required void Function(_UnrouterRouteMachineTransition transition)
    onTransition,
    required int maxRedirectHops,
    required RedirectLoopPolicy redirectLoopPolicy,
    required RedirectDiagnosticsCallback? onRedirectDiagnostics,
  }) : _routeInformationProvider = routeInformationProvider,
       _resolver = resolver,
       _currentResolutionType = currentResolutionType,
       _currentResolutionUri = currentResolutionUri,
       _resolutionTypeOf = resolutionTypeOf,
       _resolutionUriOf = resolutionUriOf,
       _redirectUriOf = redirectUriOf,
       _isRedirect = isRedirect,
       _isBlocked = isBlocked,
       _buildUnmatchedResolution = buildUnmatchedResolution,
       _buildErrorResolution = buildErrorResolution,
       _mapResolutionType = mapResolutionType,
       _onCommit = onCommit,
       _onTransition = onTransition,
       _maxRedirectHops = maxRedirectHops,
       _redirectLoopPolicy = redirectLoopPolicy,
       _onRedirectDiagnostics = onRedirectDiagnostics;

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final Future<Resolution?> Function(
    Uri uri, {
    required bool Function() isCancelled,
  })
  _resolver;
  final ResolutionType Function() _currentResolutionType;
  final Uri Function() _currentResolutionUri;
  final ResolutionType Function(Resolution resolution) _resolutionTypeOf;
  final Uri Function(Resolution resolution) _resolutionUriOf;
  final Uri? Function(Resolution resolution) _redirectUriOf;
  final bool Function(ResolutionType type) _isRedirect;
  final bool Function(ResolutionType type) _isBlocked;
  final Resolution Function(Uri uri) _buildUnmatchedResolution;
  final Resolution Function(Uri uri, Object error, StackTrace stackTrace)
  _buildErrorResolution;
  final UnrouterResolutionState Function(ResolutionType type)
  _mapResolutionType;
  final void Function(Resolution resolution) _onCommit;
  final void Function(_UnrouterRouteMachineTransition transition) _onTransition;
  final int _maxRedirectHops;
  final RedirectLoopPolicy _redirectLoopPolicy;
  final RedirectDiagnosticsCallback? _onRedirectDiagnostics;

  int _generation = 0;
  bool _hasCommittedResolution = false;
  Uri? _resolvingUri;
  Future<void>? _resolvingFuture;
  _RedirectChainState? _redirectChain;

  @override
  Future<void> resolveRequest(Uri uri, {Object? state}) {
    final generationSnapshot = _generation;
    _emit(
      event: UnrouterMachineEvent.request,
      requestUri: uri,
      generation: generationSnapshot,
      payload: <String, Object?>{'hasState': state != null},
    );
    _prepareRedirectChain(uri, generation: generationSnapshot);

    final activeUri = _resolvingUri;
    final activeFuture = _resolvingFuture;
    if (activeUri != null &&
        activeFuture != null &&
        _isSameUri(activeUri, uri)) {
      _emit(
        event: UnrouterMachineEvent.requestDeduplicated,
        requestUri: uri,
        generation: generationSnapshot,
      );
      return activeFuture;
    }

    final request = _resolve(uri, state: state);
    _resolvingUri = uri;
    _resolvingFuture = request.whenComplete(() {
      if (identical(_resolvingFuture, request)) {
        _resolvingUri = null;
        _resolvingFuture = null;
      }
    });
    return _resolvingFuture!;
  }

  @override
  void dispose() {
    _resolvingUri = null;
    _resolvingFuture = null;
    _redirectChain = null;
  }

  Future<void> _resolve(Uri uri, {Object? state}) async {
    final generation = ++_generation;
    final previousType = _currentResolutionType();
    final previousUri = _currentResolutionUri();
    _emit(
      event: UnrouterMachineEvent.resolveStart,
      requestUri: uri,
      generation: generation,
      payload: <String, Object?>{'previousResolution': previousType.name},
    );

    bool isCancelled() {
      return generation != _generation;
    }

    final nextResolution = await _resolver(uri, isCancelled: isCancelled);

    if (nextResolution == null) {
      _emit(
        event: UnrouterMachineEvent.resolveCancelled,
        requestUri: uri,
        generation: generation,
      );
      return;
    }

    if (isCancelled()) {
      _emit(
        event: UnrouterMachineEvent.resolveCancelledSignal,
        requestUri: uri,
        generation: generation,
      );
      return;
    }

    final nextType = _resolutionTypeOf(nextResolution);
    final nextUri = _resolutionUriOf(nextResolution);
    _emit(
      event: UnrouterMachineEvent.resolveFinished,
      requestUri: uri,
      generation: generation,
      targetUri: nextUri,
      toResolution: _mapResolutionType(nextType),
    );

    if (_isRedirect(nextType)) {
      final redirectUri = _redirectUriOf(nextResolution);
      if (redirectUri == null) {
        _clearRedirectChain(generation: generation, requestUri: uri);
        _emit(
          event: UnrouterMachineEvent.redirectMissingTarget,
          requestUri: uri,
          generation: generation,
          toResolution: UnrouterResolutionState.error,
        );
        _commit(
          _buildErrorResolution(
            uri,
            StateError('Redirect resolution is missing target uri.'),
            StackTrace.current,
          ),
          generation: generation,
          requestUri: uri,
        );
        return;
      }

      final diagnostics = _registerRedirect(
        uri: uri,
        redirectUri: redirectUri,
        generation: generation,
      );
      if (diagnostics != null) {
        _reportRedirectDiagnostics(diagnostics);
        _clearRedirectChain(generation: generation, requestUri: uri);
        _emit(
          event: UnrouterMachineEvent.redirectDiagnosticsError,
          requestUri: uri,
          generation: generation,
          targetUri: redirectUri,
          toResolution: UnrouterResolutionState.error,
          payload: <String, Object?>{
            'reason': diagnostics.reason.name,
            'hop': diagnostics.hop,
            'maxHops': diagnostics.maxHops,
          },
        );
        _commit(
          _buildErrorResolution(
            uri,
            StateError(_buildRedirectErrorMessage(diagnostics)),
            StackTrace.current,
          ),
          generation: generation,
          requestUri: uri,
        );
        return;
      }

      _emit(
        event: UnrouterMachineEvent.redirectAccepted,
        requestUri: uri,
        generation: generation,
        targetUri: redirectUri,
        toResolution: UnrouterResolutionState.redirect,
      );
      _routeInformationProvider.replace(redirectUri, state: state);
      return;
    }

    if (_isBlocked(nextType)) {
      _clearRedirectChain(generation: generation, requestUri: uri);
      if (_hasCommittedResolution) {
        final fallbackUri = previousUri;
        if (!_isSameUri(uri, fallbackUri)) {
          _emit(
            event: UnrouterMachineEvent.blockedFallback,
            requestUri: uri,
            generation: generation,
            targetUri: fallbackUri,
            toResolution: UnrouterResolutionState.blocked,
          );
          _routeInformationProvider.replace(fallbackUri, state: state);
        } else {
          _emit(
            event: UnrouterMachineEvent.blockedNoop,
            requestUri: uri,
            generation: generation,
            targetUri: fallbackUri,
            toResolution: UnrouterResolutionState.blocked,
          );
        }
        return;
      }

      _emit(
        event: UnrouterMachineEvent.blockedUnmatched,
        requestUri: uri,
        generation: generation,
        toResolution: UnrouterResolutionState.unmatched,
      );
      _commit(
        _buildUnmatchedResolution(uri),
        generation: generation,
        requestUri: uri,
      );
      return;
    }

    _commit(nextResolution, generation: generation, requestUri: uri);
  }

  void _commit(
    Resolution resolution, {
    required int generation,
    required Uri requestUri,
  }) {
    _clearRedirectChain(generation: generation, requestUri: requestUri);
    _hasCommittedResolution = true;
    final type = _resolutionTypeOf(resolution);
    _emit(
      event: UnrouterMachineEvent.commit,
      requestUri: requestUri,
      generation: generation,
      targetUri: _resolutionUriOf(resolution),
      toResolution: _mapResolutionType(type),
    );
    _onCommit(resolution);
  }

  void _prepareRedirectChain(Uri incomingUri, {required int generation}) {
    final chain = _redirectChain;
    if (chain == null) {
      return;
    }

    final expected = chain.expectedNextUri;
    if (expected != null && _isSameUri(expected, incomingUri)) {
      chain.expectedNextUri = null;
      return;
    }

    _clearRedirectChain(generation: generation, requestUri: incomingUri);
  }

  RedirectDiagnostics? _registerRedirect({
    required Uri uri,
    required Uri redirectUri,
    required int generation,
  }) {
    var chain = _redirectChain;
    if (chain == null) {
      chain = _RedirectChainState.initial(uri);
      _redirectChain = chain;
    } else {
      chain.recordCurrent(uri);
    }

    chain.hops += 1;
    final trailCandidate = chain.trailWith(redirectUri);
    if (chain.hops > _maxRedirectHops) {
      return RedirectDiagnostics(
        reason: RedirectDiagnosticsReason.maxHopsExceeded,
        currentUri: uri,
        redirectUri: redirectUri,
        trail: trailCandidate,
        hop: chain.hops,
        maxHops: _maxRedirectHops,
        loopPolicy: _redirectLoopPolicy,
      );
    }

    final redirectKey = redirectUri.toString();
    if (_redirectLoopPolicy == RedirectLoopPolicy.error &&
        chain.seen.contains(redirectKey)) {
      return RedirectDiagnostics(
        reason: RedirectDiagnosticsReason.loopDetected,
        currentUri: uri,
        redirectUri: redirectUri,
        trail: trailCandidate,
        hop: chain.hops,
        maxHops: _maxRedirectHops,
        loopPolicy: _redirectLoopPolicy,
      );
    }

    chain.acceptRedirect(redirectUri);
    _emit(
      event: UnrouterMachineEvent.redirectRegistered,
      requestUri: uri,
      generation: generation,
      targetUri: redirectUri,
      toResolution: UnrouterResolutionState.redirect,
      payload: <String, Object?>{
        'hop': chain.hops,
        'maxHops': _maxRedirectHops,
      },
    );
    return null;
  }

  void _clearRedirectChain({required int generation, required Uri requestUri}) {
    if (_redirectChain == null) {
      return;
    }
    _emit(
      event: UnrouterMachineEvent.redirectChainCleared,
      requestUri: requestUri,
      generation: generation,
    );
    _redirectChain = null;
  }

  void _reportRedirectDiagnostics(RedirectDiagnostics diagnostics) {
    final callback = _onRedirectDiagnostics;
    if (callback == null) {
      return;
    }
    callback(diagnostics);
  }

  String _buildRedirectErrorMessage(RedirectDiagnostics diagnostics) {
    final trail = diagnostics.trail.map((uri) => uri.toString()).join(' -> ');
    switch (diagnostics.reason) {
      case RedirectDiagnosticsReason.loopDetected:
        return 'Redirect loop detected '
            '(policy: ${diagnostics.loopPolicy.name}, '
            'hop ${diagnostics.hop}/${diagnostics.maxHops}): $trail';
      case RedirectDiagnosticsReason.maxHopsExceeded:
        return 'Maximum redirect hops (${diagnostics.maxHops}) exceeded '
            'at hop ${diagnostics.hop} '
            '(policy: ${diagnostics.loopPolicy.name}): $trail';
    }
  }

  bool _isSameUri(Uri a, Uri b) {
    return a.toString() == b.toString();
  }

  void _emit({
    required UnrouterMachineEvent event,
    required Uri requestUri,
    required int generation,
    Uri? targetUri,
    UnrouterResolutionState? toResolution,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    _onTransition(
      _UnrouterRouteMachineTransition(
        event: event,
        requestUri: requestUri,
        generation: generation,
        targetUri: targetUri,
        toResolution: toResolution,
        payload: payload,
      ),
    );
  }
}

class _RedirectChainState {
  _RedirectChainState({required this.trail}) {
    seen = trail.map((uri) => uri.toString()).toSet();
  }

  factory _RedirectChainState.initial(Uri uri) {
    return _RedirectChainState(trail: <Uri>[uri]);
  }

  final List<Uri> trail;
  late final Set<String> seen;
  int hops = 0;
  Uri? expectedNextUri;

  void recordCurrent(Uri uri) {
    final uriKey = uri.toString();
    if (trail.isEmpty || trail.last.toString() != uriKey) {
      trail.add(uri);
    }
    seen.add(uriKey);
  }

  List<Uri> trailWith(Uri uri) {
    final uriKey = uri.toString();
    if (trail.isNotEmpty && trail.last.toString() == uriKey) {
      return List<Uri>.unmodifiable(trail);
    }
    return List<Uri>.unmodifiable(<Uri>[...trail, uri]);
  }

  void acceptRedirect(Uri redirectUri) {
    final redirectKey = redirectUri.toString();
    seen.add(redirectKey);
    if (trail.isEmpty || trail.last.toString() != redirectKey) {
      trail.add(redirectUri);
    }
    expectedNextUri = redirectUri;
  }
}

class UnrouterController<R extends RouteData> {
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

  UnrouterStateSnapshot<R> get state => _stateStore.current.cast<R>();

  UnrouterInspector<R> get inspector => UnrouterInspector<R>(this);

  ValueListenable<UnrouterStateSnapshot<R>> get stateListenable {
    return _stateListenable;
  }

  List<UnrouterStateTimelineEntry<R>> get stateTimeline {
    return List<UnrouterStateTimelineEntry<R>>.unmodifiable(
      _stateStore.timeline.map((entry) => entry.cast<R>()),
    );
  }

  List<UnrouterMachineTransitionEntry> get machineTimeline {
    return _machineStore.entries;
  }

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

  T dispatchMachineCommand<T>(UnrouterMachineCommand<T> command) {
    return command.execute(this);
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
    _navigationDispatch.dispatch<void>(
      _UnrouterMachineGoUriEvent(
        uri: uri,
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
    _navigationDispatch.dispatch<void>(
      _UnrouterMachineReplaceUriEvent(
        uri: uri,
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
    return _navigationDispatch.dispatch<Future<T?>>(
      _UnrouterMachinePushUriEvent<T>(uri: uri, state: state),
    );
  }

  bool pop<T extends Object?>([T? result]) {
    return _navigationDispatch.dispatch<bool>(_UnrouterMachinePopEvent(result));
  }

  void popToUri(Uri uri, {Object? state, Object? result}) {
    _navigationDispatch.dispatch<void>(
      _UnrouterMachinePopToUriEvent(state: state, uri: uri, result: result),
    );
  }

  bool back() {
    return _navigationDispatch.dispatch<bool>(
      const _UnrouterMachineBackEvent(),
    );
  }

  void forward() {
    _navigationDispatch.dispatch<void>(const _UnrouterMachineForwardEvent());
  }

  void goDelta(int delta) {
    _navigationDispatch.dispatch<void>(_UnrouterMachineGoDeltaEvent(delta));
  }

  bool switchBranch(
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

  bool popBranch([Object? result]) {
    return _navigationDispatch.dispatch<bool>(
      _UnrouterMachinePopBranchEvent(result),
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

class UnrouterInspector<R extends RouteData> {
  const UnrouterInspector(this._controller);

  final UnrouterController<R> _controller;

  UnrouterStateSnapshot<R> get state => _controller.state;

  ValueListenable<UnrouterStateSnapshot<R>> get stateListenable {
    return _controller.stateListenable;
  }

  List<UnrouterStateTimelineEntry<R>> get stateTimeline {
    return _controller.stateTimeline;
  }

  Map<String, Object?> debugState() {
    return _serializeSnapshot(_controller.state);
  }

  Map<String, Object?> debugMachineState() {
    return _controller.machineState.toJson();
  }

  List<Map<String, Object?>> debugTimeline({
    int? tail,
    String? query,
    Set<UnrouterResolutionState>? resolutions,
    Set<HistoryAction>? actions,
    bool includeErrorsOnly = false,
  }) {
    final timeline = _filterTimelineEntries(
      _controller.stateTimeline,
      query: query,
      resolutions: resolutions,
      actions: actions,
      includeErrorsOnly: includeErrorsOnly,
    );
    final entries = tail == null
        ? timeline
        : _tailEntries(
            timeline,
            tail,
            assertionMessage:
                'Unrouter inspector timeline tail must be greater than zero.',
          );
    return entries.map(_serializeTimelineEntry).toList();
  }

  List<Map<String, Object?>> debugMachineTimeline({
    int? tail,
    String? query,
    Set<UnrouterMachineSource>? sources,
    Set<UnrouterMachineEvent>? events,
    Set<UnrouterMachineEventGroup>? eventGroups,
    Set<UnrouterMachineTypedPayloadKind>? payloadKinds,
  }) {
    final filtered = _filterMachineTimelineEntries(
      _controller.machineTimeline,
      query: query,
      sources: sources,
      events: events,
      eventGroups: eventGroups,
      payloadKinds: payloadKinds,
    );
    final entries = tail == null
        ? filtered
        : _tailEntries(
            filtered,
            tail,
            assertionMessage:
                'Unrouter inspector machine timeline tail must be greater than zero.',
          );
    return entries.map((entry) => entry.toJson()).toList(growable: false);
  }

  List<Map<String, Object?>> debugTypedMachineTimeline({
    int? tail,
    String? query,
    Set<UnrouterMachineSource>? sources,
    Set<UnrouterMachineEvent>? events,
    Set<UnrouterMachineEventGroup>? eventGroups,
    Set<UnrouterMachineTypedPayloadKind>? payloadKinds,
  }) {
    final filtered = _filterMachineTimelineEntries(
      _controller.machineTimeline,
      query: query,
      sources: sources,
      events: events,
      eventGroups: eventGroups,
      payloadKinds: payloadKinds,
    );
    final entries = tail == null
        ? filtered
        : _tailEntries(
            filtered,
            tail,
            assertionMessage:
                'Unrouter inspector typed machine timeline tail must be greater than zero.',
          );
    return entries.map((entry) => entry.typed.toJson()).toList(growable: false);
  }

  List<Map<String, Object?>> debugRedirectDiagnostics(
    List<RedirectDiagnostics> diagnostics, {
    int? tail,
    String? query,
    Set<RedirectDiagnosticsReason>? reasons,
  }) {
    final filtered = _filterRedirectDiagnostics(
      diagnostics,
      query: query,
      reasons: reasons,
    );
    final entries = tail == null
        ? filtered
        : _tailEntries(
            filtered,
            tail,
            assertionMessage:
                'Unrouter inspector redirect tail must be greater than zero.',
          );
    return entries.map(_serializeRedirectDiagnostics).toList();
  }

  Map<String, Object?> debugReport({
    int timelineTail = 10,
    List<RedirectDiagnostics> redirectDiagnostics =
        const <RedirectDiagnostics>[],
    int redirectTrailTail = 5,
    int machineTimelineTail = 20,
    String? machineQuery,
    Set<UnrouterMachineSource>? machineSources,
    Set<UnrouterMachineEvent>? machineEvents,
    Set<UnrouterMachineEventGroup>? machineEventGroups,
    Set<UnrouterMachineTypedPayloadKind>? machinePayloadKinds,
    String? query,
    Set<UnrouterResolutionState>? resolutions,
    Set<HistoryAction>? actions,
    bool includeErrorsOnly = false,
    String? redirectQuery,
    Set<RedirectDiagnosticsReason>? redirectReasons,
  }) {
    final timeline = _tailEntries(
      _filterTimelineEntries(
        _controller.stateTimeline,
        query: query,
        resolutions: resolutions,
        actions: actions,
        includeErrorsOnly: includeErrorsOnly,
      ),
      timelineTail,
      assertionMessage:
          'Unrouter inspector timelineTail must be greater than zero.',
    );
    final redirectTrail = _tailEntries(
      _filterRedirectDiagnostics(
        redirectDiagnostics,
        query: redirectQuery,
        reasons: redirectReasons,
      ),
      redirectTrailTail,
      assertionMessage:
          'Unrouter inspector redirectTrailTail must be greater than zero.',
    );
    final machineTimeline = _tailEntries(
      _filterMachineTimelineEntries(
        _controller.machineTimeline,
        query: machineQuery,
        sources: machineSources,
        events: machineEvents,
        eventGroups: machineEventGroups,
        payloadKinds: machinePayloadKinds,
      ),
      machineTimelineTail,
      assertionMessage:
          'Unrouter inspector machineTimelineTail must be greater than zero.',
    );
    return <String, Object?>{
      ..._serializeSnapshot(_controller.state),
      'machineState': _controller.machineState.toJson(),
      'timelineLength': _controller.stateTimeline.length,
      'timelineTail': timeline.map(_serializeTimelineEntry).toList(),
      'redirectTrailLength': redirectDiagnostics.length,
      'redirectTrailTail': redirectTrail
          .map(_serializeRedirectDiagnostics)
          .toList(),
      'machineTimelineLength': _controller.machineTimeline.length,
      'machineTimelineTail': machineTimeline
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }

  String exportDebugReportJson({
    int timelineTail = 10,
    List<RedirectDiagnostics> redirectDiagnostics =
        const <RedirectDiagnostics>[],
    int redirectTrailTail = 5,
    int machineTimelineTail = 20,
    String? machineQuery,
    Set<UnrouterMachineSource>? machineSources,
    Set<UnrouterMachineEvent>? machineEvents,
    Set<UnrouterMachineEventGroup>? machineEventGroups,
    Set<UnrouterMachineTypedPayloadKind>? machinePayloadKinds,
    String? query,
    Set<UnrouterResolutionState>? resolutions,
    Set<HistoryAction>? actions,
    bool includeErrorsOnly = false,
    String? redirectQuery,
    Set<RedirectDiagnosticsReason>? redirectReasons,
  }) {
    return jsonEncode(
      debugReport(
        timelineTail: timelineTail,
        redirectDiagnostics: redirectDiagnostics,
        redirectTrailTail: redirectTrailTail,
        machineTimelineTail: machineTimelineTail,
        machineQuery: machineQuery,
        machineSources: machineSources,
        machineEvents: machineEvents,
        machineEventGroups: machineEventGroups,
        machinePayloadKinds: machinePayloadKinds,
        query: query,
        resolutions: resolutions,
        actions: actions,
        includeErrorsOnly: includeErrorsOnly,
        redirectQuery: redirectQuery,
        redirectReasons: redirectReasons,
      ),
    );
  }

  List<UnrouterStateTimelineEntry<R>> _filterTimelineEntries(
    List<UnrouterStateTimelineEntry<R>> timeline, {
    String? query,
    Set<UnrouterResolutionState>? resolutions,
    Set<HistoryAction>? actions,
    bool includeErrorsOnly = false,
  }) {
    final normalizedQuery = _normalizeQuery(query);
    return timeline.where((entry) {
      final snapshot = entry.snapshot;
      if (includeErrorsOnly && !snapshot.hasError) {
        return false;
      }
      if (resolutions != null &&
          resolutions.isNotEmpty &&
          !resolutions.contains(snapshot.resolution)) {
        return false;
      }
      if (actions != null &&
          actions.isNotEmpty &&
          !actions.contains(snapshot.lastAction)) {
        return false;
      }
      if (normalizedQuery != null &&
          !_timelineEntryMatchesQuery(entry, normalizedQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<RedirectDiagnostics> _filterRedirectDiagnostics(
    List<RedirectDiagnostics> diagnostics, {
    String? query,
    Set<RedirectDiagnosticsReason>? reasons,
  }) {
    final normalizedQuery = _normalizeQuery(query);
    return diagnostics.where((event) {
      if (reasons != null &&
          reasons.isNotEmpty &&
          !reasons.contains(event.reason)) {
        return false;
      }
      if (normalizedQuery != null &&
          !_redirectEventMatchesQuery(event, normalizedQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<UnrouterMachineTransitionEntry> _filterMachineTimelineEntries(
    List<UnrouterMachineTransitionEntry> timeline, {
    String? query,
    Set<UnrouterMachineSource>? sources,
    Set<UnrouterMachineEvent>? events,
    Set<UnrouterMachineEventGroup>? eventGroups,
    Set<UnrouterMachineTypedPayloadKind>? payloadKinds,
  }) {
    final normalizedQuery = _normalizeQuery(query);
    return timeline
        .where((entry) {
          if (sources != null &&
              sources.isNotEmpty &&
              !sources.contains(entry.source)) {
            return false;
          }
          if (events != null &&
              events.isNotEmpty &&
              !events.contains(entry.event)) {
            return false;
          }
          if (eventGroups != null &&
              eventGroups.isNotEmpty &&
              !eventGroups.contains(entry.event.group)) {
            return false;
          }
          if (payloadKinds != null &&
              payloadKinds.isNotEmpty &&
              !payloadKinds.contains(entry.typed.payload.kind)) {
            return false;
          }
          if (normalizedQuery != null &&
              !_machineTimelineEntryMatchesQuery(entry, normalizedQuery)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<T> _tailEntries<T>(
    List<T> timeline,
    int tail, {
    required String assertionMessage,
  }) {
    assert(tail > 0, assertionMessage);
    if (tail <= 0 || timeline.length <= tail) {
      return timeline;
    }
    return timeline.sublist(timeline.length - tail);
  }

  bool _timelineEntryMatchesQuery(
    UnrouterStateTimelineEntry<R> entry,
    String normalizedQuery,
  ) {
    final snapshot = entry.snapshot;
    final route = snapshot.route;
    return _containsQuery(snapshot.uri.toString(), normalizedQuery) ||
        _containsQuery(snapshot.resolution.name, normalizedQuery) ||
        _containsQuery(snapshot.routePath, normalizedQuery) ||
        _containsQuery(snapshot.routeName, normalizedQuery) ||
        _containsQuery(snapshot.lastAction.name, normalizedQuery) ||
        _containsQuery(snapshot.historyIndex, normalizedQuery) ||
        _containsQuery(route?.runtimeType.toString(), normalizedQuery) ||
        _containsQuery(route?.toUri().toString(), normalizedQuery) ||
        _containsQuery(snapshot.error?.toString(), normalizedQuery);
  }

  bool _redirectEventMatchesQuery(
    RedirectDiagnostics event,
    String normalizedQuery,
  ) {
    final trail = event.trail.map((uri) => uri.toString()).join(' -> ');
    return _containsQuery(event.reason.name, normalizedQuery) ||
        _containsQuery(event.currentUri.toString(), normalizedQuery) ||
        _containsQuery(event.redirectUri.toString(), normalizedQuery) ||
        _containsQuery(event.loopPolicy.name, normalizedQuery) ||
        _containsQuery(event.hop, normalizedQuery) ||
        _containsQuery(event.maxHops, normalizedQuery) ||
        _containsQuery(trail, normalizedQuery);
  }

  bool _machineTimelineEntryMatchesQuery(
    UnrouterMachineTransitionEntry entry,
    String normalizedQuery,
  ) {
    if (_containsQuery(entry.source.name, normalizedQuery) ||
        _containsQuery(entry.event.name, normalizedQuery) ||
        _containsQuery(entry.event.group.name, normalizedQuery) ||
        _containsQuery(entry.from.uri.toString(), normalizedQuery) ||
        _containsQuery(entry.to.uri.toString(), normalizedQuery)) {
      return true;
    }
    if (_containsQuery(entry.from.resolution.name, normalizedQuery) ||
        _containsQuery(entry.to.resolution.name, normalizedQuery) ||
        _containsQuery(entry.from.routePath, normalizedQuery) ||
        _containsQuery(entry.to.routePath, normalizedQuery) ||
        _containsQuery(entry.from.routeName, normalizedQuery) ||
        _containsQuery(entry.to.routeName, normalizedQuery) ||
        _containsQuery(entry.from.historyAction.name, normalizedQuery) ||
        _containsQuery(entry.to.historyAction.name, normalizedQuery)) {
      return true;
    }
    for (final value in entry.payload.values) {
      if (_containsQuery(value, normalizedQuery)) {
        return true;
      }
    }
    return false;
  }

  String? _normalizeQuery(String? query) {
    final value = query?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toLowerCase();
  }

  bool _containsQuery(Object? value, String normalizedQuery) {
    if (value == null) {
      return false;
    }
    return value.toString().toLowerCase().contains(normalizedQuery);
  }

  Map<String, Object?> _serializeTimelineEntry(
    UnrouterStateTimelineEntry<R> entry,
  ) {
    return <String, Object?>{
      'sequence': entry.sequence,
      'recordedAt': entry.recordedAt.toIso8601String(),
      ..._serializeSnapshot(entry.snapshot),
    };
  }

  Map<String, Object?> _serializeRedirectDiagnostics(
    RedirectDiagnostics event,
  ) {
    return <String, Object?>{
      'reason': event.reason.name,
      'currentUri': event.currentUri.toString(),
      'redirectUri': event.redirectUri.toString(),
      'trail': event.trail.map((uri) => uri.toString()).toList(),
      'hop': event.hop,
      'maxHops': event.maxHops,
      'loopPolicy': event.loopPolicy.name,
    };
  }

  Map<String, Object?> _serializeSnapshot(UnrouterStateSnapshot<R> snapshot) {
    final route = snapshot.route;
    return <String, Object?>{
      'uri': snapshot.uri.toString(),
      'resolution': snapshot.resolution.name,
      'routePath': snapshot.routePath,
      'routeName': snapshot.routeName,
      'routeType': route?.runtimeType.toString(),
      'routeUri': route?.toUri().toString(),
      'lastAction': snapshot.lastAction.name,
      'lastDelta': snapshot.lastDelta,
      'historyIndex': snapshot.historyIndex,
      'errorType': snapshot.error?.runtimeType.toString(),
      'error': snapshot.error?.toString(),
      'stackTrace': snapshot.stackTrace?.toString(),
    };
  }
}

class _UnrouterTypedStateListenable<R extends RouteData>
    implements ValueListenable<UnrouterStateSnapshot<R>> {
  const _UnrouterTypedStateListenable(this._source);

  final ValueListenable<UnrouterStateSnapshot<RouteData>> _source;

  @override
  UnrouterStateSnapshot<R> get value => _source.value.cast<R>();

  @override
  void addListener(VoidCallback listener) {
    _source.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _source.removeListener(listener);
  }
}

class _UnrouterStateStore {
  _UnrouterStateStore({
    required UnrouterStateSnapshot<RouteData> Function() stateGetter,
    required int timelineLimit,
  }) : assert(
         timelineLimit > 0,
         'Unrouter stateTimelineLimit must be greater than zero.',
       ),
       _stateGetter = stateGetter,
       _timelineLimit = timelineLimit,
       _current = ValueNotifier<UnrouterStateSnapshot<RouteData>>(
         stateGetter(),
       ) {
    _appendTimeline(_current.value);
  }

  final UnrouterStateSnapshot<RouteData> Function() _stateGetter;
  final int _timelineLimit;
  final ValueNotifier<UnrouterStateSnapshot<RouteData>> _current;
  final List<UnrouterStateTimelineEntry<RouteData>> _timeline =
      <UnrouterStateTimelineEntry<RouteData>>[];
  int _sequence = 0;
  bool _isDisposed = false;

  ValueListenable<UnrouterStateSnapshot<RouteData>> get listenable => _current;

  UnrouterStateSnapshot<RouteData> get current => _current.value;

  List<UnrouterStateTimelineEntry<RouteData>> get timeline => _timeline;

  void refresh() {
    if (_isDisposed) {
      return;
    }

    final next = _stateGetter();
    if (_isSameSnapshot(_current.value, next)) {
      return;
    }

    _current.value = next;
    _appendTimeline(next);
  }

  void clearTimeline() {
    if (_isDisposed) {
      return;
    }
    _timeline
      ..clear()
      ..add(
        UnrouterStateTimelineEntry<RouteData>(
          sequence: _sequence++,
          recordedAt: DateTime.now(),
          snapshot: _current.value,
        ),
      );
  }

  void _appendTimeline(UnrouterStateSnapshot<RouteData> snapshot) {
    _timeline.add(
      UnrouterStateTimelineEntry<RouteData>(
        sequence: _sequence++,
        recordedAt: DateTime.now(),
        snapshot: snapshot,
      ),
    );
    if (_timeline.length > _timelineLimit) {
      final removeCount = _timeline.length - _timelineLimit;
      _timeline.removeRange(0, removeCount);
    }
  }

  bool _isSameSnapshot(
    UnrouterStateSnapshot<RouteData> a,
    UnrouterStateSnapshot<RouteData> b,
  ) {
    return a.uri.toString() == b.uri.toString() &&
        _routeIdentity(a.route) == _routeIdentity(b.route) &&
        a.resolution == b.resolution &&
        a.routePath == b.routePath &&
        a.routeName == b.routeName &&
        a.error == b.error &&
        a.stackTrace == b.stackTrace &&
        a.lastAction == b.lastAction &&
        a.lastDelta == b.lastDelta &&
        a.historyIndex == b.historyIndex;
  }

  String? _routeIdentity(RouteData? route) {
    if (route == null) {
      return null;
    }
    return '${route.runtimeType}:${route.toUri()}';
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _timeline.clear();
    _current.dispose();
  }
}

class _UnrouterNavigationState {
  _UnrouterNavigationState(this._routeInformationProvider)
    : _trackedHistoryIndex = _routeInformationProvider.historyIndex ?? 0 {
    _routeInformationProvider.addListener(_onRouteInformationChanged);
  }

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final List<Completer<Object?>> _pendingPushResults = <Completer<Object?>>[];
  final ListQueue<Object?> _popResultQueue = ListQueue<Object?>();

  int _trackedHistoryIndex;
  bool _isDisposed = false;

  Future<T?> pushForResult<T extends Object?>(Uri uri, {Object? state}) {
    final completer = Completer<Object?>();
    _pendingPushResults.add(completer);
    _routeInformationProvider.push(uri, state: state);
    return completer.future.then((value) => value as T?);
  }

  bool popWithResult<T extends Object?>([T? result]) {
    if (!_routeInformationProvider.canGoBack) {
      return false;
    }

    _popResultQueue.addLast(result);
    _routeInformationProvider.back();
    return true;
  }

  void replaceAsPop(Uri uri, {Object? state, Object? result}) {
    _completeTopPending(result);
    _routeInformationProvider.replace(uri, state: state);
  }

  void _onRouteInformationChanged() {
    if (_isDisposed) {
      return;
    }

    final previousIndex = _trackedHistoryIndex;
    final action = _routeInformationProvider.lastAction;
    final nextIndex = _resolveHistoryIndex(
      fallbackIndex: previousIndex,
      historyIndex: _routeInformationProvider.historyIndex,
      action: action,
      delta: _routeInformationProvider.lastDelta,
    );

    if (action == HistoryAction.pop) {
      final poppedCount = _resolvePoppedCount(
        previousIndex: previousIndex,
        nextIndex: nextIndex,
        delta: _routeInformationProvider.lastDelta,
      );
      _completePoppedEntries(poppedCount);
    }

    _trackedHistoryIndex = nextIndex;
  }

  int _resolveHistoryIndex({
    required int fallbackIndex,
    required int? historyIndex,
    required HistoryAction action,
    required int? delta,
  }) {
    if (historyIndex != null) {
      return historyIndex;
    }

    switch (action) {
      case HistoryAction.push:
        return fallbackIndex + 1;
      case HistoryAction.replace:
        return fallbackIndex;
      case HistoryAction.pop:
        final movement = delta ?? 0;
        final next = fallbackIndex + movement;
        if (next < 0) {
          return 0;
        }
        return next;
    }
  }

  int _resolvePoppedCount({
    required int previousIndex,
    required int nextIndex,
    required int? delta,
  }) {
    if (delta != null) {
      if (delta < 0) {
        return -delta;
      }
      return 0;
    }

    if (nextIndex < previousIndex) {
      return previousIndex - nextIndex;
    }

    return 0;
  }

  void _completePoppedEntries(int poppedCount) {
    for (var i = 0; i < poppedCount; i++) {
      final result = i == 0 && _popResultQueue.isNotEmpty
          ? _popResultQueue.removeFirst()
          : null;
      _completeTopPending(result);
    }
  }

  void _completeTopPending(Object? result) {
    if (_pendingPushResults.isEmpty) {
      return;
    }

    final completer = _pendingPushResults.removeLast();
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _routeInformationProvider.removeListener(_onRouteInformationChanged);
    for (final completer in _pendingPushResults) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _pendingPushResults.clear();
    _popResultQueue.clear();
  }
}

class UnrouterScope extends InheritedWidget {
  const UnrouterScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final UnrouterController<RouteData> controller;

  static UnrouterController<RouteData> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UnrouterScope>();
    if (scope != null) {
      return scope.controller;
    }

    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('UnrouterScope was not found in context.'),
      ErrorDescription(
        'No Unrouter widget is available above this BuildContext.',
      ),
    ]);
  }

  static UnrouterController<R> ofAs<R extends RouteData>(BuildContext context) {
    return of(context).cast<R>();
  }

  @override
  bool updateShouldNotify(UnrouterScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

extension UnrouterBuildContextExtension on BuildContext {
  UnrouterController<RouteData> get unrouter => UnrouterScope.of(this);

  UnrouterMachine<RouteData> get unrouterMachine => unrouter.machine;

  UnrouterController<R> unrouterAs<R extends RouteData>() {
    return UnrouterScope.ofAs<R>(this);
  }

  UnrouterMachine<R> unrouterMachineAs<R extends RouteData>() {
    return unrouterAs<R>().machine;
  }
}
