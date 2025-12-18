import 'package:flutter/widgets.dart';

import '../history/history.dart';

/// Provides route information and listens to history changes.
class UnrouterInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  UnrouterInformationProvider(this.history) : value = history.location {
    unlisten = history.listen((event) {
      value = event.location;
      notifyListeners();
    });
  }

  final History history;
  late final void Function() unlisten;

  @override
  RouteInformation value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final newUri = routeInformation.uri;
    final currentUri = history.location.uri;

    if (newUri != currentUri) {
      switch (type) {
        case RouteInformationReportingType.none:
        case RouteInformationReportingType.neglect:
          // Don't update history
          break;
        case RouteInformationReportingType.navigate:
          history.push(newUri, routeInformation.state);
          break;
      }
    }
  }

  @override
  void dispose() {
    unlisten();
    super.dispose();
  }
}
