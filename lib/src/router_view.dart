import 'package:flutter/widgets.dart' show BuildContext, InheritedWidget, SizedBox, StatelessWidget, Widget;
import '_internal/scope.dart';

/// Render the matched component at the current depth.
class RouterView extends StatelessWidget {
  const RouterView({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = RouterScope.of(context);
    final currentDepth = _DepthMarker.currentDepth(context);

    if (currentDepth >= scope.route.matches.length) {
      return const SizedBox.shrink();
    }

    final match = scope.route.matches[currentDepth];
    final component = match.route.factory();

    return RouterScope(
      router: scope.router,
      route: scope.route,
      child: _DepthMarker(depth: currentDepth + 1, child: component),
    );
  }
}

/// Tracks depth for nested RouterView.
class _DepthMarker extends InheritedWidget {
  const _DepthMarker({required this.depth, required super.child});
  final int depth;

  static int currentDepth(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DepthMarker>()?.depth ?? 0;

  @override
  bool updateShouldNotify(_DepthMarker oldWidget) => depth != oldWidget.depth;
}
