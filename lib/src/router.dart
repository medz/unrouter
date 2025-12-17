import 'package:flutter/widgets.dart';

import 'history/types.dart';
import 'history/memory.dart';
import 'history_mode.dart';
import 'routes.dart';
import 'router_delegate.dart';
import 'route_information_parser.dart';
import 'route_information_provider.dart';

/// The main router that integrates with Flutter's Router API.
///
/// Example:
/// ```dart
/// final router = Unrouter(
///   Routes([
///     Unroute(path: null, factory: Home.new),
///     Unroute(path: 'about', factory: About.new),
///   ]),
///   mode: HistoryMode.memory,
/// );
///
/// MaterialApp.router(
///   routerConfig: router,
/// );
/// ```
///
/// For apps deployed on a subpath:
/// ```dart
/// final router = Unrouter(
///   Routes([...]),
///   mode: HistoryMode.browser,
///   base: '/my-app',  // Deployed at example.com/my-app
/// );
/// ```
class Unrouter extends RouterConfig<RouteInformation> {
  factory Unrouter(
    Routes routes, {
    required HistoryMode mode,
    String? initialLocation,
    String base = '/',
  }) {
    final location = initialLocation ?? '/';
    final history = _createHistory(mode, base);
    final provider = UnrouteInformationProvider(history: history);
    final delegate = UnrouterDelegate(routes: routes);

    // Connect history to router delegate
    delegate.attachHistory(history);

    // Set initial location
    if (location != '/' && location.isNotEmpty) {
      history.push(location);
      // Manually update delegate since push doesn't trigger listeners
      delegate.navigateTo(location);
    }

    return Unrouter._(
      routes: routes,
      mode: mode,
      history: history,
      provider: provider,
      delegate: delegate,
    );
  }

  Unrouter._({
    required this.routes,
    required this.mode,
    required this.history,
    required UnrouteInformationProvider provider,
    required UnrouterDelegate delegate,
  }) : _delegate = delegate,
       super(
          routeInformationProvider: provider,
          routeInformationParser: UnrouteInformationParser(),
          routerDelegate: delegate,
        );

  final UnrouterDelegate _delegate;

  /// The history mode for this router.
  final HistoryMode mode;

  /// The root routes configuration.
  final Routes routes;

  /// The underlying history implementation.
  final RouterHistory history;

  /// Creates the appropriate history implementation based on mode.
  static RouterHistory _createHistory(HistoryMode mode, String base) {
    switch (mode) {
      case HistoryMode.memory:
        return MemoryHistory(base);
      case HistoryMode.browser:
        // TODO: Implement browser history
        throw UnimplementedError('Browser history not yet implemented');
      case HistoryMode.hash:
        // TODO: Implement hash history
        throw UnimplementedError('Hash history not yet implemented');
    }
  }

  /// Navigates to a new location.
  ///
  /// Following browser history.pushState() semantics, this updates
  /// the history stack but the delegate must be notified manually.
  void push(String location, [Object? state]) {
    history.push(location, state);
    // Manually update delegate since pushState doesn't trigger popstate
    _delegate.navigateTo(location, state);
  }

  /// Replaces the current location.
  ///
  /// Following browser history.replaceState() semantics, this updates
  /// the current history entry but the delegate must be notified manually.
  void replace(String location, [Object? state]) {
    history.replace(location, state);
    // Manually update delegate since replaceState doesn't trigger popstate
    _delegate.navigateTo(location, state);
  }

  /// Goes back n steps in history.
  void go(int delta) {
    history.go(delta);
  }

  /// Goes back one step in history.
  void back() {
    history.back();
  }

  /// Goes forward one step in history.
  void forward() {
    history.forward();
  }

  /// Cleans up resources.
  void dispose() {
    history.destroy();
  }
}
