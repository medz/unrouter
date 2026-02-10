import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

class UnrouterRouteInformationParser
    extends RouteInformationParser<HistoryLocation> {
  const UnrouterRouteInformationParser();

  @override
  Future<HistoryLocation> parseRouteInformation(
    RouteInformation routeInformation,
  ) async => HistoryLocation(routeInformation.uri, routeInformation.state);

  @override
  RouteInformation restoreRouteInformation(HistoryLocation configuration) =>
      RouteInformation(uri: configuration.uri, state: configuration.state);
}
