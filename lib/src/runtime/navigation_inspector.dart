part of 'navigation.dart';

/// Debug and export facade for route/machine state timelines.
class UnrouterInspector<R extends RouteData> {
  const UnrouterInspector(this._source);

  final UnrouterInspectorSource<R> _source;

  /// Current route state snapshot.
  UnrouterStateSnapshot<R> get state => _source.state;

  ValueListenable<UnrouterStateSnapshot<R>> get stateListenable {
    return _source.stateListenable;
  }

  List<UnrouterStateTimelineEntry<R>> get stateTimeline {
    return _source.stateTimeline;
  }

  /// Returns current state as JSON-like map.
  Map<String, Object?> debugState() {
    return _serializeSnapshot(_source.state);
  }

  /// Returns current machine state as JSON-like map.
  Map<String, Object?> debugMachineState() {
    return _source.machineState.toJson();
  }

  /// Returns filtered route timeline entries.
  List<Map<String, Object?>> debugTimeline({
    int? tail,
    String? query,
    Set<UnrouterResolutionState>? resolutions,
    Set<HistoryAction>? actions,
    bool includeErrorsOnly = false,
  }) {
    final timeline = _filterTimelineEntries(
      _source.stateTimeline,
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

  /// Returns filtered raw machine timeline entries.
  List<Map<String, Object?>> debugMachineTimeline({
    int? tail,
    String? query,
    Set<UnrouterMachineSource>? sources,
    Set<UnrouterMachineEvent>? events,
    Set<UnrouterMachineEventGroup>? eventGroups,
    Set<UnrouterMachineTypedPayloadKind>? payloadKinds,
  }) {
    final filtered = _filterMachineTimelineEntries(
      _source.machineTimeline,
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

  /// Returns filtered typed machine timeline entries.
  List<Map<String, Object?>> debugTypedMachineTimeline({
    int? tail,
    String? query,
    Set<UnrouterMachineSource>? sources,
    Set<UnrouterMachineEvent>? events,
    Set<UnrouterMachineEventGroup>? eventGroups,
    Set<UnrouterMachineTypedPayloadKind>? payloadKinds,
  }) {
    final filtered = _filterMachineTimelineEntries(
      _source.machineTimeline,
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

  /// Returns filtered redirect diagnostics entries.
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

  /// Returns a combined debug report for route state, redirects, and machine.
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
        _source.stateTimeline,
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
        _source.machineTimeline,
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
      ..._serializeSnapshot(_source.state),
      'machineState': _source.machineState.toJson(),
      'timelineLength': _source.stateTimeline.length,
      'timelineTail': timeline.map(_serializeTimelineEntry).toList(),
      'redirectTrailLength': redirectDiagnostics.length,
      'redirectTrailTail': redirectTrail
          .map(_serializeRedirectDiagnostics)
          .toList(),
      'machineTimelineLength': _source.machineTimeline.length,
      'machineTimelineTail': machineTimeline
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }

  /// Exports [debugReport] as JSON string.
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
