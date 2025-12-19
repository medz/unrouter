/// Declarative routing for Flutter.
///
/// `unrouter` provides a small, declarative router built on Flutter's `Router`
/// API (Navigator 2.0).
///
/// - Define a route tree with [Inlet]
/// - Render nested routes with [Outlet]
/// - Navigate with browser-like history operations via [Unrouter] or
///   [Navigate.of]
///
/// Basic usage:
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:unrouter/unrouter.dart';
///
/// final router = Unrouter(
///   routes: const [
///     Inlet(factory: HomePage.new),
///     Inlet(path: 'about', factory: AboutPage.new),
///   ],
/// );
///
/// void main() => runApp(MaterialApp.router(routerConfig: router));
/// ```
///
/// For web-only history implementations (`BrowserHistory` / `HashHistory`),
/// import `package:unrouter/browser.dart`.
library;

export 'src/history/history.dart';
export 'src/history/memory.dart';

export 'src/widgets/link.dart';
export 'src/widgets/outlet.dart';
export 'src/widgets/routes.dart';

export 'src/inlet.dart';
export 'src/navigation.dart';
export 'src/route_matcher.dart' show MatchedRoute;
export 'src/router.dart';
export 'src/router_state.dart';
export 'src/url_strategy.dart';
