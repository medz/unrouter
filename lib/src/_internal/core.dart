import 'package:flutter/widgets.dart' show BuildContext, Widget, Builder;
import 'package:zenrouter/zenrouter.dart';

import '../route.dart';
import '../page.dart';
import '../router.dart';
import 'tree.dart';

/// Internal coordinator that handles route parsing/rendering.
class CoreCoordinator extends Coordinator<RoutePage> {
  CoreCoordinator({required Iterable<Route> routes, String initialPath = '/'})
    : _tree = RouteTree(routes.toList()),
      _initialUri = _normalize(initialPath);

  late Router router;

  final RouteTree _tree;
  final Uri _initialUri;

  late final RoutePage _initialPage = parseRouteFromUri(_initialUri);

  /// Replace stack with [path].
  void goPath(String path) => replace(parseRouteFromUri(_normalize(path)));

  /// Push new page.
  Future<dynamic> pushPath(String path) =>
      push(parseRouteFromUri(_normalize(path)));

  @override
  Widget layoutBuilder(BuildContext context) => NavigationStack<RoutePage>(
    path: root,
    coordinator: this,
    defaultRoute: _initialPage,
    resolver: (route) => StackTransition.material(
      Builder(builder: (ctx) => route.build(this, ctx)),
    ),
  );

  @override
  RoutePage parseRouteFromUri(Uri uri) {
    final matches = _tree.match(uri);
    if (matches != null) {
      return RoutePage(uri: uri, matches: matches, router: router);
    }

    final fallback = _tree.matchFallback(uri);
    if (fallback != null) {
      return RoutePage(uri: uri, matches: fallback, router: router);
    }

    throw StateError('No route matched for ${uri.path}');
  }

  String? pathForName(String name, Map<String, String> params) =>
      _tree.buildPathForName(name, params);

  static Uri _normalize(String path) =>
      path.startsWith('/') ? Uri.parse(path) : Uri.parse('/$path');
}
