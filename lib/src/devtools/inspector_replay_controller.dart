import 'dart:async';

import 'package:flutter/foundation.dart';

import 'inspector_replay_store.dart';

/// Replay speed presets used by [UnrouterInspectorReplayController].
enum UnrouterInspectorReplaySpeedPreset {
  x025(0.25),
  x05(0.5),
  x1(1),
  x2(2),
  x4(4);

  const UnrouterInspectorReplaySpeedPreset(this.multiplier);

  final double multiplier;

  String get label {
    switch (this) {
      case UnrouterInspectorReplaySpeedPreset.x025:
        return '0.25x';
      case UnrouterInspectorReplaySpeedPreset.x05:
        return '0.5x';
      case UnrouterInspectorReplaySpeedPreset.x1:
        return '1x';
      case UnrouterInspectorReplaySpeedPreset.x2:
        return '2x';
      case UnrouterInspectorReplaySpeedPreset.x4:
        return '4x';
    }
  }
}

/// Current replay lifecycle phase.
enum UnrouterInspectorReplayPhase { idle, playing, paused }

/// Bookmark on replay sequence timeline.
class UnrouterInspectorReplayBookmark {
  const UnrouterInspectorReplayBookmark({
    required this.id,
    required this.sequence,
    required this.label,
    required this.group,
    required this.createdAt,
  });

  final String id;
  final int sequence;
  final String label;
  final String group;
  final DateTime createdAt;
}

/// Configuration for [UnrouterInspectorReplayController].
class UnrouterInspectorReplayControllerConfig {
  const UnrouterInspectorReplayControllerConfig({
    this.step = const Duration(milliseconds: 120),
    this.useRecordedIntervals = false,
    this.initialSpeed = UnrouterInspectorReplaySpeedPreset.x1,
  });

  final Duration step;
  final bool useRecordedIntervals;
  final UnrouterInspectorReplaySpeedPreset initialSpeed;
}

/// Immutable controller state for replay operations.
class UnrouterInspectorReplayControllerState {
  const UnrouterInspectorReplayControllerState({
    required this.phase,
    required this.speed,
    required this.step,
    required this.useRecordedIntervals,
    required this.cursorSequence,
    required this.rangeStart,
    required this.rangeEnd,
    required this.replayedCount,
    required this.bookmarks,
  });

  factory UnrouterInspectorReplayControllerState.initial({
    required UnrouterInspectorReplayControllerConfig config,
  }) {
    return UnrouterInspectorReplayControllerState(
      phase: UnrouterInspectorReplayPhase.idle,
      speed: config.initialSpeed,
      step: config.step,
      useRecordedIntervals: config.useRecordedIntervals,
      cursorSequence: null,
      rangeStart: null,
      rangeEnd: null,
      replayedCount: 0,
      bookmarks: const <UnrouterInspectorReplayBookmark>[],
    );
  }

  static const Object _unset = Object();

  final UnrouterInspectorReplayPhase phase;
  final UnrouterInspectorReplaySpeedPreset speed;
  final Duration step;
  final bool useRecordedIntervals;
  final int? cursorSequence;
  final int? rangeStart;
  final int? rangeEnd;
  final int replayedCount;
  final List<UnrouterInspectorReplayBookmark> bookmarks;

  /// Bookmarks grouped by bookmark group.
  Map<String, List<UnrouterInspectorReplayBookmark>> get bookmarksByGroup {
    final map = <String, List<UnrouterInspectorReplayBookmark>>{};
    for (final bookmark in bookmarks) {
      final key = bookmark.group.trim().isEmpty ? 'default' : bookmark.group;
      map
          .putIfAbsent(key, () => <UnrouterInspectorReplayBookmark>[])
          .add(bookmark);
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Map<String, List<UnrouterInspectorReplayBookmark>>.unmodifiable(
      <String, List<UnrouterInspectorReplayBookmark>>{
        for (final entry in sorted)
          entry.key: List<UnrouterInspectorReplayBookmark>.unmodifiable(
            entry.value,
          ),
      },
    );
  }

  /// Whether controller is idle.
  bool get isIdle => phase == UnrouterInspectorReplayPhase.idle;

  /// Whether replay is currently running.
  bool get isPlaying => phase == UnrouterInspectorReplayPhase.playing;

  /// Whether replay is currently paused.
  bool get isPaused => phase == UnrouterInspectorReplayPhase.paused;

  /// Returns a new state with selected fields replaced.
  UnrouterInspectorReplayControllerState copyWith({
    UnrouterInspectorReplayPhase? phase,
    UnrouterInspectorReplaySpeedPreset? speed,
    Duration? step,
    bool? useRecordedIntervals,
    Object? cursorSequence = _unset,
    Object? rangeStart = _unset,
    Object? rangeEnd = _unset,
    int? replayedCount,
    List<UnrouterInspectorReplayBookmark>? bookmarks,
  }) {
    return UnrouterInspectorReplayControllerState(
      phase: phase ?? this.phase,
      speed: speed ?? this.speed,
      step: step ?? this.step,
      useRecordedIntervals: useRecordedIntervals ?? this.useRecordedIntervals,
      cursorSequence: cursorSequence == _unset
          ? this.cursorSequence
          : cursorSequence as int?,
      rangeStart: rangeStart == _unset ? this.rangeStart : rangeStart as int?,
      rangeEnd: rangeEnd == _unset ? this.rangeEnd : rangeEnd as int?,
      replayedCount: replayedCount ?? this.replayedCount,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}

/// Playback controller for [UnrouterInspectorReplayStore].
class UnrouterInspectorReplayController
    implements ValueListenable<UnrouterInspectorReplayControllerState> {
  UnrouterInspectorReplayController({
    required this.store,
    this.config = const UnrouterInspectorReplayControllerConfig(),
  }) : _state = ValueNotifier<UnrouterInspectorReplayControllerState>(
         UnrouterInspectorReplayControllerState.initial(config: config),
       ) {
    if (config.step.isNegative) {
      throw ArgumentError.value(
        config.step,
        'config.step',
        'Unrouter inspector replay controller step must not be negative.',
      );
    }
    store.addListener(_onStoreChanged);
  }

  final UnrouterInspectorReplayStore store;
  final UnrouterInspectorReplayControllerConfig config;
  final ValueNotifier<UnrouterInspectorReplayControllerState> _state;

  int _playToken = 0;
  int _bookmarkId = 0;
  Completer<void>? _pauseCompleter;
  bool _isDisposed = false;

  /// Listenable state view.
  ValueListenable<UnrouterInspectorReplayControllerState> get listenable =>
      this;

  @override
  UnrouterInspectorReplayControllerState get value => _state.value;

  @override
  void addListener(VoidCallback listener) {
    _state.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _state.removeListener(listener);
  }

  /// Sets replay range boundaries.
  void setRange({int? fromSequence, int? toSequence}) {
    if (_isDisposed) {
      return;
    }
    if (fromSequence != null &&
        toSequence != null &&
        fromSequence > toSequence) {
      throw ArgumentError.value(
        fromSequence,
        'fromSequence',
        'fromSequence must be less than or equal to toSequence.',
      );
    }
    _state.value = value.copyWith(
      rangeStart: fromSequence,
      rangeEnd: toSequence,
      replayedCount: 0,
    );
    _normalizeCursorToEntries(store.value.entries);
  }

  /// Clears replay range boundaries.
  void clearRange() {
    if (_isDisposed) {
      return;
    }
    _state.value = value.copyWith(
      rangeStart: null,
      rangeEnd: null,
      replayedCount: 0,
    );
    _normalizeCursorToEntries(store.value.entries);
  }

  /// Moves replay cursor to [sequence].
  bool scrubTo(int sequence, {bool selectNearest = true}) {
    if (_isDisposed) {
      return false;
    }
    final entries = _entriesInRange(store.value.entries);
    if (entries.isEmpty) {
      return false;
    }

    final exact = _indexOfSequence(entries, sequence);
    if (exact >= 0) {
      _state.value = value.copyWith(cursorSequence: sequence);
      return true;
    }

    if (!selectNearest) {
      return false;
    }
    final nearest = _nearestSequence(entries, sequence);
    if (nearest == null) {
      return false;
    }
    _state.value = value.copyWith(cursorSequence: nearest);
    return true;
  }

  /// Sets replay speed preset.
  void setSpeedPreset(UnrouterInspectorReplaySpeedPreset preset) {
    if (_isDisposed) {
      return;
    }
    _state.value = value.copyWith(speed: preset);
  }

  /// Cycles replay speed preset and returns the new value.
  UnrouterInspectorReplaySpeedPreset cycleSpeedPreset() {
    if (_isDisposed) {
      return value.speed;
    }
    final values = UnrouterInspectorReplaySpeedPreset.values;
    final index = values.indexOf(value.speed);
    final next = values[(index + 1) % values.length];
    setSpeedPreset(next);
    return next;
  }

  /// Adds a replay bookmark.
  UnrouterInspectorReplayBookmark addBookmark({
    int? sequence,
    String? label,
    String group = 'default',
  }) {
    if (_isDisposed) {
      throw StateError('Unrouter inspector replay controller is disposed.');
    }
    final targetSequence =
        sequence ?? value.cursorSequence ?? _latestSequence();
    if (targetSequence == null) {
      throw StateError(
        'Unrouter inspector replay bookmark requires at least one entry.',
      );
    }
    final bookmark = UnrouterInspectorReplayBookmark(
      id: 'bookmark-${++_bookmarkId}',
      sequence: targetSequence,
      label: label ?? 'bookmark-$targetSequence',
      group: group.trim().isEmpty ? 'default' : group.trim(),
      createdAt: DateTime.now(),
    );
    final next = List<UnrouterInspectorReplayBookmark>.from(value.bookmarks)
      ..add(bookmark);
    _state.value = value.copyWith(
      bookmarks: List<UnrouterInspectorReplayBookmark>.unmodifiable(next),
    );
    return bookmark;
  }

  /// Removes bookmark by id.
  bool removeBookmark(String id) {
    if (_isDisposed) {
      return false;
    }
    final next = List<UnrouterInspectorReplayBookmark>.from(value.bookmarks);
    final before = next.length;
    next.removeWhere((bookmark) => bookmark.id == id);
    final removed = next.length != before;
    if (!removed) {
      return false;
    }
    _state.value = value.copyWith(
      bookmarks: List<UnrouterInspectorReplayBookmark>.unmodifiable(next),
    );
    return true;
  }

  /// Clears all bookmarks.
  void clearBookmarks() {
    if (_isDisposed || value.bookmarks.isEmpty) {
      return;
    }
    _state.value = value.copyWith(
      bookmarks: const <UnrouterInspectorReplayBookmark>[],
    );
  }

  /// Jumps cursor to bookmark by id.
  bool jumpToBookmark(String id) {
    if (_isDisposed) {
      return false;
    }
    for (final bookmark in value.bookmarks) {
      if (bookmark.id == id) {
        return scrubTo(bookmark.sequence);
      }
    }
    return false;
  }

  /// Starts replay and returns replayed entry count.
  Future<int> play({
    bool restart = false,
    ValueChanged<UnrouterInspectorReplayEntry>? onStep,
  }) async {
    if (_isDisposed) {
      return 0;
    }
    if (value.isPaused) {
      resume();
      return 0;
    }
    if (value.isPlaying) {
      return 0;
    }

    final entries = _entriesInRange(store.value.entries);
    if (entries.isEmpty) {
      _state.value = value.copyWith(
        phase: UnrouterInspectorReplayPhase.idle,
        replayedCount: 0,
      );
      return 0;
    }

    final startIndex = _resolveStartIndex(entries, restart: restart);
    if (startIndex < 0 || startIndex >= entries.length) {
      _state.value = value.copyWith(
        phase: UnrouterInspectorReplayPhase.idle,
        replayedCount: 0,
      );
      return 0;
    }

    final token = ++_playToken;
    _state.value = value.copyWith(
      phase: UnrouterInspectorReplayPhase.playing,
      replayedCount: 0,
      cursorSequence: entries[startIndex].sequence,
    );

    var delivered = 0;
    for (var index = startIndex; index < entries.length; index++) {
      if (_isDisposed || token != _playToken) {
        break;
      }

      await _awaitWhilePaused(token);
      if (_isDisposed || token != _playToken) {
        break;
      }

      final entry = entries[index];
      _state.value = value.copyWith(
        cursorSequence: entry.sequence,
        replayedCount: delivered + 1,
      );
      onStep?.call(entry);
      delivered += 1;

      if (index >= entries.length - 1) {
        continue;
      }
      final delay = _resolveDelay(
        previousRecordedAt: entry.emission.recordedAt,
        nextRecordedAt: entries[index + 1].emission.recordedAt,
      );
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }

    if (!_isDisposed && token == _playToken) {
      _state.value = value.copyWith(phase: UnrouterInspectorReplayPhase.idle);
    }
    return delivered;
  }

  /// Pauses replay.
  bool pause() {
    if (_isDisposed || !value.isPlaying) {
      return false;
    }
    _state.value = value.copyWith(phase: UnrouterInspectorReplayPhase.paused);
    _pauseCompleter ??= Completer<void>();
    return true;
  }

  /// Resumes replay if paused.
  bool resume() {
    if (_isDisposed || !value.isPaused) {
      return false;
    }
    _state.value = value.copyWith(phase: UnrouterInspectorReplayPhase.playing);
    final completer = _pauseCompleter;
    _pauseCompleter = null;
    completer?.complete();
    return true;
  }

  /// Stops replay and resets phase to idle.
  void stop() {
    if (_isDisposed) {
      return;
    }
    _playToken += 1;
    final completer = _pauseCompleter;
    _pauseCompleter = null;
    completer?.complete();
    if (!value.isIdle) {
      _state.value = value.copyWith(phase: UnrouterInspectorReplayPhase.idle);
    }
  }

  /// Disposes controller listeners.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    stop();
    store.removeListener(_onStoreChanged);
    _state.dispose();
  }

  void _onStoreChanged() {
    if (_isDisposed) {
      return;
    }
    _normalizeCursorToEntries(store.value.entries);
  }

  void _normalizeCursorToEntries(List<UnrouterInspectorReplayEntry> entries) {
    final inRange = _entriesInRange(entries);
    final cursor = value.cursorSequence;
    if (inRange.isEmpty) {
      if (cursor != null) {
        _state.value = value.copyWith(cursorSequence: null);
      }
      return;
    }
    if (cursor != null && _indexOfSequence(inRange, cursor) >= 0) {
      return;
    }
    _state.value = value.copyWith(cursorSequence: inRange.last.sequence);
  }

  List<UnrouterInspectorReplayEntry> _entriesInRange(
    List<UnrouterInspectorReplayEntry> entries,
  ) {
    final start = value.rangeStart;
    final end = value.rangeEnd;
    return entries
        .where((entry) {
          if (start != null && entry.sequence < start) {
            return false;
          }
          if (end != null && entry.sequence > end) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  int _resolveStartIndex(
    List<UnrouterInspectorReplayEntry> entries, {
    required bool restart,
  }) {
    if (entries.isEmpty) {
      return -1;
    }
    if (restart) {
      return 0;
    }
    final cursor = value.cursorSequence;
    if (cursor == null) {
      return 0;
    }
    final index = _indexOfSequence(entries, cursor);
    if (index < 0) {
      return 0;
    }
    return index;
  }

  int _indexOfSequence(
    List<UnrouterInspectorReplayEntry> entries,
    int sequence,
  ) {
    for (var index = 0; index < entries.length; index++) {
      if (entries[index].sequence == sequence) {
        return index;
      }
    }
    return -1;
  }

  int? _nearestSequence(
    List<UnrouterInspectorReplayEntry> entries,
    int target,
  ) {
    if (entries.isEmpty) {
      return null;
    }
    var nearest = entries.first.sequence;
    var nearestDistance = (nearest - target).abs();
    for (final entry in entries.skip(1)) {
      final distance = (entry.sequence - target).abs();
      if (distance < nearestDistance) {
        nearest = entry.sequence;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  int? _latestSequence() {
    final latest = store.value.latestEntry;
    if (latest == null) {
      return null;
    }
    return latest.sequence;
  }

  Duration _resolveDelay({
    required DateTime? previousRecordedAt,
    required DateTime nextRecordedAt,
  }) {
    Duration raw;
    if (value.useRecordedIntervals && previousRecordedAt != null) {
      raw = nextRecordedAt.difference(previousRecordedAt);
      if (raw.isNegative) {
        raw = Duration.zero;
      }
    } else {
      raw = value.step;
    }
    if (raw <= Duration.zero) {
      return Duration.zero;
    }
    final scaledMicroseconds = raw.inMicroseconds / value.speed.multiplier;
    return Duration(microseconds: scaledMicroseconds.round());
  }

  Future<void> _awaitWhilePaused(int token) async {
    while (!_isDisposed &&
        token == _playToken &&
        value.phase == UnrouterInspectorReplayPhase.paused) {
      _pauseCompleter ??= Completer<void>();
      await _pauseCompleter!.future;
    }
  }
}
