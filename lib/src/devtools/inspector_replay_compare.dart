import 'inspector_replay_store.dart';

/// Replay diff strategy.
enum UnrouterInspectorReplayCompareMode { sequence, path }

/// Replay diff entry type.
enum UnrouterInspectorReplayDiffType {
  unchanged,
  changed,
  missingBaseline,
  missingCurrent,
}

/// One replay diff row comparing baseline and current sessions.
class UnrouterInspectorReplayDiffEntry {
  const UnrouterInspectorReplayDiffEntry({
    required this.mode,
    required this.key,
    required this.type,
    required this.baselineEntry,
    required this.currentEntry,
    required this.reasonChanged,
    required this.pathChanged,
    required this.uriChanged,
  });

  final UnrouterInspectorReplayCompareMode mode;
  final String key;
  final UnrouterInspectorReplayDiffType type;
  final UnrouterInspectorReplayEntry? baselineEntry;
  final UnrouterInspectorReplayEntry? currentEntry;
  final bool reasonChanged;
  final bool pathChanged;
  final bool uriChanged;

  /// Whether this row represents a difference.
  bool get isChanged => type != UnrouterInspectorReplayDiffType.unchanged;

  int? get baselineSequence => baselineEntry?.sequence;

  int? get currentSequence => currentEntry?.sequence;

  String? get baselinePath => _entryPath(baselineEntry);

  String? get currentPath => _entryPath(currentEntry);

  String? get baselineUri => _entryUri(baselineEntry);

  String? get currentUri => _entryUri(currentEntry);

  String? get baselineReason => baselineEntry?.emission.reason.name;

  String? get currentReason => currentEntry?.emission.reason.name;

  /// Serializes diff entry to JSON-like map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'mode': mode.name,
      'key': key,
      'type': type.name,
      'reasonChanged': reasonChanged,
      'pathChanged': pathChanged,
      'uriChanged': uriChanged,
      'baselineSequence': baselineSequence,
      'currentSequence': currentSequence,
      'baselinePath': baselinePath,
      'currentPath': currentPath,
      'baselineUri': baselineUri,
      'currentUri': currentUri,
      'baselineReason': baselineReason,
      'currentReason': currentReason,
    };
  }
}

/// Aggregated replay session diff result.
class UnrouterInspectorReplaySessionDiff {
  const UnrouterInspectorReplaySessionDiff({
    required this.mode,
    required this.entries,
    required this.comparedCount,
    required this.changedCount,
    required this.missingBaselineCount,
    required this.missingCurrentCount,
  });

  final UnrouterInspectorReplayCompareMode mode;
  final List<UnrouterInspectorReplayDiffEntry> entries;
  final int comparedCount;
  final int changedCount;
  final int missingBaselineCount;
  final int missingCurrentCount;

  /// Whether any differences were detected.
  bool get hasDifferences =>
      changedCount > 0 || missingBaselineCount > 0 || missingCurrentCount > 0;

  /// Returns only changed or missing rows.
  List<UnrouterInspectorReplayDiffEntry> get changedEntries {
    return entries.where((entry) => entry.isChanged).toList(growable: false);
  }

  /// Serializes session diff to JSON-like map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'mode': mode.name,
      'comparedCount': comparedCount,
      'changedCount': changedCount,
      'missingBaselineCount': missingBaselineCount,
      'missingCurrentCount': missingCurrentCount,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }
}

/// Utility for comparing replay sessions.
class UnrouterInspectorReplayComparator {
  const UnrouterInspectorReplayComparator._();

  /// Compares baseline/current replay entries with selected [mode].
  static UnrouterInspectorReplaySessionDiff compare({
    required Iterable<UnrouterInspectorReplayEntry> baseline,
    required Iterable<UnrouterInspectorReplayEntry> current,
    UnrouterInspectorReplayCompareMode mode =
        UnrouterInspectorReplayCompareMode.sequence,
    bool includeUnchanged = false,
    int? tail,
  }) {
    if (tail != null && tail <= 0) {
      throw ArgumentError.value(
        tail,
        'tail',
        'Unrouter inspector replay compare tail must be greater than zero.',
      );
    }

    final baselineEntries = _normalizeTail(baseline.toList(), tail);
    final currentEntries = _normalizeTail(current.toList(), tail);
    final entries = mode == UnrouterInspectorReplayCompareMode.sequence
        ? _compareBySequence(
            baselineEntries,
            currentEntries,
            includeUnchanged: includeUnchanged,
          )
        : _compareByPath(
            baselineEntries,
            currentEntries,
            includeUnchanged: includeUnchanged,
          );

    final changedCount = entries
        .where((entry) => entry.type == UnrouterInspectorReplayDiffType.changed)
        .length;
    final missingBaselineCount = entries
        .where(
          (entry) =>
              entry.type == UnrouterInspectorReplayDiffType.missingBaseline,
        )
        .length;
    final missingCurrentCount = entries
        .where(
          (entry) =>
              entry.type == UnrouterInspectorReplayDiffType.missingCurrent,
        )
        .length;

    return UnrouterInspectorReplaySessionDiff(
      mode: mode,
      entries: List<UnrouterInspectorReplayDiffEntry>.unmodifiable(entries),
      comparedCount: entries.length,
      changedCount: changedCount,
      missingBaselineCount: missingBaselineCount,
      missingCurrentCount: missingCurrentCount,
    );
  }

  static List<UnrouterInspectorReplayEntry> _normalizeTail(
    List<UnrouterInspectorReplayEntry> entries,
    int? tail,
  ) {
    if (tail == null || entries.length <= tail) {
      return entries;
    }
    return entries.sublist(entries.length - tail);
  }

  static List<UnrouterInspectorReplayDiffEntry> _compareBySequence(
    List<UnrouterInspectorReplayEntry> baseline,
    List<UnrouterInspectorReplayEntry> current, {
    required bool includeUnchanged,
  }) {
    final baselineBySequence = <int, UnrouterInspectorReplayEntry>{};
    final currentBySequence = <int, UnrouterInspectorReplayEntry>{};
    for (final entry in baseline) {
      baselineBySequence[entry.sequence] = entry;
    }
    for (final entry in current) {
      currentBySequence[entry.sequence] = entry;
    }

    final allSequences = <int>{
      ...baselineBySequence.keys,
      ...currentBySequence.keys,
    }.toList()..sort();

    final diffs = <UnrouterInspectorReplayDiffEntry>[];
    for (final sequence in allSequences) {
      final baselineEntry = baselineBySequence[sequence];
      final currentEntry = currentBySequence[sequence];
      final diff = _createDiff(
        mode: UnrouterInspectorReplayCompareMode.sequence,
        key: '$sequence',
        baselineEntry: baselineEntry,
        currentEntry: currentEntry,
      );
      if (!includeUnchanged && !diff.isChanged) {
        continue;
      }
      diffs.add(diff);
    }
    return diffs;
  }

  static List<UnrouterInspectorReplayDiffEntry> _compareByPath(
    List<UnrouterInspectorReplayEntry> baseline,
    List<UnrouterInspectorReplayEntry> current, {
    required bool includeUnchanged,
  }) {
    final baselineByPath = _indexByPath(baseline);
    final currentByPath = _indexByPath(current);
    final allPaths = <String>{
      ...baselineByPath.keys,
      ...currentByPath.keys,
    }.toList()..sort();

    final diffs = <UnrouterInspectorReplayDiffEntry>[];
    for (final path in allPaths) {
      final baselineEntry = baselineByPath[path];
      final currentEntry = currentByPath[path];
      final diff = _createDiff(
        mode: UnrouterInspectorReplayCompareMode.path,
        key: path,
        baselineEntry: baselineEntry,
        currentEntry: currentEntry,
      );
      if (!includeUnchanged && !diff.isChanged) {
        continue;
      }
      diffs.add(diff);
    }
    return diffs;
  }

  static Map<String, UnrouterInspectorReplayEntry> _indexByPath(
    List<UnrouterInspectorReplayEntry> entries,
  ) {
    final map = <String, UnrouterInspectorReplayEntry>{};
    for (final entry in entries) {
      map[_entryPath(entry) ?? '-'] = entry;
    }
    return map;
  }

  static UnrouterInspectorReplayDiffEntry _createDiff({
    required UnrouterInspectorReplayCompareMode mode,
    required String key,
    required UnrouterInspectorReplayEntry? baselineEntry,
    required UnrouterInspectorReplayEntry? currentEntry,
  }) {
    final type = _resolveType(baselineEntry, currentEntry);
    final reasonChanged =
        baselineEntry?.emission.reason != currentEntry?.emission.reason;
    final pathChanged = _entryPath(baselineEntry) != _entryPath(currentEntry);
    final uriChanged = _entryUri(baselineEntry) != _entryUri(currentEntry);

    return UnrouterInspectorReplayDiffEntry(
      mode: mode,
      key: key,
      type: type,
      baselineEntry: baselineEntry,
      currentEntry: currentEntry,
      reasonChanged: reasonChanged,
      pathChanged: pathChanged,
      uriChanged: uriChanged,
    );
  }

  static UnrouterInspectorReplayDiffType _resolveType(
    UnrouterInspectorReplayEntry? baselineEntry,
    UnrouterInspectorReplayEntry? currentEntry,
  ) {
    if (baselineEntry == null && currentEntry != null) {
      return UnrouterInspectorReplayDiffType.missingBaseline;
    }
    if (baselineEntry != null && currentEntry == null) {
      return UnrouterInspectorReplayDiffType.missingCurrent;
    }
    if (baselineEntry == null && currentEntry == null) {
      return UnrouterInspectorReplayDiffType.unchanged;
    }

    final sameReason =
        baselineEntry!.emission.reason == currentEntry!.emission.reason;
    final samePath = _entryPath(baselineEntry) == _entryPath(currentEntry);
    final sameUri = _entryUri(baselineEntry) == _entryUri(currentEntry);
    if (sameReason && samePath && sameUri) {
      return UnrouterInspectorReplayDiffType.unchanged;
    }
    return UnrouterInspectorReplayDiffType.changed;
  }
}

/// Convenience compare helpers on replay store.
extension UnrouterInspectorReplayStoreCompareExtension
    on UnrouterInspectorReplayStore {
  /// Compares this store with [baseline].
  UnrouterInspectorReplaySessionDiff compareWith(
    UnrouterInspectorReplayStore baseline, {
    UnrouterInspectorReplayCompareMode mode =
        UnrouterInspectorReplayCompareMode.sequence,
    bool includeUnchanged = false,
    int? tail,
  }) {
    return UnrouterInspectorReplayComparator.compare(
      baseline: baseline.value.entries,
      current: value.entries,
      mode: mode,
      includeUnchanged: includeUnchanged,
      tail: tail,
    );
  }
}

String? _entryPath(UnrouterInspectorReplayEntry? entry) {
  final report = entry?.emission.report;
  if (report == null) {
    return null;
  }
  final value = report['routePath'] ?? report['uri'];
  return value?.toString();
}

String? _entryUri(UnrouterInspectorReplayEntry? entry) {
  final report = entry?.emission.report;
  if (report == null) {
    return null;
  }
  return report['uri']?.toString();
}
