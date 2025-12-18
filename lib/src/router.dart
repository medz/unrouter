import 'package:flutter/widgets.dart';

import 'history/memory.dart';
import 'history/types.dart';
import 'inlet.dart';
import '_internal/route_information_parser.dart';
import '_internal/route_information_provider.dart';
import '_internal/router_delegate.dart';
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
    final delegate = UnrouterDelegate(routes: routes);
    delegate.attachHistory(history);

    if (initialLocation != null && initialLocation != '/') {
      history.push(initialLocation);
      delegate.pushTo(initialLocation);
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
  final Iterable<Inlet> routes;

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
    _delegate.pushTo(location, state);
  }

  /// Replace the current location in the history stack.
  ///
  /// Following browser history.replaceState() semantics, this does NOT trigger
  /// listeners. The delegate is manually updated.
  void replace(String location, [Object? state]) {
    _history.replace(location, state);
    _delegate.replaceTo(location, state);
  }

  /// Go back in the history stack.
  void back() => _history.back();

  /// Go forward in the history stack.
  void forward() => _history.forward();

  /// Go to a specific point in the history stack.
  void go(int delta) => _history.go(delta);
}
