import 'package:nocterm/nocterm.dart';

import 'inlet.dart';

/// Renders the next matched view in the active nested route chain.
class Outlet extends StatelessComponent {
  /// Creates an outlet component.
  const Outlet({super.key});

  @override
  Component build(BuildContext context) {
    final scope = OutletScope.of(context);
    final depth = scope.depth;
    if (depth >= scope.views.length) {
      return const SizedBox.shrink();
    }

    return OutletScope(
      views: scope.views,
      depth: depth + 1,
      child: _ViewHost(builder: scope.views[depth]),
    );
  }
}

/// Inherited scope used by [Outlet] to resolve nested views by depth.
class OutletScope extends InheritedComponent {
  /// Creates an outlet scope.
  const OutletScope({
    required super.child,
    required this.views,
    required this.depth,
    super.key,
  });

  /// Ordered view builders for the matched route chain.
  final List<ViewBuilder> views;

  /// Zero-based depth for the next [Outlet] lookup.
  final int depth;

  /// Looks up the nearest [OutletScope] from [context].
  static OutletScope of(BuildContext context) {
    final scope = context.dependOnInheritedComponentOfExactType<OutletScope>();
    if (scope != null) return scope;

    throw StateError('Outlet must be used inside a routed view.');
  }

  @override
  bool updateShouldNotify(covariant OutletScope oldComponent) {
    return oldComponent.views != views || oldComponent.depth != depth;
  }
}

class _ViewHost extends StatefulComponent {
  const _ViewHost({required this.builder});

  final ViewBuilder builder;

  @override
  State<_ViewHost> createState() => _ViewHostState();
}

class _ViewHostState extends State<_ViewHost> {
  late Component child = component.builder.call();

  @override
  void didUpdateComponent(covariant _ViewHost oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.builder != component.builder) {
      child = component.builder.call();
    }
  }

  @override
  Component build(BuildContext context) {
    return child;
  }
}
