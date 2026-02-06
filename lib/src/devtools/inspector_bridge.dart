import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:unstory/unstory.dart';

import '../runtime/navigation.dart';
import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';

/// Trigger reason for one inspector bridge emission.
enum UnrouterInspectorEmissionReason {
  initial,
  stateChanged,
  redirectChanged,
  manual,
}

/// One emitted diagnostics payload from inspector bridge.
class UnrouterInspectorEmission {
  const UnrouterInspectorEmission({
    required this.reason,
    required this.recordedAt,
    required this.report,
  });

  final UnrouterInspectorEmissionReason reason;
  final DateTime recordedAt;
  final Map<String, Object?> report;

  /// Serializes emission to JSON-like map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'reason': reason.name,
      'recordedAt': recordedAt.toIso8601String(),
      'report': report,
    };
  }
}

/// Sink contract consumed by [UnrouterInspectorBridge].
abstract interface class UnrouterInspectorSink {
  void add(UnrouterInspectorEmission emission);
}

/// Sink that forwards structured emissions to callback.
class UnrouterInspectorCallbackSink implements UnrouterInspectorSink {
  const UnrouterInspectorCallbackSink(this._callback);

  final void Function(UnrouterInspectorEmission emission) _callback;

  @override
  void add(UnrouterInspectorEmission emission) {
    _callback(emission);
  }
}

/// Sink that forwards JSON-encoded emissions to callback.
class UnrouterInspectorJsonSink implements UnrouterInspectorSink {
  const UnrouterInspectorJsonSink(this._callback);

  final void Function(String payload) _callback;

  @override
  void add(UnrouterInspectorEmission emission) {
    _callback(jsonEncode(emission.toJson()));
  }
}

/// Filtering and sizing options for bridge emissions.
class UnrouterInspectorBridgeConfig {
  const UnrouterInspectorBridgeConfig({
    this.timelineTail = 10,
    this.redirectTrailTail = 5,
    this.machineTimelineTail = 20,
    this.machineQuery,
    this.machineSources,
    this.machineEvents,
    this.machineEventGroups,
    this.machinePayloadKinds,
    this.query,
    this.resolutions,
    this.actions,
    this.includeErrorsOnly = false,
    this.redirectQuery,
    this.redirectReasons,
  }) : assert(
         timelineTail > 0,
         'Unrouter inspector bridge timelineTail must be greater than zero.',
       ),
       assert(
         redirectTrailTail > 0,
         'Unrouter inspector bridge redirectTrailTail must be greater than zero.',
       ),
       assert(
         machineTimelineTail > 0,
         'Unrouter inspector bridge machineTimelineTail must be greater than zero.',
       );

  final int timelineTail;
  final int redirectTrailTail;
  final int machineTimelineTail;
  final String? machineQuery;
  final Set<UnrouterMachineSource>? machineSources;
  final Set<UnrouterMachineEvent>? machineEvents;
  final Set<UnrouterMachineEventGroup>? machineEventGroups;
  final Set<UnrouterMachineTypedPayloadKind>? machinePayloadKinds;
  final String? query;
  final Set<UnrouterResolutionState>? resolutions;
  final Set<HistoryAction>? actions;
  final bool includeErrorsOnly;
  final String? redirectQuery;
  final Set<RedirectDiagnosticsReason>? redirectReasons;

  static const Object _unset = Object();

  /// Returns a new config with updated fields.
  ///
  /// Nullable filters can be cleared by explicitly passing `null`.
  UnrouterInspectorBridgeConfig copyWith({
    int? timelineTail,
    int? redirectTrailTail,
    int? machineTimelineTail,
    Object? machineQuery = _unset,
    Object? machineSources = _unset,
    Object? machineEvents = _unset,
    Object? machineEventGroups = _unset,
    Object? machinePayloadKinds = _unset,
    Object? query = _unset,
    Object? resolutions = _unset,
    Object? actions = _unset,
    bool? includeErrorsOnly,
    Object? redirectQuery = _unset,
    Object? redirectReasons = _unset,
  }) {
    return UnrouterInspectorBridgeConfig(
      timelineTail: timelineTail ?? this.timelineTail,
      redirectTrailTail: redirectTrailTail ?? this.redirectTrailTail,
      machineTimelineTail: machineTimelineTail ?? this.machineTimelineTail,
      machineQuery: identical(machineQuery, _unset)
          ? this.machineQuery
          : machineQuery as String?,
      machineSources: identical(machineSources, _unset)
          ? this.machineSources
          : machineSources as Set<UnrouterMachineSource>?,
      machineEvents: identical(machineEvents, _unset)
          ? this.machineEvents
          : machineEvents as Set<UnrouterMachineEvent>?,
      machineEventGroups: identical(machineEventGroups, _unset)
          ? this.machineEventGroups
          : machineEventGroups as Set<UnrouterMachineEventGroup>?,
      machinePayloadKinds: identical(machinePayloadKinds, _unset)
          ? this.machinePayloadKinds
          : machinePayloadKinds as Set<UnrouterMachineTypedPayloadKind>?,
      query: identical(query, _unset) ? this.query : query as String?,
      resolutions: identical(resolutions, _unset)
          ? this.resolutions
          : resolutions as Set<UnrouterResolutionState>?,
      actions: identical(actions, _unset)
          ? this.actions
          : actions as Set<HistoryAction>?,
      includeErrorsOnly: includeErrorsOnly ?? this.includeErrorsOnly,
      redirectQuery: identical(redirectQuery, _unset)
          ? this.redirectQuery
          : redirectQuery as String?,
      redirectReasons: identical(redirectReasons, _unset)
          ? this.redirectReasons
          : redirectReasons as Set<RedirectDiagnosticsReason>?,
    );
  }
}

/// Connects [UnrouterInspector] to stream/sink based diagnostics pipelines.
class UnrouterInspectorBridge<R extends RouteData> {
  UnrouterInspectorBridge({
    required UnrouterInspector<R> inspector,
    this.redirectDiagnostics,
    this.config = const UnrouterInspectorBridgeConfig(),
    Iterable<UnrouterInspectorSink> sinks = const <UnrouterInspectorSink>[],
    bool emitInitial = true,
  }) : _inspector = inspector,
       _sinks = List<UnrouterInspectorSink>.from(sinks) {
    _inspector.stateListenable.addListener(_onStateChanged);
    redirectDiagnostics?.addListener(_onRedirectChanged);
    if (emitInitial) {
      emit(reason: UnrouterInspectorEmissionReason.initial);
    }
  }

  final UnrouterInspector<R> _inspector;
  final ValueListenable<List<RedirectDiagnostics>>? redirectDiagnostics;
  final List<UnrouterInspectorSink> _sinks;
  final StreamController<UnrouterInspectorEmission> _controller =
      StreamController<UnrouterInspectorEmission>.broadcast();

  UnrouterInspectorBridgeConfig config;
  bool _isDisposed = false;

  /// Broadcast stream of bridge emissions.
  Stream<UnrouterInspectorEmission> get stream => _controller.stream;

  /// Adds a sink target.
  void addSink(UnrouterInspectorSink sink) {
    if (_isDisposed) {
      return;
    }
    _sinks.add(sink);
  }

  /// Removes a sink target.
  bool removeSink(UnrouterInspectorSink sink) {
    if (_isDisposed) {
      return false;
    }
    return _sinks.remove(sink);
  }

  /// Replaces bridge config and optionally emits immediately.
  void updateConfig(
    UnrouterInspectorBridgeConfig next, {
    bool emitAfterUpdate = true,
  }) {
    if (_isDisposed) {
      return;
    }
    config = next;
    if (emitAfterUpdate) {
      emit(reason: UnrouterInspectorEmissionReason.manual);
    }
  }

  /// Convenience helper for updating machine event-group filter.
  void updateMachineEventGroups(
    Set<UnrouterMachineEventGroup>? machineEventGroups, {
    bool emitAfterUpdate = true,
  }) {
    updateConfig(
      config.copyWith(machineEventGroups: machineEventGroups),
      emitAfterUpdate: emitAfterUpdate,
    );
  }

  /// Convenience helper for updating machine payload-kind filter.
  void updateMachinePayloadKinds(
    Set<UnrouterMachineTypedPayloadKind>? machinePayloadKinds, {
    bool emitAfterUpdate = true,
  }) {
    updateConfig(
      config.copyWith(machinePayloadKinds: machinePayloadKinds),
      emitAfterUpdate: emitAfterUpdate,
    );
  }

  /// Emits one report using current [config].
  void emit({
    UnrouterInspectorEmissionReason reason =
        UnrouterInspectorEmissionReason.manual,
  }) {
    if (_isDisposed) {
      return;
    }

    final emission = UnrouterInspectorEmission(
      reason: reason,
      recordedAt: DateTime.now(),
      report: _inspector.debugReport(
        timelineTail: config.timelineTail,
        redirectDiagnostics:
            redirectDiagnostics?.value ?? const <RedirectDiagnostics>[],
        redirectTrailTail: config.redirectTrailTail,
        machineTimelineTail: config.machineTimelineTail,
        machineQuery: config.machineQuery,
        machineSources: config.machineSources,
        machineEvents: config.machineEvents,
        machineEventGroups: config.machineEventGroups,
        machinePayloadKinds: config.machinePayloadKinds,
        query: config.query,
        resolutions: config.resolutions,
        actions: config.actions,
        includeErrorsOnly: config.includeErrorsOnly,
        redirectQuery: config.redirectQuery,
        redirectReasons: config.redirectReasons,
      ),
    );

    _controller.add(emission);
    for (final sink in _sinks) {
      sink.add(emission);
    }
  }

  void _onStateChanged() {
    emit(reason: UnrouterInspectorEmissionReason.stateChanged);
  }

  void _onRedirectChanged() {
    emit(reason: UnrouterInspectorEmissionReason.redirectChanged);
  }

  /// Disposes listeners and stream resources.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _inspector.stateListenable.removeListener(_onStateChanged);
    redirectDiagnostics?.removeListener(_onRedirectChanged);
    _sinks.clear();
    unawaited(_controller.close());
  }
}
