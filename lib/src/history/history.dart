import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

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

/// Internal state stored in a browser history entry.
///
/// This is used by `unrouter`'s web history implementation to keep extra
/// metadata (like an index) alongside the user-provided entry state.
///
/// Do not rely on the shape of this object; it is an implementation detail.
@internal
class HistoryState {
  /// The user-provided state passed to [History.push] / [History.replace].
  final Object? userData;

  /// The current position in the history stack, as tracked by `unrouter`.
  final int index;

  /// An internal identifier for the entry.
  final String? identifier;

  const HistoryState({required this.index, this.identifier, this.userData});

  /// Converts this object into a plain `Map` suitable for serialization.
  Map<String, dynamic> toJson() => {
        'index': index,
        'identifier': identifier,
        'userData': userData,
      };

  /// Creates an instance from a JSON-like `Map`.
  factory HistoryState.fromJson(Map<dynamic, dynamic> json) => HistoryState(
        index: json['index'] as int? ?? 0,
        identifier: json['identifier'] as String?,
        userData: json['userData'],
      );
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
