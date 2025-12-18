import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '_utils.dart';
import 'history.dart';

/// Internal entry for MemoryHistory that includes identifier
class _MemoryEntry {
  final RouteInformation info;
  final String identifier;

  const _MemoryEntry({required this.info, required this.identifier});
}

/// An in-memory [History] implementation.
///
/// This is the default history used by `Unrouter` on non-web platforms and is
/// convenient for tests.
///
/// Browser semantics:
/// - [push] and [replace] update [location] immediately and do **not** notify
///   listeners.
/// - [go] / [back] / [forward] notify listeners synchronously.
class MemoryHistory extends History {
  /// Creates a [MemoryHistory] with an optional initial stack.
  ///
  /// If [initialEntries] is omitted (or empty), the stack starts with a single
  /// entry at `/`.
  ///
  /// If provided, [initialIndex] is clamped to the valid range.
  MemoryHistory({
    List<RouteInformation>? initialEntries,
    int? initialIndex,
  }) {
    final entries = (initialEntries == null || initialEntries.isEmpty)
        ? [RouteInformation(uri: Uri.parse('/'))]
        : initialEntries;
    _entries = entries
        .map((info) => _MemoryEntry(info: info, identifier: generateIdentifier()))
        .toList();
    index = clampIndex(initialIndex ?? _entries.length - 1);
  }

  late final List<_MemoryEntry> _entries;
  late int index;

  final listeners = <void Function(HistoryEvent event)>[];

  @override
  HistoryAction action = .pop;

  @override
  RouteInformation get location => _entries.elementAt(index).info;

  @override
  String createHref(Uri uri) {
    final buffer = StringBuffer(uri.path);
    if (uri.hasQuery) buffer.write('?${uri.query}');
    if (uri.hasFragment) buffer.write('#${uri.fragment}');
    return buffer.toString();
  }

  @override
  void push(Uri uri, [Object? state]) {
    action = .push;
    index += 1;
    _entries
      ..length = index
      ..add(_MemoryEntry(
        info: RouteInformation(uri: uri, state: state),
        identifier: generateIdentifier(),
      ));
  }

  @override
  void replace(Uri uri, [Object? state]) {
    action = .replace;
    _entries[index] = _MemoryEntry(
      info: RouteInformation(uri: uri, state: state),
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
    _entries.clear();
    listeners.clear();
  }
}

extension on MemoryHistory {
  int clampIndex(int value) => math.min(math.max(value, 0), _entries.length - 1);
}
