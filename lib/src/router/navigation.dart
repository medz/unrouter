import 'package:flutter/widgets.dart';
import 'package:unrouter/history.dart';

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
  /// Navigates to a named route or a path.
  ///
  /// Provide either [name] (for [Inlet.name]) or [path] (for direct paths).
  ///
  /// - If [path] starts with `/`, navigation is absolute.
  /// - Otherwise, the path is appended to the current location (relative
  ///   navigation).
  ///
  /// For named routes and path patterns, [params] are substituted into the
  /// route pattern (`:id`, optional `?` segments, and `*` wildcard).
  /// Optional params are omitted when not provided. Optional static segments
  /// are included when generating the path.
  ///
  /// When using optional segments in [path], pass query values via [query]
  /// instead of embedding them in the path string.
  ///
  /// The optional [state] is stored on the history entry and can be read via
  /// [RouteInformation.state] (see [RouteState.location]).
  ///
  /// If [replace] is `true`, the current history entry is replaced instead of
  /// pushing a new one.
  ///
  /// Throws a [FlutterError] if neither [name] nor [path] is provided, if both
  /// are provided, or if required params are missing.
  Future<Navigation> call({
    String? name,
    String? path,
    Map<String, String> params = const {},
    Map<String, String>? query,
    String? fragment,
    Object? state,
    bool replace = false,
  });

  /// Generates a URI for a named route or path pattern.
  ///
  /// [params] are substituted into dynamic segments in the route pattern.
  /// Optional params are omitted when not provided. Optional static segments
  /// are included when generating the path.
  ///
  /// [query] and [fragment] are appended to the generated URI.
  ///
  /// Provide either [name] (for [Inlet.name]) or [path] (for direct patterns).
  ///
  /// Throws a [FlutterError] if the route name is unknown or required params
  /// are missing, or if both [name] and [path] are provided.
  Uri route({
    String? name,
    String? path,
    Map<String, String> params = const {},
    Map<String, String>? query,
    String? fragment,
  });

  /// Moves within the history stack by [delta] entries.
  Future<Navigation> go(int delta);

  /// Equivalent to calling [go] with `-1`.
  Future<Navigation> back();

  /// Equivalent to calling [go] with `+1`.
  Future<Navigation> forward();
}
