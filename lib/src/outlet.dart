import 'package:flutter/widgets.dart';

import 'inlet.dart';

class Outlet extends StatelessWidget {
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

class OutletScope extends InheritedWidget {
  const OutletScope({
    required super.child,
    required this.views,
    required this.depth,
    super.key,
  });

  final Iterable<ViewBuilder> views;
  final int depth;

  static OutletScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OutletScope>();
    if (scope != null) return scope;

    throw FlutterError('Outlet must be used inside a router view.');
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
