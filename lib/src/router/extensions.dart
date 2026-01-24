import 'package:flutter/widgets.dart';

import 'package:unrouter/history.dart';

import 'navigation.dart';
import 'router.dart';
import '_internal/route_animation.dart';
import '_internal/route_params.dart';
import '_internal/route_state_scope.dart';
import 'route_location.dart';
import 'route_matcher.dart';
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
    final provider = RouteStateScope.maybeOfAll(this);
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.state;
  }

  RouteState? get maybeRouteState => RouteStateScope.maybeOfAll(this)?.state;

  RouteLocation get location {
    final provider = RouteStateScope.maybeOf(
      this,
      aspect: RouteStateAspect.location,
    );
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.location;
  }

  List<MatchedRoute> get matchedRoutes {
    final provider = RouteStateScope.maybeOf(
      this,
      aspect: RouteStateAspect.matchedRoutes,
    );
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.matchedRoutes;
  }

  Map<String, String> get params {
    final matchedProvider = RouteStateScope.maybeOf(
      this,
      aspect: RouteStateAspect.matchedRoutes,
    );
    final levelProvider = RouteStateScope.maybeOf(
      this,
      aspect: RouteStateAspect.level,
    );
    final provider = matchedProvider ?? levelProvider;
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    final state = provider!.state;
    return resolveParamsForLevel(state.matchedRoutes, state.level);
  }

  int get routeLevel {
    final provider = RouteStateScope.maybeOf(
      this,
      aspect: RouteStateAspect.level,
    );
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.level;
  }

  int get historyIndex {
    final provider = RouteStateScope.maybeOf(
      this,
      aspect: RouteStateAspect.historyIndex,
    );
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.historyIndex;
  }

  HistoryAction get historyAction {
    final provider = RouteStateScope.maybeOf(
      this,
      aspect: RouteStateAspect.action,
    );
    assert(
      provider != null,
      'No RouteStateScope found in context. '
      'Make sure your widget is a descendant of Unrouter.',
    );
    return provider!.action;
  }

  AnimationController routeAnimation({
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final scope = RouteAnimationScope.maybeOf(this);
    if (scope == null) {
      throw FlutterError(
        'context.routeAnimation called with a context that does not contain a RouteAnimationScope.\n'
        'No RouteAnimationScope ancestor could be found starting from the context that was passed to context.routeAnimation.\n'
        'The context used was:\n'
        '  $this',
      );
    }

    return scope.handle.ensureController(
      RouteAnimationConfig(
        defaultValue: scope.isActive ? 1.0 : 0.0,
        value: value,
        duration: duration,
        reverseDuration: reverseDuration,
        debugLabel: debugLabel,
        lowerBound: lowerBound,
        upperBound: upperBound,
        animationBehavior: animationBehavior,
      ),
    );
  }
}
