import 'package:flutter/widgets.dart';

import 'inlet.dart';

/// Renders the next matched view in the active nested route chain.
///
/// Place [Outlet] inside a parent layout view to render child views declared
/// by nested routes. Each [Outlet] consumes one depth level from [OutletScope].
///
/// Example:
/// ```dart
/// class UsersLayout extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: const [
///         Text('Users layout'),
///         const Outlet(),
///       ],
///     );
///   }
/// }
/// ```
///
/// Prefer `const Outlet()` when no runtime arguments are needed so static child
/// trees can keep deeper nodes from being rebuilt unnecessarily.
class Outlet extends StatelessWidget {
  /// Creates an outlet widget.
  const Outlet({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = OutletScope.of(context);
    final depth = scope.depth;
    if (depth >= scope.views.length) {
      return const SizedBox.shrink();
    }

    return OutletScope(
      views: scope.views,
      depth: depth + 1,
      child: _ViewHost(builder: scope.views.elementAt(depth)),
    );
  }
}

/// Inherited scope used by [Outlet] to resolve nested views by depth.
///
/// This scope is created by the router delegate and then advanced by each
/// rendered [Outlet].
///
/// See also:
///
///  * [Outlet], which reads from [OutletScope] and advances depth.
class OutletScope extends InheritedWidget {
  /// Creates an outlet scope.
  const OutletScope({
    required super.child,
    required this.views,
    required this.depth,
    super.key,
  });

  /// Ordered view builders for the matched route chain.
  final Iterable<ViewBuilder> views;

  /// Zero-based depth for the next [Outlet] lookup.
  final int depth;

  /// Looks up the nearest [OutletScope] from [context].
  ///
  /// Throws a [FlutterError] when [Outlet] is used outside a routed view.
  static OutletScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OutletScope>();
    if (scope != null) return scope;

    throw FlutterError('Outlet must be used inside a routed view.');
  }

  @override
  bool updateShouldNotify(covariant OutletScope oldWidget) {
    return oldWidget.views != views || oldWidget.depth != depth;
  }
}

class _ViewHost extends StatefulWidget {
  const _ViewHost({required this.builder});

  final ViewBuilder builder;

  @override
  State<_ViewHost> createState() => _ViewHostState();
}

class _ViewHostState extends State<_ViewHost> {
  late Widget child = widget.builder.call();

  @override
  void didUpdateWidget(covariant _ViewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) {
      child = widget.builder.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
