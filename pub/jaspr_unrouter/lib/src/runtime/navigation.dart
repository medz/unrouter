import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart' as core show UnrouterController;

import '../core/route_data.dart';

/// Runtime controller is directly reused from core.
typedef UnrouterController<R extends RouteData> = core.UnrouterController<R>;

/// Provides `UnrouterController` to descendants.
class UnrouterScope extends InheritedComponent {
  const UnrouterScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final UnrouterController<RouteData> controller;

  static UnrouterController<RouteData> of(BuildContext context) {
    final scope = context
        .dependOnInheritedComponentOfExactType<UnrouterScope>();
    if (scope != null) {
      return scope.controller;
    }

    throw StateError(
      'UnrouterScope was not found in context. '
      'No UnrouterRouter is available above this BuildContext.',
    );
  }

  static UnrouterController<R> ofAs<R extends RouteData>(BuildContext context) {
    return of(context).cast<R>();
  }

  @override
  bool updateShouldNotify(UnrouterScope oldComponent) {
    return controller != oldComponent.controller;
  }
}

/// `BuildContext` helpers for Jaspr router access.
extension UnrouterBuildContextExtension on BuildContext {
  /// Returns an untyped router controller.
  UnrouterController<RouteData> get unrouter => UnrouterScope.of(this);

  /// Returns a typed router controller.
  UnrouterController<R> unrouterAs<R extends RouteData>() {
    return UnrouterScope.ofAs<R>(this);
  }
}
