import 'package:flutter/widgets.dart';

import '../_internal/stacked_route_view.dart';
import '../router_state.dart';

/// A widget that renders the next matched child route.
///
/// Outlet must be used inside layout and nested routes to render their children.
/// It maintains a stack of child widgets to preserve state across navigation.
class Outlet extends StatelessWidget {
  const Outlet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = RouterStateProvider.of(context);
    return StackedRouteView(state: state, levelOffset: 1);
  }
}
