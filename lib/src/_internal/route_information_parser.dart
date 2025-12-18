import 'package:flutter/widgets.dart';

/// Parses route information from the browser URL.
///
/// This is a simple pass-through parser that just extracts the location
/// from RouteInformation.
class UnrouterInformationParser
    extends RouteInformationParser<RouteInformation> {
  const UnrouterInformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation;
  }

  @override
  RouteInformation? restoreRouteInformation(RouteInformation configuration) {
    return configuration;
  }
}
