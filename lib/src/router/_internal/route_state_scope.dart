import 'package:flutter/widgets.dart';
import 'package:unrouter/history.dart';

import '../route_location.dart';
import '../route_matcher.dart';
import '../route_state.dart';

enum RouteStateAspect { location, matchedRoutes, level, historyIndex, action }

class RouteStateScope extends InheritedModel<RouteStateAspect> {
  const RouteStateScope({super.key, required this.state, required super.child});

  final RouteState state;

  static RouteStateScope? maybeOf(
    BuildContext context, {
    RouteStateAspect? aspect,
  }) {
    return InheritedModel.inheritFrom<RouteStateScope>(context, aspect: aspect);
  }

  static RouteStateScope? maybeOfAll(BuildContext context) {
    RouteStateScope? scope;
    for (final aspect in RouteStateAspect.values) {
      scope = maybeOf(context, aspect: aspect) ?? scope;
    }
    return scope;
  }

  @override
  bool updateShouldNotify(RouteStateScope oldWidget) {
    return state != oldWidget.state;
  }

  @override
  bool updateShouldNotifyDependent(
    RouteStateScope oldWidget,
    Set<RouteStateAspect> aspects,
  ) {
    final current = state;
    final previous = oldWidget.state;

    for (final aspect in aspects) {
      switch (aspect) {
        case RouteStateAspect.location:
          if (!_sameLocation(previous.location, current.location)) {
            return true;
          }
          break;
        case RouteStateAspect.matchedRoutes:
          if (!_sameMatchedRoutes(
            previous.matchedRoutes,
            current.matchedRoutes,
          )) {
            return true;
          }
          break;
        case RouteStateAspect.level:
          if (previous.level != current.level) {
            return true;
          }
          break;
        case RouteStateAspect.historyIndex:
          if (previous.historyIndex != current.historyIndex) {
            return true;
          }
          break;
        case RouteStateAspect.action:
          if (previous.action != current.action) {
            return true;
          }
          break;
      }
    }

    return false;
  }

  bool _sameLocation(RouteLocation a, RouteLocation b) {
    return a.uri == b.uri && a.state == b.state && a.name == b.name;
  }

  bool _sameMatchedRoutes(List<MatchedRoute> a, List<MatchedRoute> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (!identical(left.route, right.route)) return false;
      if (!_sameParams(left.params, right.params)) return false;
    }
    return true;
  }

  bool _sameParams(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  RouteLocation get location => state.location;
  List<MatchedRoute> get matchedRoutes => state.matchedRoutes;
  int get level => state.level;
  int get historyIndex => state.historyIndex;
  HistoryAction get action => state.action;
}
