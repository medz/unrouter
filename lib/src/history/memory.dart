import 'dart:math' as math;

import '_utils.dart';
import 'history.dart';

class MemoryHistory extends History {
  MemoryHistory({
    List<Location> initialEntries = const [Location(identifier: 'default')],
    int? initialIndex,
  }) {
    final [defaults, ...rest] = initialEntries;
    entries = [
      switch (defaults) {
        Location(identifier: 'default') => defaults,
        _ => Location(
          identifier: 'default',
          pathname: defaults.pathname,
          search: defaults.search,
          hash: defaults.hash,
          state: defaults.state,
        ),
      },
      ...rest,
    ];
    index = clampIndex(initialIndex ?? entries.length - 1);
  }

  late final List<Location> entries;
  late int index;

  final listeners = <void Function(HistoryEvent event)>[];

  @override
  HistoryAction action = .pop;

  @override
  Location get location => entries.elementAt(index);

  @override
  String createHref(Path to) => to.toUri().toString();

  @override
  void push(Path to, [Object? state]) {
    action = .push;
    index += 1;
    entries
      ..length = index
      ..add(
        Location(
          pathname: to.pathname,
          search: to.search,
          hash: to.hash,
          state: state,
          identifier: generateIdentifier(),
        ),
      );
  }

  @override
  void replace(Path to, [Object? state]) {
    action = .replace;
    entries[index] = Location(
      pathname: to.pathname,
      search: to.search,
      hash: to.hash,
      state: state,
      identifier: generateIdentifier(),
    );
  }

  @override
  void go(int delta) {
    action = .pop;
    index = clampIndex(index + delta);
    final event = HistoryEvent(
      action: action,
      location: location,
      delta: delta,
    );
    for (final e in listeners) {
      e(event);
    }
  }

  @override
  void Function() listen(void Function(HistoryEvent event) listener) {
    listeners.add(listener);
    return () {
      listeners.removeWhere((e) => e == listener);
    };
  }

  @override
  void dispose() {
    entries.clear();
    listeners.clear();
  }
}

extension on MemoryHistory {
  int clampIndex(int value) => math.min(math.max(value, 0), entries.length - 1);
}

extension on Path {
  Uri toUri() => Uri(
        path: pathname,
        query: search.isEmpty ? null : search,
        fragment: hash.isEmpty ? null : hash,
      );
}
