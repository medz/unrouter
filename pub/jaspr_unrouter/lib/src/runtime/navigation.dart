import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart' as jaspr_router;

import '../core/route_data.dart';

/// Runtime controller backed by `jaspr_router.RouterState`.
class UnrouterController<R extends RouteData> {
  UnrouterController._({
    required BuildContext context,
    required jaspr_router.RouterState routerState,
  }) : _context = context,
       _routerState = routerState;

  final BuildContext _context;
  final jaspr_router.RouterState _routerState;

  /// Current location URI.
  Uri get uri => Uri.parse(jaspr_router.RouteState.of(_context).location);

  /// Pushes [route] onto history stack.
  Future<void> push(R route, {Object? extra}) {
    return _routerState.push(route.toUri().toString(), extra: extra);
  }

  /// Replaces current history entry with [route].
  void replace(R route, {Object? extra}) {
    _routerState.replace(route.toUri().toString(), extra: extra);
  }

  /// Alias of [replace], aligned with core controller naming.
  void go(R route, {Object? extra}) {
    replace(route, extra: extra);
  }

  /// Triggers browser/server back navigation.
  void back() {
    _routerState.back();
  }
}

/// `BuildContext` helpers for Jaspr router access.
extension UnrouterBuildContextExtension on BuildContext {
  /// Returns an untyped router controller.
  UnrouterController<RouteData> get unrouter {
    return UnrouterController<RouteData>._(
      context: this,
      routerState: jaspr_router.Router.of(this),
    );
  }

  /// Returns a typed router controller.
  UnrouterController<R> unrouterAs<R extends RouteData>() {
    return UnrouterController<R>._(
      context: this,
      routerState: jaspr_router.Router.of(this),
    );
  }
}
