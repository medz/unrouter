import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

class UnrouterRouteInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  UnrouterRouteInformationProvider(this.history)
    : value = RouteInformation(
        uri: history.location.uri,
        state: history.location.state,
      ) {
    unlisten = history.listen((event) {
      value = RouteInformation(
        uri: event.location.uri,
        state: event.location.state,
      );
      notifyListeners();
    });
  }

  final History history;
  late final VoidCallback unlisten;

  @override
  RouteInformation value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = .none,
  }) {
    if (type == .navigate) {
      history.push(routeInformation.uri, state: routeInformation.state);
    }
  }

  @override
  void dispose() {
    unlisten();
    history.dispose();
    super.dispose();
  }
}
