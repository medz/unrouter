import 'package:flutter/widgets.dart' hide Route;

import 'history/memory.dart';
import 'history/types.dart';
import 'route.dart';
import '_internal/route_information_parser.dart';
import '_internal/route_information_provider.dart';
import '_internal/router_delegate.dart';

/// History mode for the router.
///
/// - [memory]: In-memory history (for testing or mobile apps)
/// - [browser]: Browser history using pushState API
/// - [hash]: Hash-based history (legacy browser support)
enum HistoryMode { memory, browser, hash }

/// The main router for declarative routing.
///
/// Example:
/// ```dart
/// final router = Unrouter([
///   Route.index(HomePage.new),
///   Route.path('about', AboutPage.new),
///   Route.nested('users', UsersLayout.new, [
///     Route.index(UsersIndexPage.new),
///     Route.path(':id', UserDetailPage.new),
///   ]),
/// ], mode: HistoryMode.memory);
///
/// MaterialApp.router(routerConfig: router);
/// ```
class Unrouter extends RouterConfig<RouteInformation> {
  factory Unrouter(
    List<Route> routes, {
    required HistoryMode mode,
    String? initialLocation,
    String base = '/',
  }) {
    final history = _createHistory(mode, base);
    final delegate = UnrouterDelegate(routes: routes);
    delegate.attachHistory(history);

    if (initialLocation != null && initialLocation != '/') {
      history.push(initialLocation);
      delegate.navigateTo(initialLocation);
    }

    return Unrouter._(
      routes: routes,
      routeInformationProvider: UnrouteInformationProvider(history: history),
      routeInformationParser: const UnrouteInformationParser(),
      routerDelegate: delegate,
      backButtonDispatcher: RootBackButtonDispatcher(),
      history: history,
      delegate: delegate,
    );
  }

  Unrouter._({
    required this.routes,
    required super.routeInformationProvider,
    required super.routeInformationParser,
    required super.routerDelegate,
    required super.backButtonDispatcher,
    required RouterHistory history,
    required UnrouterDelegate delegate,
  }) : _history = history,
       _delegate = delegate;

  /// The route configuration.
  final Iterable<Route> routes;

  final RouterHistory _history;
  final UnrouterDelegate _delegate;

  /// Gets the underlying history object.
  RouterHistory get history => _history;

  /// Push a new location onto the history stack.
  ///
  /// Following browser history.pushState() semantics, this does NOT trigger
  /// listeners. The delegate is manually updated.
  void push(String location, [Object? state]) {
    _history.push(location, state);
    _delegate.navigateTo(location, state);
  }

  /// Replace the current location in the history stack.
  ///
  /// Following browser history.replaceState() semantics, this does NOT trigger
  /// listeners. The delegate is manually updated.
  void replace(String location, [Object? state]) {
    _history.replace(location, state);
    _delegate.navigateTo(location, state);
  }

  /// Go back in the history stack.
  void back() => _history.back();

  /// Go forward in the history stack.
  void forward() => _history.forward();

  /// Go to a specific point in the history stack.
  void go(int delta) => _history.go(delta);

  static RouterHistory _createHistory(HistoryMode mode, String base) {
    switch (mode) {
      case HistoryMode.memory:
        return MemoryHistory(base);
      case HistoryMode.browser:
        throw UnimplementedError('Browser history not yet implemented');
      case HistoryMode.hash:
        throw UnimplementedError('Hash history not yet implemented');
    }
  }
}
