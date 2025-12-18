import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '_internal.dart';
import 'history.dart';

class MemoryHistory extends History {
  MemoryHistory({
    List<Location> initialEntries = const [Location(key: DefaultKey())],
    int? initialIndex,
  }) {
    final [defaults, ...rest] = initialEntries;
    entries = [
      switch (defaults) {
        Location(key: const DefaultKey()) => defaults,
        _ => Location(
          key: const DefaultKey(),
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
  void Function(HistoryEvent event)? listener;

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
          key: UniqueKey(),
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
      key: UniqueKey(),
    );
  }

  @override
  void go(int delta) {
    action = .pop;
    index = clampIndex(index + delta);
    if (listener != null) {
      listener!.call(
        HistoryEvent(action: action, location: location, delta: delta),
      );
    }
  }

  @override
  void Function() listen(void Function(HistoryEvent event) listener) {
    this.listener = listener;
    return () => this.listener = null;
  }

  @override
  void dispose() {
    entries.clear();
    listener = null;
  }
}

extension on MemoryHistory {
  int clampIndex(int value) => math.min(math.max(value, 0), entries.length - 1);
}

extension on Path {
  Uri toUri() => Uri(path: pathname, query: search, fragment: hash);
}
