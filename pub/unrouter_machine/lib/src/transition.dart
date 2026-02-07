/// Generic machine transition entry.
final class MachineTransitionEntry<S, E, P extends Object?> {
  const MachineTransitionEntry({
    required this.sequence,
    required this.recordedAt,
    required this.event,
    required this.from,
    required this.to,
    required this.payload,
  });

  final int sequence;
  final DateTime recordedAt;
  final E event;
  final S from;
  final S to;
  final P payload;
}

/// Bounded transition timeline store.
final class MachineTransitionStore<S, E, P extends Object?> {
  MachineTransitionStore({
    required this.limit,
    DateTime Function()? clock,
  }) : assert(limit > 0, 'Machine transition limit must be greater than zero.'),
       _clock = clock ?? DateTime.now;

  final int limit;
  final DateTime Function() _clock;

  final List<MachineTransitionEntry<S, E, P>> _entries =
      <MachineTransitionEntry<S, E, P>>[];
  int _sequence = 0;

  List<MachineTransitionEntry<S, E, P>> get entries {
    return List<MachineTransitionEntry<S, E, P>>.unmodifiable(_entries);
  }

  int get nextSequence => _sequence;

  void append({
    required E event,
    required S from,
    required S to,
    required P payload,
  }) {
    _entries.add(
      MachineTransitionEntry<S, E, P>(
        sequence: _sequence++,
        recordedAt: _clock(),
        event: event,
        from: from,
        to: to,
        payload: payload,
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
