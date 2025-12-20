import 'package:flutter/widgets.dart';

import 'navigation.dart';
import 'router.dart';
import 'route_state.dart';

extension UnrouterBuildContext on BuildContext {
  Navigate get navigate {
    final router = Router.maybeOf(this);
    if (router == null) {
      throw FlutterError(
        'context.navigate called with a context that does not contain a Router.\n'
        'No Router ancestor could be found starting from the context that was passed to context.navigate.\n'
        'The context used was:\n'
        '  $this',
      );
    }
    final delegate = router.routerDelegate;
    if (delegate is! Navigate) {
      throw FlutterError(
        'context.navigate called with a Router whose delegate does not implement Navigate.\n'
        'The router delegate type is: ${delegate.runtimeType}\n'
        'Make sure you are using Unrouter or a custom router delegate that implements Navigate.\n'
        'The context used was:\n'
        '  $this',
      );
    }
    return delegate as Navigate;
  }

  Unrouter get router {
    final router = Router.maybeOf(this);
    if (router == null) {
      throw FlutterError(
        'context.router called with a context that does not contain a Router.\n'
        'No Router ancestor could be found starting from the context that was passed to context.router.\n'
        'The context used was:\n'
        '  $this',
      );
    }
    final delegate = router.routerDelegate;
    if (delegate is! UnrouterDelegate) {
      throw FlutterError(
        'context.router called with a Router whose delegate is not UnrouterDelegate.\n'
        'The router delegate type is: ${delegate.runtimeType}\n'
        'Make sure you are using Unrouter.\n'
        'The context used was:\n'
        '  $this',
      );
    }
    return delegate.router;
  }

  RouteState get routeState {
    final provider = dependOnInheritedWidgetOfExactType<RouteStateScope>();
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.state;
  }

  RouteState? get maybeRouteState =>
      dependOnInheritedWidgetOfExactType<RouteStateScope>()?.state;
}
