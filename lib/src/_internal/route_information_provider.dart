import 'package:flutter/widgets.dart';

import '../history/types.dart';

/// Provides route information and listens to history changes.
class UnrouteInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  UnrouteInformationProvider({required RouterHistory history})
    : _history = history,
      _value = RouteInformation(
        uri: Uri.parse(history.location),
        state: history.state,
      ) {
    // Listen to history changes
    _unlisten = history.listen((to, from, info) {
      _value = RouteInformation(uri: Uri.parse(to), state: history.state);
      notifyListeners();
    });
  }

  final RouterHistory _history;
  RouteInformation _value;
  VoidCallback? _unlisten;

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final location = routeInformation.uri.path;
    if (location != _history.location) {
      switch (type) {
        case RouteInformationReportingType.none:
        case RouteInformationReportingType.neglect:
          // Don't update history
          break;
        case RouteInformationReportingType.navigate:
          _history.push(location, routeInformation.state);
          break;
      }
    }
  }

  @override
  void dispose() {
    _unlisten?.call();
    super.dispose();
  }
}
