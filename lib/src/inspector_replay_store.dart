import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'inspector_bridge.dart';
import 'navigation.dart';
import 'route_data.dart';

class UnrouterInspectorReplayStoreConfig {
  const UnrouterInspectorReplayStoreConfig({this.maxEntries = 5000})
    : assert(
        maxEntries > 0,
        'Unrouter inspector replay maxEntries must be greater than zero.',
      );

  final int maxEntries;
}

enum UnrouterInspectorReplayValidationSeverity { warning, error }

enum UnrouterInspectorReplayValidationIssueCode {
  machineTimelineMalformed,
  actionEnvelopeSchemaIncompatible,
  actionEnvelopeEventIncompatible,
  actionEnvelopeFailureMissing,
  controllerLifecycleCoverageMissing,
}

class UnrouterInspectorReplayValidationIssue {
  const UnrouterInspectorReplayValidationIssue({
    required this.sequence,
    required this.code,
    required this.severity,
    required this.message,
    this.machineEntryIndex,
    this.schemaVersion,
    this.eventVersion,
    this.machineEvent,
  });

  final int sequence;
  final UnrouterInspectorReplayValidationIssueCode code;
  final UnrouterInspectorReplayValidationSeverity severity;
  final String message;
  final int? machineEntryIndex;
  final int? schemaVersion;
  final int? eventVersion;
  final UnrouterMachineEvent? machineEvent;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'code': code.name,
      'severity': severity.name,
      'message': message,
      'machineEntryIndex': machineEntryIndex,
      'schemaVersion': schemaVersion,
      'eventVersion': eventVersion,
      'machineEvent': machineEvent?.name,
    };
  }
}

class UnrouterInspectorReplayValidationResult {
  const UnrouterInspectorReplayValidationResult({
    required this.entryCount,
    required this.issues,
  });

  final int entryCount;
  final List<UnrouterInspectorReplayValidationIssue> issues;

  bool get hasIssues => issues.isNotEmpty;

  int get errorCount {
    return issues
        .where(
          (issue) =>
              issue.severity == UnrouterInspectorReplayValidationSeverity.error,
        )
        .length;
  }

  int get warningCount {
    return issues
        .where(
          (issue) =>
              issue.severity ==
              UnrouterInspectorReplayValidationSeverity.warning,
        )
        .length;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'entryCount': entryCount,
      'issueCount': issues.length,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
    };
  }
}

class UnrouterInspectorReplayEntry {
  const UnrouterInspectorReplayEntry({
    required this.sequence,
    required this.emission,
  });

  final int sequence;
  final UnrouterInspectorEmission emission;

  Map<String, Object?> toJson() {
    return <String, Object?>{'sequence': sequence, ...emission.toJson()};
  }
}

class UnrouterInspectorReplayState {
  const UnrouterInspectorReplayState({
    required this.entries,
    required this.emittedCount,
    required this.droppedCount,
    required this.maxEntries,
    required this.isReplaying,
    required this.replayedCount,
  });

  factory UnrouterInspectorReplayState.initial({required int maxEntries}) {
    return UnrouterInspectorReplayState(
      entries: const <UnrouterInspectorReplayEntry>[],
      emittedCount: 0,
      droppedCount: 0,
      maxEntries: maxEntries,
      isReplaying: false,
      replayedCount: 0,
    );
  }

  static const Object _unset = Object();

  final List<UnrouterInspectorReplayEntry> entries;
  final int emittedCount;
  final int droppedCount;
  final int maxEntries;
  final bool isReplaying;
  final int replayedCount;

  bool get isEmpty => entries.isEmpty;

  bool get isNotEmpty => entries.isNotEmpty;

  UnrouterInspectorReplayEntry? get latestEntry {
    if (entries.isEmpty) {
      return null;
    }
    return entries.last;
  }

  UnrouterInspectorReplayState copyWith({
    List<UnrouterInspectorReplayEntry>? entries,
    int? emittedCount,
    int? droppedCount,
    int? maxEntries,
    Object? isReplaying = _unset,
    int? replayedCount,
  }) {
    return UnrouterInspectorReplayState(
      entries: entries ?? this.entries,
      emittedCount: emittedCount ?? this.emittedCount,
      droppedCount: droppedCount ?? this.droppedCount,
      maxEntries: maxEntries ?? this.maxEntries,
      isReplaying: isReplaying == _unset
          ? this.isReplaying
          : isReplaying as bool,
      replayedCount: replayedCount ?? this.replayedCount,
    );
  }
}

class UnrouterInspectorReplayStore
    implements ValueListenable<UnrouterInspectorReplayState> {
  UnrouterInspectorReplayStore({
    Stream<UnrouterInspectorEmission>? stream,
    this.config = const UnrouterInspectorReplayStoreConfig(),
  }) : _state = ValueNotifier<UnrouterInspectorReplayState>(
         UnrouterInspectorReplayState.initial(maxEntries: config.maxEntries),
       ) {
    if (stream != null) {
      _subscription = stream.listen(add);
    }
  }

  static const int schemaVersion = 1;

  final UnrouterInspectorReplayStoreConfig config;
  final ValueNotifier<UnrouterInspectorReplayState> _state;
  final StreamController<UnrouterInspectorEmission> _replayController =
      StreamController<UnrouterInspectorEmission>.broadcast();
  StreamSubscription<UnrouterInspectorEmission>? _subscription;
  int _replayToken = 0;
  bool _isDisposed = false;

  static UnrouterInspectorReplayStore fromBridge<R extends RouteData>({
    required UnrouterInspectorBridge<R> bridge,
    UnrouterInspectorReplayStoreConfig config =
        const UnrouterInspectorReplayStoreConfig(),
  }) {
    return UnrouterInspectorReplayStore(stream: bridge.stream, config: config);
  }

  ValueListenable<UnrouterInspectorReplayState> get listenable => this;

  @override
  UnrouterInspectorReplayState get value => _state.value;

  Stream<UnrouterInspectorEmission> get replayStream =>
      _replayController.stream;

  @override
  void addListener(VoidCallback listener) {
    _state.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _state.removeListener(listener);
  }

  void add(UnrouterInspectorEmission emission) {
    if (_isDisposed) {
      return;
    }
    final current = value;
    final sequence = current.emittedCount + 1;
    final normalized = _normalizeEmission(emission);
    final nextEntries = List<UnrouterInspectorReplayEntry>.from(current.entries)
      ..add(
        UnrouterInspectorReplayEntry(sequence: sequence, emission: normalized),
      );
    var droppedCount = current.droppedCount;
    if (nextEntries.length > config.maxEntries) {
      final removeCount = nextEntries.length - config.maxEntries;
      nextEntries.removeRange(0, removeCount);
      droppedCount += removeCount;
    }

    _state.value = current.copyWith(
      entries: List<UnrouterInspectorReplayEntry>.unmodifiable(nextEntries),
      emittedCount: sequence,
      droppedCount: droppedCount,
    );
  }

  void addAll(Iterable<UnrouterInspectorEmission> emissions) {
    for (final emission in emissions) {
      add(emission);
    }
  }

  void clear({bool resetCounters = false}) {
    if (_isDisposed) {
      return;
    }
    stopReplay();
    final current = value;
    _state.value = UnrouterInspectorReplayState(
      entries: const <UnrouterInspectorReplayEntry>[],
      emittedCount: resetCounters ? 0 : current.emittedCount,
      droppedCount: resetCounters ? 0 : current.droppedCount,
      maxEntries: current.maxEntries,
      isReplaying: false,
      replayedCount: 0,
    );
  }

  String exportJson({int? tail, bool pretty = false}) {
    if (tail != null) {
      assert(
        tail > 0,
        'Unrouter inspector replay export tail must be greater than zero.',
      );
      if (tail <= 0) {
        throw ArgumentError.value(
          tail,
          'tail',
          'Unrouter inspector replay export tail must be greater than zero.',
        );
      }
    }

    final entries = tail == null || value.entries.length <= tail
        ? value.entries
        : value.entries.sublist(value.entries.length - tail);
    final payload = <String, Object?>{
      'version': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'entryCount': entries.length,
      'emittedCount': value.emittedCount,
      'droppedCount': value.droppedCount,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(payload);
    }
    return jsonEncode(payload);
  }

  void importJson(String payload, {bool clearExisting = true}) {
    if (_isDisposed) {
      return;
    }

    final decoded = jsonDecode(payload);
    final rawEntries = _extractRawEntries(decoded);
    final parsed = _normalizeImportedEntries(
      rawEntries.map(_parseEntry).toList(growable: false),
    );

    if (clearExisting) {
      clear(resetCounters: true);
      _state.value = value.copyWith(
        entries: List<UnrouterInspectorReplayEntry>.unmodifiable(
          _trimToMax(parsed),
        ),
        emittedCount: parsed.isEmpty ? 0 : parsed.last.sequence,
        droppedCount: parsed.length > config.maxEntries
            ? parsed.length - config.maxEntries
            : 0,
        replayedCount: 0,
      );
      return;
    }

    addAll(parsed.map((entry) => entry.emission));
  }

  UnrouterInspectorReplayValidationResult validateCompatibility({
    Iterable<UnrouterInspectorReplayEntry>? entries,
    bool requireFailureForRejected = true,
    bool validateControllerLifecycleCoverage = true,
    Set<UnrouterMachineEvent>? requiredControllerLifecycleEvents,
  }) {
    final source = (entries ?? value.entries).toList(growable: false);
    final issues = <UnrouterInspectorReplayValidationIssue>[];
    final seenControllerLifecycleEvents = <UnrouterMachineEvent>{};
    var hasControllerLifecycleCoverageMarker = false;
    for (final replayEntry in source) {
      final machineTimeline = _asObjectList(
        replayEntry.emission.report['machineTimelineTail'],
      );
      if (machineTimeline == null) {
        continue;
      }

      for (
        var machineEntryIndex = 0;
        machineEntryIndex < machineTimeline.length;
        machineEntryIndex++
      ) {
        final rawMachineEntry = machineTimeline[machineEntryIndex];
        if (rawMachineEntry is! Map<Object?, Object?>) {
          issues.add(
            UnrouterInspectorReplayValidationIssue(
              sequence: replayEntry.sequence,
              code: UnrouterInspectorReplayValidationIssueCode
                  .machineTimelineMalformed,
              severity: UnrouterInspectorReplayValidationSeverity.warning,
              message: 'Machine timeline entry is not a map.',
              machineEntryIndex: machineEntryIndex,
            ),
          );
          continue;
        }

        final machineEntry = _normalizeObjectMap(rawMachineEntry);
        final machineEvent = _parseMachineEvent(machineEntry['event']);
        if (machineEvent != null && _isControllerLifecycleEvent(machineEvent)) {
          seenControllerLifecycleEvents.add(machineEvent);
          if (_isControllerLifecycleCoverageMarker(machineEvent)) {
            hasControllerLifecycleCoverageMarker = true;
          }
        }
        if (machineEntry['event']?.toString() !=
            UnrouterMachineEvent.actionEnvelope.name) {
          continue;
        }

        final payload = machineEntry['payload'];
        if (payload is! Map<Object?, Object?>) {
          issues.add(
            UnrouterInspectorReplayValidationIssue(
              sequence: replayEntry.sequence,
              code: UnrouterInspectorReplayValidationIssueCode
                  .machineTimelineMalformed,
              severity: UnrouterInspectorReplayValidationSeverity.error,
              message:
                  'Action-envelope machine timeline entry has invalid payload.',
              machineEntryIndex: machineEntryIndex,
            ),
          );
          continue;
        }

        final payloadMap = _normalizeObjectMap(payload);
        final envelopeMap = _extractEnvelopeMap(payloadMap['actionEnvelope']);
        final schemaVersion =
            _toInt(payloadMap['actionEnvelopeSchemaVersion']) ??
            _toInt(envelopeMap?['schemaVersion']);
        final eventVersion =
            _toInt(payloadMap['actionEnvelopeEventVersion']) ??
            _toInt(envelopeMap?['eventVersion']);
        final state =
            payloadMap['actionState']?.toString() ??
            envelopeMap?['state']?.toString();
        final failure = payloadMap['actionFailure'] ?? envelopeMap?['failure'];

        if (schemaVersion != null &&
            !UnrouterMachineActionEnvelope.isSchemaVersionCompatible(
              schemaVersion,
            )) {
          issues.add(
            UnrouterInspectorReplayValidationIssue(
              sequence: replayEntry.sequence,
              code: UnrouterInspectorReplayValidationIssueCode
                  .actionEnvelopeSchemaIncompatible,
              severity: UnrouterInspectorReplayValidationSeverity.error,
              message:
                  'Unsupported action-envelope schema version $schemaVersion.',
              machineEntryIndex: machineEntryIndex,
              schemaVersion: schemaVersion,
            ),
          );
        }

        if (eventVersion != null &&
            !UnrouterMachineActionEnvelope.isEventVersionCompatible(
              eventVersion,
            )) {
          issues.add(
            UnrouterInspectorReplayValidationIssue(
              sequence: replayEntry.sequence,
              code: UnrouterInspectorReplayValidationIssueCode
                  .actionEnvelopeEventIncompatible,
              severity: UnrouterInspectorReplayValidationSeverity.error,
              message:
                  'Unsupported action-envelope event version $eventVersion.',
              machineEntryIndex: machineEntryIndex,
              eventVersion: eventVersion,
            ),
          );
        }

        if (requireFailureForRejected &&
            state == UnrouterMachineActionEnvelopeState.rejected.name &&
            (schemaVersion == null || schemaVersion >= 2) &&
            failure is! Map<Object?, Object?> &&
            failure is! Map<String, Object?>) {
          issues.add(
            UnrouterInspectorReplayValidationIssue(
              sequence: replayEntry.sequence,
              code: UnrouterInspectorReplayValidationIssueCode
                  .actionEnvelopeFailureMissing,
              severity: UnrouterInspectorReplayValidationSeverity.warning,
              message:
                  'Rejected action-envelope entry is missing structured failure payload.',
              machineEntryIndex: machineEntryIndex,
              schemaVersion: schemaVersion,
              eventVersion: eventVersion,
            ),
          );
        }
      }
    }

    if (validateControllerLifecycleCoverage) {
      final requiredLifecycleEvents = _resolveRequiredControllerLifecycleEvents(
        requiredControllerLifecycleEvents: requiredControllerLifecycleEvents,
        hasCoverageMarker: hasControllerLifecycleCoverageMarker,
      );
      final issueSequence = source.isEmpty ? 0 : source.last.sequence;
      for (final event in requiredLifecycleEvents) {
        if (seenControllerLifecycleEvents.contains(event)) {
          continue;
        }
        issues.add(
          UnrouterInspectorReplayValidationIssue(
            sequence: issueSequence,
            code: UnrouterInspectorReplayValidationIssueCode
                .controllerLifecycleCoverageMissing,
            severity: UnrouterInspectorReplayValidationSeverity.warning,
            message:
                'Replay timeline is missing controller lifecycle event '
                '"${event.name}".',
            machineEvent: event,
          ),
        );
      }
    }

    return UnrouterInspectorReplayValidationResult(
      entryCount: source.length,
      issues: List<UnrouterInspectorReplayValidationIssue>.unmodifiable(issues),
    );
  }

  UnrouterInspectorReplayValidationResult validateActionEnvelopeCompatibility({
    Iterable<UnrouterInspectorReplayEntry>? entries,
    bool requireFailureForRejected = true,
    bool validateControllerLifecycleCoverage = true,
    Set<UnrouterMachineEvent>? requiredControllerLifecycleEvents,
  }) {
    return validateCompatibility(
      entries: entries,
      requireFailureForRejected: requireFailureForRejected,
      validateControllerLifecycleCoverage: validateControllerLifecycleCoverage,
      requiredControllerLifecycleEvents: requiredControllerLifecycleEvents,
    );
  }

  Future<int> replay({
    Duration step = Duration.zero,
    bool useRecordedIntervals = false,
    int? fromSequence,
    int? toSequence,
    ValueChanged<UnrouterInspectorEmission>? onEmission,
  }) async {
    assert(
      !step.isNegative,
      'Unrouter inspector replay step must not be negative.',
    );
    if (step.isNegative) {
      throw ArgumentError.value(
        step,
        'step',
        'Unrouter inspector replay step must not be negative.',
      );
    }
    if (_isDisposed || value.entries.isEmpty) {
      return 0;
    }

    final replayEntries = _entriesForReplay(
      value.entries,
      fromSequence: fromSequence,
      toSequence: toSequence,
    );
    if (replayEntries.isEmpty) {
      _state.value = value.copyWith(isReplaying: false, replayedCount: 0);
      return 0;
    }

    final token = ++_replayToken;
    _state.value = value.copyWith(isReplaying: true, replayedCount: 0);

    var delivered = 0;
    DateTime? previousRecordedAt;
    for (final entry in replayEntries) {
      if (_isDisposed || token != _replayToken) {
        break;
      }

      var delay = Duration.zero;
      if (delivered > 0) {
        if (useRecordedIntervals) {
          final previous = previousRecordedAt;
          if (previous != null) {
            final delta = entry.emission.recordedAt.difference(previous);
            delay = delta.isNegative ? Duration.zero : delta;
          }
        } else {
          delay = step;
        }
      }
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (_isDisposed || token != _replayToken) {
        break;
      }

      delivered += 1;
      previousRecordedAt = entry.emission.recordedAt;
      _replayController.add(entry.emission);
      onEmission?.call(entry.emission);
      _state.value = _state.value.copyWith(replayedCount: delivered);
    }

    if (!_isDisposed && token == _replayToken) {
      _state.value = _state.value.copyWith(isReplaying: false);
    }
    return delivered;
  }

  void stopReplay() {
    if (_isDisposed) {
      return;
    }
    _replayToken += 1;
    if (value.isReplaying) {
      _state.value = value.copyWith(isReplaying: false);
    }
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    stopReplay();
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    unawaited(_replayController.close());
    _state.dispose();
  }

  List<UnrouterInspectorReplayEntry> _entriesForReplay(
    List<UnrouterInspectorReplayEntry> entries, {
    int? fromSequence,
    int? toSequence,
  }) {
    return entries
        .where((entry) {
          if (fromSequence != null && entry.sequence < fromSequence) {
            return false;
          }
          if (toSequence != null && entry.sequence > toSequence) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<UnrouterInspectorReplayEntry> _trimToMax(
    List<UnrouterInspectorReplayEntry> entries,
  ) {
    if (entries.length <= config.maxEntries) {
      return entries;
    }
    return entries.sublist(entries.length - config.maxEntries);
  }

  List<UnrouterInspectorReplayEntry> _normalizeImportedEntries(
    List<UnrouterInspectorReplayEntry> entries,
  ) {
    var previousSequence = 0;
    return entries
        .map((entry) {
          var sequence = entry.sequence;
          if (sequence <= previousSequence) {
            sequence = previousSequence + 1;
          }
          previousSequence = sequence;
          return UnrouterInspectorReplayEntry(
            sequence: sequence,
            emission: entry.emission,
          );
        })
        .toList(growable: false);
  }

  UnrouterInspectorReplayEntry _parseEntry(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException(
        'Unrouter inspector replay entry must be a map.',
      );
    }
    final map = value;
    final reasonName = map['reason']?.toString();
    final reason = reasonName == null
        ? UnrouterInspectorEmissionReason.manual
        : _parseReason(reasonName);
    final recordedAtRaw = map['recordedAt']?.toString();
    final recordedAt = recordedAtRaw == null
        ? DateTime.now()
        : DateTime.tryParse(recordedAtRaw) ?? DateTime.now();
    final report = _normalizeReport(map['report']);
    final sequence = _toInt(map['sequence']) ?? 0;
    return UnrouterInspectorReplayEntry(
      sequence: sequence,
      emission: UnrouterInspectorEmission(
        reason: reason,
        recordedAt: recordedAt,
        report: report,
      ),
    );
  }

  List<Object?> _extractRawEntries(Object? decoded) {
    if (decoded is List<Object?>) {
      return decoded;
    }
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException(
        'Unrouter inspector replay payload must be a map or list.',
      );
    }
    final map = decoded;
    final entries = map['entries'];
    if (entries is List<Object?>) {
      return entries;
    }
    final emissions = map['emissions'];
    if (emissions is List<Object?>) {
      return emissions;
    }
    throw const FormatException(
      'Unrouter inspector replay payload must include entries/emissions list.',
    );
  }

  Map<String, Object?> _normalizeReport(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return const <String, Object?>{};
    }
    final next = <String, Object?>{};
    for (final entry in value.entries) {
      next['${entry.key}'] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(next);
  }

  UnrouterInspectorEmission _normalizeEmission(
    UnrouterInspectorEmission value,
  ) {
    return UnrouterInspectorEmission(
      reason: value.reason,
      recordedAt: value.recordedAt,
      report: _normalizeReport(value.report),
    );
  }

  UnrouterInspectorEmissionReason _parseReason(String value) {
    for (final reason in UnrouterInspectorEmissionReason.values) {
      if (reason.name == value) {
        return reason;
      }
    }
    return UnrouterInspectorEmissionReason.manual;
  }

  int? _toInt(Object? value) {
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

  List<Object?>? _asObjectList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }
    if (value is List) {
      return value.cast<Object?>();
    }
    return null;
  }

  Map<String, Object?> _normalizeObjectMap(Map<Object?, Object?> value) {
    final next = <String, Object?>{};
    for (final entry in value.entries) {
      next['${entry.key}'] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(next);
  }

  Map<String, Object?>? _extractEnvelopeMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return _normalizeObjectMap(value);
    }
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.unmodifiable(value);
    }
    return null;
  }

  UnrouterMachineEvent? _parseMachineEvent(Object? value) {
    if (value is UnrouterMachineEvent) {
      return value;
    }
    if (value is! String) {
      return null;
    }
    for (final event in UnrouterMachineEvent.values) {
      if (event.name == value) {
        return event;
      }
    }
    return null;
  }

  bool _isControllerLifecycleEvent(UnrouterMachineEvent event) {
    switch (event) {
      case UnrouterMachineEvent.initialized:
      case UnrouterMachineEvent.controllerRouteMachineConfigured:
      case UnrouterMachineEvent.controllerHistoryStateComposerChanged:
      case UnrouterMachineEvent.controllerShellResolversChanged:
      case UnrouterMachineEvent.controllerDisposed:
      case UnrouterMachineEvent.actionEnvelope:
        return true;
      case UnrouterMachineEvent.goUri:
      case UnrouterMachineEvent.replaceUri:
      case UnrouterMachineEvent.pushUri:
      case UnrouterMachineEvent.pop:
      case UnrouterMachineEvent.popToUri:
      case UnrouterMachineEvent.back:
      case UnrouterMachineEvent.forward:
      case UnrouterMachineEvent.goDelta:
      case UnrouterMachineEvent.switchBranch:
      case UnrouterMachineEvent.popBranch:
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
        return false;
    }
  }

  bool _isControllerLifecycleCoverageMarker(UnrouterMachineEvent event) {
    switch (event) {
      case UnrouterMachineEvent.controllerRouteMachineConfigured:
      case UnrouterMachineEvent.controllerHistoryStateComposerChanged:
      case UnrouterMachineEvent.controllerShellResolversChanged:
      case UnrouterMachineEvent.controllerDisposed:
        return true;
      case UnrouterMachineEvent.initialized:
      case UnrouterMachineEvent.actionEnvelope:
      case UnrouterMachineEvent.goUri:
      case UnrouterMachineEvent.replaceUri:
      case UnrouterMachineEvent.pushUri:
      case UnrouterMachineEvent.pop:
      case UnrouterMachineEvent.popToUri:
      case UnrouterMachineEvent.back:
      case UnrouterMachineEvent.forward:
      case UnrouterMachineEvent.goDelta:
      case UnrouterMachineEvent.switchBranch:
      case UnrouterMachineEvent.popBranch:
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
        return false;
    }
  }

  List<UnrouterMachineEvent> _resolveRequiredControllerLifecycleEvents({
    required Set<UnrouterMachineEvent>? requiredControllerLifecycleEvents,
    required bool hasCoverageMarker,
  }) {
    final explicit = requiredControllerLifecycleEvents;
    if (explicit != null) {
      if (explicit.isEmpty) {
        return const <UnrouterMachineEvent>[];
      }
      final filtered = UnrouterMachineEvent.values
          .where(_isControllerLifecycleEvent)
          .where(explicit.contains)
          .toList(growable: false);
      return filtered;
    }
    if (!hasCoverageMarker) {
      return const <UnrouterMachineEvent>[];
    }
    return const <UnrouterMachineEvent>[
      UnrouterMachineEvent.initialized,
      UnrouterMachineEvent.controllerRouteMachineConfigured,
    ];
  }
}
