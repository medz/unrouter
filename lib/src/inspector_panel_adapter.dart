import 'dart:async';

import 'package:flutter/foundation.dart';

import 'inspector_bridge.dart';
import 'route_data.dart';

class UnrouterInspectorPanelAdapterConfig {
  const UnrouterInspectorPanelAdapterConfig({
    this.maxEntries = 200,
    this.autoSelectLatest = true,
  }) : assert(
         maxEntries > 0,
         'Unrouter inspector panel maxEntries must be greater than zero.',
       );

  final int maxEntries;
  final bool autoSelectLatest;
}

class UnrouterInspectorPanelEntry {
  const UnrouterInspectorPanelEntry({
    required this.sequence,
    required this.emission,
  });

  final int sequence;
  final UnrouterInspectorEmission emission;

  UnrouterInspectorEmissionReason get reason => emission.reason;

  DateTime get recordedAt => emission.recordedAt;

  Map<String, Object?> get report => emission.report;

  String? get routePath => report['routePath'] as String?;

  String? get uri => report['uri']?.toString();

  String? get resolution => report['resolution'] as String?;

  Map<String, Object?> toJson() {
    return <String, Object?>{'sequence': sequence, ...emission.toJson()};
  }
}

class UnrouterInspectorPanelState {
  const UnrouterInspectorPanelState({
    required this.entries,
    required this.selectedSequence,
    required this.emittedCount,
    required this.droppedCount,
    required this.maxEntries,
    required this.reasonCounts,
  });

  factory UnrouterInspectorPanelState.initial({required int maxEntries}) {
    return UnrouterInspectorPanelState(
      entries: const <UnrouterInspectorPanelEntry>[],
      selectedSequence: null,
      emittedCount: 0,
      droppedCount: 0,
      maxEntries: maxEntries,
      reasonCounts: const <UnrouterInspectorEmissionReason, int>{},
    );
  }

  static const Object _unset = Object();

  final List<UnrouterInspectorPanelEntry> entries;
  final int? selectedSequence;
  final int emittedCount;
  final int droppedCount;
  final int maxEntries;
  final Map<UnrouterInspectorEmissionReason, int> reasonCounts;

  bool get isEmpty => entries.isEmpty;

  bool get isNotEmpty => entries.isNotEmpty;

  UnrouterInspectorPanelEntry? get latestEntry {
    if (entries.isEmpty) {
      return null;
    }
    return entries.last;
  }

  UnrouterInspectorPanelEntry? get selectedEntry {
    final selected = selectedSequence;
    if (selected == null) {
      return null;
    }
    for (final entry in entries) {
      if (entry.sequence == selected) {
        return entry;
      }
    }
    return null;
  }

  UnrouterInspectorPanelState copyWith({
    List<UnrouterInspectorPanelEntry>? entries,
    Object? selectedSequence = _unset,
    int? emittedCount,
    int? droppedCount,
    int? maxEntries,
    Map<UnrouterInspectorEmissionReason, int>? reasonCounts,
  }) {
    return UnrouterInspectorPanelState(
      entries: entries ?? this.entries,
      selectedSequence: selectedSequence == _unset
          ? this.selectedSequence
          : selectedSequence as int?,
      emittedCount: emittedCount ?? this.emittedCount,
      droppedCount: droppedCount ?? this.droppedCount,
      maxEntries: maxEntries ?? this.maxEntries,
      reasonCounts: reasonCounts ?? this.reasonCounts,
    );
  }
}

class UnrouterInspectorPanelAdapter
    implements ValueListenable<UnrouterInspectorPanelState> {
  UnrouterInspectorPanelAdapter({
    required Stream<UnrouterInspectorEmission> stream,
    this.config = const UnrouterInspectorPanelAdapterConfig(),
  }) : _state = ValueNotifier<UnrouterInspectorPanelState>(
         UnrouterInspectorPanelState.initial(maxEntries: config.maxEntries),
       ) {
    _subscription = stream.listen(_onEmission);
  }

  final UnrouterInspectorPanelAdapterConfig config;
  final ValueNotifier<UnrouterInspectorPanelState> _state;
  StreamSubscription<UnrouterInspectorEmission>? _subscription;
  bool _isDisposed = false;

  static UnrouterInspectorPanelAdapter fromBridge<R extends RouteData>({
    required UnrouterInspectorBridge<R> bridge,
    UnrouterInspectorPanelAdapterConfig config =
        const UnrouterInspectorPanelAdapterConfig(),
  }) {
    return UnrouterInspectorPanelAdapter(stream: bridge.stream, config: config);
  }

  ValueListenable<UnrouterInspectorPanelState> get listenable => this;

  @override
  UnrouterInspectorPanelState get value => _state.value;

  @override
  void addListener(VoidCallback listener) {
    _state.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _state.removeListener(listener);
  }

  bool select(int sequence) {
    if (_isDisposed) {
      return false;
    }
    if (!_containsSequence(value.entries, sequence)) {
      return false;
    }
    return _setSelectedSequence(sequence);
  }

  bool selectLatest() {
    if (_isDisposed || value.entries.isEmpty) {
      return false;
    }
    return _setSelectedSequence(value.entries.last.sequence);
  }

  bool selectPrevious() {
    if (_isDisposed) {
      return false;
    }
    final entries = value.entries;
    if (entries.isEmpty) {
      return false;
    }
    final selected = value.selectedSequence;
    if (selected == null) {
      return _setSelectedSequence(entries.last.sequence);
    }
    final index = _indexOfSequence(entries, selected);
    if (index <= 0) {
      return false;
    }
    return _setSelectedSequence(entries[index - 1].sequence);
  }

  bool selectNext() {
    if (_isDisposed) {
      return false;
    }
    final entries = value.entries;
    if (entries.isEmpty) {
      return false;
    }
    final selected = value.selectedSequence;
    if (selected == null) {
      return _setSelectedSequence(entries.first.sequence);
    }
    final index = _indexOfSequence(entries, selected);
    if (index < 0 || index >= entries.length - 1) {
      return false;
    }
    return _setSelectedSequence(entries[index + 1].sequence);
  }

  void clear({bool resetCounters = false}) {
    if (_isDisposed) {
      return;
    }
    final current = value;
    _state.value = UnrouterInspectorPanelState(
      entries: const <UnrouterInspectorPanelEntry>[],
      selectedSequence: null,
      emittedCount: resetCounters ? 0 : current.emittedCount,
      droppedCount: resetCounters ? 0 : current.droppedCount,
      maxEntries: current.maxEntries,
      reasonCounts: const <UnrouterInspectorEmissionReason, int>{},
    );
  }

  void _onEmission(UnrouterInspectorEmission emission) {
    if (_isDisposed) {
      return;
    }
    final current = value;
    final sequence = current.emittedCount + 1;
    final nextEntries = List<UnrouterInspectorPanelEntry>.from(
      current.entries,
    )..add(UnrouterInspectorPanelEntry(sequence: sequence, emission: emission));
    var droppedCount = current.droppedCount;
    if (nextEntries.length > config.maxEntries) {
      final removeCount = nextEntries.length - config.maxEntries;
      nextEntries.removeRange(0, removeCount);
      droppedCount += removeCount;
    }

    var selectedSequence = current.selectedSequence;
    if (config.autoSelectLatest || selectedSequence == null) {
      selectedSequence = sequence;
    } else if (!_containsSequence(nextEntries, selectedSequence)) {
      selectedSequence = nextEntries.isEmpty
          ? null
          : nextEntries.first.sequence;
    }

    _state.value = UnrouterInspectorPanelState(
      entries: List<UnrouterInspectorPanelEntry>.unmodifiable(nextEntries),
      selectedSequence: selectedSequence,
      emittedCount: sequence,
      droppedCount: droppedCount,
      maxEntries: config.maxEntries,
      reasonCounts: Map<UnrouterInspectorEmissionReason, int>.unmodifiable(
        _countReasons(nextEntries),
      ),
    );
  }

  bool _setSelectedSequence(int? sequence) {
    final current = value;
    if (current.selectedSequence == sequence) {
      return false;
    }
    _state.value = current.copyWith(selectedSequence: sequence);
    return true;
  }

  Map<UnrouterInspectorEmissionReason, int> _countReasons(
    List<UnrouterInspectorPanelEntry> entries,
  ) {
    final counts = <UnrouterInspectorEmissionReason, int>{};
    for (final entry in entries) {
      counts.update(entry.reason, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  bool _containsSequence(List<UnrouterInspectorPanelEntry> entries, int value) {
    return _indexOfSequence(entries, value) >= 0;
  }

  int _indexOfSequence(List<UnrouterInspectorPanelEntry> entries, int value) {
    for (var index = 0; index < entries.length; index++) {
      if (entries[index].sequence == value) {
        return index;
      }
    }
    return -1;
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _state.dispose();
  }
}
