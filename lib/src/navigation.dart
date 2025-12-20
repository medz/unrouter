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
/// access it via [Navigate.of].
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
  /// [RouteInformation.state] (see [RouterState.location]).
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

  /// Retrieves the current [Navigate] implementation from the nearest [Router].
  ///
  /// This assumes the app is using a router delegate that implements
  /// [Navigate] (such as [UnrouterDelegate]).
  ///
  /// Throws a [FlutterError] if called outside a Router scope or if the
  /// router delegate does not implement [Navigate].
  static Navigate of(BuildContext context) {
    final router = Router.maybeOf(context);
    if (router == null) {
      throw FlutterError(
        'Navigate.of() called with a context that does not contain a Router.\n'
        'No Router ancestor could be found starting from the context that was passed to Navigate.of().\n'
        'The context used was:\n'
        '  $context',
      );
    }
    final delegate = router.routerDelegate;
    if (delegate is! Navigate) {
      throw FlutterError(
        'Navigate.of() called with a Router whose delegate does not implement Navigate.\n'
        'The router delegate type is: ${delegate.runtimeType}\n'
        'Make sure you are using Unrouter or a custom router delegate that implements Navigate.\n'
        'The context used was:\n'
        '  $context',
      );
    }
    return delegate as Navigate;
  }
}
