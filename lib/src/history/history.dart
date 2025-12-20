import 'package:flutter/widgets.dart';

import '_utils.dart';

/// The kind of navigation that produced the current [History.location].
enum HistoryAction {
  /// Navigation caused by [History.go], [History.back] or [History.forward].
  ///
  /// On the web this corresponds to a `popstate` event (user pressed the
  /// browser back/forward buttons, or code called `history.go()`).
  pop,

  /// A new entry was added to the history stack via [History.push].
  push,

  /// The current entry was replaced via [History.replace].
  replace,
}

/// A navigation event emitted by [History.listen].
class HistoryEvent {
  /// The type of navigation that occurred.
  final HistoryAction action;

  /// The new location after the navigation finished.
  final RouteInformation location;

  /// The navigation delta, if known (e.g. -1 for back, +1 for forward).
  ///
  /// Some implementations may not be able to determine the delta.
  final int? delta;

  const HistoryEvent({
    required this.action,
    required this.location,
    this.delta,
  });
}

/// A minimal browser-like history abstraction used by `unrouter`.
///
/// The contract intentionally mirrors common browser semantics:
///
/// - [push] and [replace] update [location] immediately and MUST NOT trigger
///   listeners registered via [listen].
/// - [go] / [back] / [forward] represent moving within the existing history
///   stack. Implementations SHOULD notify listeners with a [HistoryEvent] when
///   the navigation completes.
abstract class History {
  const History();

  /// The last navigation action performed by this history.
  HistoryAction get action;

  /// The current location, including the optional per-entry [RouteInformation.state].
  RouteInformation get location;

  /// The current index in the history stack.
  ///
  /// This is useful for tracking the position in the history stack after page
  /// refresh, especially on the web where the browser maintains the history stack
  /// but application state is lost.
  int get index;

  /// Formats a [Uri] as an `href` for this history implementation.
  ///
  /// This is primarily useful on the web (e.g. when calling
  /// `window.history.pushState`), but can also be used to generate link targets.
  String createHref(Uri uri);

  /// Pushes a new history entry.
  ///
  /// The optional [state] is stored on the entry and can be read back via
  /// [location]'s [RouteInformation.state].
  void push(Uri uri, [Object? state]);

  /// Replaces the current history entry.
  ///
  /// The optional [state] is stored on the entry and can be read back via
  /// [location]'s [RouteInformation.state].
  void replace(Uri uri, [Object? state]);

  /// Moves within the history stack by [delta] entries.
  void go(int delta);

  /// Equivalent to calling [go] with `-1`.
  void back() => go(-1);

  /// Equivalent to calling [go] with `+1`.
  void forward() => go(1);

  /// Registers a listener that is called when a `pop` navigation completes.
  ///
  /// Returns a function that removes the listener.
  void Function() listen(void Function(HistoryEvent event) listener);

  /// Releases resources held by the history (e.g. DOM event listeners).
  void dispose();
}

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
  MemoryHistory({List<RouteInformation>? initialEntries, int? initialIndex}) {
    final entries = (initialEntries == null || initialEntries.isEmpty)
        ? [RouteInformation(uri: Uri.parse('/'))]
        : initialEntries;
    _entries = entries
        .map(
          (info) => _MemoryEntry(info: info, identifier: generateIdentifier()),
        )
        .toList();
    index = clampIndex(initialIndex ?? _entries.length - 1);
  }

  late final List<_MemoryEntry> _entries;

  @override
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
      ..add(
        _MemoryEntry(
          info: RouteInformation(uri: uri, state: state),
          identifier: generateIdentifier(),
        ),
      );
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
  int clampIndex(int value) => value.clamp(0, _entries.length - 1);
}
