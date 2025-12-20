import 'package:flutter/widgets.dart';

import 'history/history.dart';

@immutable
sealed class Navigation {
  const Navigation({required this.from, required this.requested});

  final RouteInformation from;
  final RouteInformation requested;
}

final class NavigationSuccess extends Navigation {
  const NavigationSuccess({
    required super.from,
    required super.requested,
    required this.to,
    required this.action,
    this.redirectCount = 0,
  });

  final RouteInformation to;
  final HistoryAction action;
  final int redirectCount;
}

final class NavigationRedirected extends NavigationSuccess {
  const NavigationRedirected({
    required super.from,
    required super.requested,
    required super.to,
    required super.action,
    required super.redirectCount,
  });
}

final class NavigationCancelled extends Navigation {
  const NavigationCancelled({required super.from, required super.requested});
}

final class NavigationFailed extends Navigation {
  const NavigationFailed({
    required super.from,
    required super.requested,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;
}

/// Browser-style navigation operations exposed by `unrouter`.
///
/// `Navigate` is implemented by [UnrouterDelegate]. In a widget tree you can
/// access it via `context.navigate` (see [UnrouterBuildContext]).
///
/// All methods return a `Future<Navigation>` describing the result. You can
/// ignore the future if you don't need the outcome.
abstract interface class Navigate {
  /// Navigates to [uri].
  ///
  /// - If `uri.path` starts with `/`, navigation is absolute.
  /// - Otherwise, the path is appended to the current location (relative
  ///   navigation).
  ///
  /// The optional [state] is stored on the history entry and can be read via
  /// [RouteInformation.state] (see [RouteState.location]).
  ///
  /// If [replace] is `true`, the current history entry is replaced instead of
  /// pushing a new one.
  Future<Navigation> call(Uri uri, {Object? state, bool replace = false});

  /// Moves within the history stack by [delta] entries.
  Future<Navigation> go(int delta);

  /// Equivalent to calling [go] with `-1`.
  Future<Navigation> back();

  /// Equivalent to calling [go] with `+1`.
  Future<Navigation> forward();
}
