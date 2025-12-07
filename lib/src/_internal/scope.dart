import 'package:flutter/widgets.dart' show BuildContext, InheritedModel;

import '../route.dart';
import '../router.dart';

enum Scope { route, query, params }

class RouterScope extends InheritedModel<Scope> {
  const RouterScope({
    super.key,
    required this.router,
    required this.route,
    required super.child,
  });

  final Router router;
  final RouteSnapshot route;

  static RouterScope of(BuildContext context, {Scope? aspect}) {
    final scope = InheritedModel.inheritFrom<RouterScope>(
      context,
      aspect: aspect,
    );
    if (scope == null) {
      throw StateError('RouterView must be under RouterScope');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(RouterScope oldWidget) =>
      route.uri != oldWidget.route.uri ||
      route.matches.length != oldWidget.route.matches.length;

  @override
  bool updateShouldNotifyDependent(RouterScope oldWidget, Set<Scope> deps) {
    if (deps.contains(Scope.query) &&
        route.uri.query != oldWidget.route.uri.query) {
      return true;
    }

    if (deps.contains(Scope.params) &&
        route.params.toString() != oldWidget.route.params.toString()) {
      return true;
    }

    if (deps.contains(Scope.route) &&
        (route.uri != oldWidget.route.uri ||
            route.matches.length != oldWidget.route.matches.length)) {
      return true;
    }

    return false;
  }
}
