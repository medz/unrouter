import 'package:nocterm/nocterm.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter_core/unrouter_core.dart'
    show RouteParams, URLSearchParams;

import 'outlet.dart';
import 'route_scope.dart';
import 'router.dart';

/// Renders the currently matched Unrouter route chain in a Nocterm app.
class UnrouterHost extends StatefulComponent {
  /// Creates a Nocterm routing host.
  const UnrouterHost({required this.router, super.key});

  /// Router used as the source of truth for page navigation state.
  final Unrouter router;

  @override
  State<UnrouterHost> createState() => _UnrouterHostState();
}

class _UnrouterHostState extends State<UnrouterHost> {
  late HistoryLocation currentLocation = component.router.history.location;
  HistoryLocation? fromLocation;

  @override
  void initState() {
    super.initState();
    component.router.addListener(_didLocationChange);
  }

  @override
  void didUpdateComponent(covariant UnrouterHost oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.router == component.router) {
      return;
    }

    oldComponent.router.removeListener(_didLocationChange);
    component.router.addListener(_didLocationChange);
    currentLocation = component.router.history.location;
    fromLocation = null;
  }

  @override
  void dispose() {
    component.router.removeListener(_didLocationChange);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final location = component.router.history.location;
    final match = component.router.matcher.match(location.path);
    if (match == null) {
      throw StateError('No route matched path "${location.path}".');
    }

    final route = match.data;
    final views = route.views;
    final iterator = views.iterator;
    if (!iterator.moveNext()) {
      throw StateError('No views found for matched path "${location.path}".');
    }

    return RouteScopeProvider(
      route: route,
      params: RouteParams(match.params ?? const <String, String>{}),
      location: location,
      query: URLSearchParams(location.query),
      fromLocation: fromLocation,
      child: OutletScope(
        views: views,
        depth: 1,
        child: _HostView(builder: iterator.current),
      ),
    );
  }

  void _didLocationChange() {
    if (!mounted) return;

    final next = component.router.history.location;
    if (currentLocation.uri == next.uri &&
        currentLocation.state == next.state) {
      return;
    }

    setState(() {
      fromLocation = currentLocation;
      currentLocation = next;
    });
  }
}

class _HostView extends StatefulComponent {
  const _HostView({required this.builder});

  final Component Function() builder;

  @override
  State<_HostView> createState() => _HostViewState();
}

class _HostViewState extends State<_HostView> {
  late Component child = component.builder.call();

  @override
  void didUpdateComponent(covariant _HostView oldComponent) {
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
