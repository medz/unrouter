import 'package:flutter/widgets.dart';

import 'history/history.dart';

/// Provides route information and listens to history changes.
class UnrouterInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  UnrouterInformationProvider({required History history})
    : _history = history,
      _value = history.location {
    // Listen to history changes
    _unlisten = history.listen((event) {
      _value = event.location;
      notifyListeners();
    });
  }

  final History _history;
  RouteInformation _value;
  void Function()? _unlisten;

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final newUri = routeInformation.uri;
    final currentUri = _history.location.uri;

    if (newUri != currentUri) {
      switch (type) {
        case RouteInformationReportingType.none:
        case RouteInformationReportingType.neglect:
          // Don't update history
          break;
        case RouteInformationReportingType.navigate:
          _history.push(newUri, routeInformation.state);
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
