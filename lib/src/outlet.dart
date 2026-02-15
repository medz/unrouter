import 'package:flutter/widgets.dart';

import 'inlet.dart';

Widget buildOutletTree(Iterable<ViewBuilder> views) {
  final routeViews = views.toList(growable: false);
  if (routeViews.isEmpty) {
    return const SizedBox.shrink();
  }

  return _OutletScope(
    views: routeViews,
    depth: 0,
    child: const Outlet(),
  );
}

class Outlet extends StatelessWidget {
  const Outlet({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = _OutletScope.of(context);
    final depth = scope.depth;
    if (depth >= scope.views.length) {
      return const SizedBox.shrink();
    }

    return _OutletScope(
      views: scope.views,
      depth: depth + 1,
      child: scope.views[depth](),
    );
  }
}

class _OutletScope extends InheritedWidget {
  const _OutletScope({
    required super.child,
    required this.views,
    required this.depth,
  });

  final List<ViewBuilder> views;
  final int depth;

  static _OutletScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_OutletScope>();
    if (scope != null) {
      return scope;
    }

    throw FlutterError('Outlet must be used inside a router view.');
  }

  @override
  bool updateShouldNotify(covariant _OutletScope oldWidget) {
    return oldWidget.views != views || oldWidget.depth != depth;
  }
}
