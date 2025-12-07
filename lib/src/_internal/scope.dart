import 'package:flutter/widgets.dart' show BuildContext, InheritedWidget, Widget;
import '../route.dart';
import '../router_base.dart';

class RouterScope extends InheritedWidget {
  const RouterScope({
    super.key,
    required this.router,
    required this.route,
    required super.child,
  });

  final Router router;
  final RouteSnapshot route;

  static RouterScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RouterScope>();
    if (scope == null) {
      throw StateError('RouterView must be under RouterScope');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(RouterScope oldWidget) =>
      route.uri != oldWidget.route.uri ||
      route.matches.length != oldWidget.route.matches.length;
}
