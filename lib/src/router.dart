import 'package:flutter/widgets.dart';

import 'history/history.dart';
import 'inlet.dart';
import 'route_information_parser.dart';
import 'route_information_provider.dart';
import 'router_delegate.dart';
import 'url_strategy.dart';

import '_internal/create_history.memory.dart'
    if (dart.library.js_interop) '_internal/create_history.browser.dart';

/// The main router for declarative routing.
///
/// Example:
/// ```dart
/// final router = Unrouter(
///   routes: [
///     Inlet(factory: HomePage.new),
///     Inlet(path: 'about', factory: AboutPage.new),
///     Inlet(path: 'users', factory: UsersLayout.new, children: [
///       Inlet(factory: UsersIndexPage.new),
///       Inlet(path: ':id', factory: UserDetailPage.new),
///     ]),
///   ],
/// );
///
/// MaterialApp.router(routerConfig: router);
/// ```
class Unrouter extends RouterConfig<RouteInformation> {
  factory Unrouter({
    required List<Inlet> routes,
    UrlStrategy strategy = .hash,
    History? history,
  }) {
    history ??= createHistory(strategy);
    final delegate = UnrouterDelegate(routes: routes, history: history);

    return Unrouter._(
      routes: routes,
      routeInformationProvider: UnrouterInformationProvider(history: history),
      routeInformationParser: const UnrouterInformationParser(),
      routerDelegate: delegate,
      backButtonDispatcher: RootBackButtonDispatcher(),
      history: history,
    );
  }

  Unrouter._({
    required super.routeInformationProvider,
    required super.routeInformationParser,
    required super.routerDelegate,
    required super.backButtonDispatcher,
    required this.routes,
    required this.history,
  });

  /// The route configuration.
  final Iterable<Inlet> routes;
  final History history;

  @override
  UnrouterDelegate get routerDelegate =>
      super.routerDelegate as UnrouterDelegate;

  /// Push a new location onto the history stack.
  ///
  /// Following browser history.pushState() semantics, this does NOT trigger
  /// listeners. The delegate is manually updated.
  ///
  /// If [location] starts with '/', it's treated as an absolute path.
  /// Otherwise, it's a relative path appended to the current location.
  void push(String location, [Object? state]) {
    final uri = Uri.parse(location);
    final resolvedUri = routerDelegate.resolveUri(uri);

    history.push(resolvedUri, state);
    routerDelegate.navigate(uri, state: state);
  }

  /// Replace the current location in the history stack.
  ///
  /// Following browser history.replaceState() semantics, this does NOT trigger
  /// listeners. The delegate is manually updated.
  ///
  /// If [location] starts with '/', it's treated as an absolute path.
  /// Otherwise, it's a relative path appended to the current location.
  void replace(String location, [Object? state]) {
    final uri = Uri.parse(location);
    final resolvedUri = routerDelegate.resolveUri(uri);
    history.replace(resolvedUri, state);
    routerDelegate.navigate(uri, state: state, replace: true);
  }

  /// Go back in the history stack.
  void back() => history.back();

  /// Go forward in the history stack.
  void forward() => history.forward();

  /// Go to a specific point in the history stack.
  void go(int delta) => history.go(delta);
}
