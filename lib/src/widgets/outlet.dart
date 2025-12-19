import 'package:flutter/widgets.dart';

import '../_internal/stacked_route_view.dart';
import '../router_state.dart';

/// A widget that renders the next matched child from declarative routes.
///
/// `Outlet` must be used inside layout and nested routes (defined in `Unrouter.routes`)
/// to render their children.
///
/// It keeps child widgets stacked so their state is preserved across
/// navigation. `Outlet` must be a descendant of `Unrouter` (it relies on
/// [RouterStateProvider]).
///
/// For widget-scoped routing, use the [Routes] widget instead.
class Outlet extends StatelessWidget {
  const Outlet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = RouterStateProvider.of(context);
    return StackedRouteView(state: state, levelOffset: 1);
  }
}
