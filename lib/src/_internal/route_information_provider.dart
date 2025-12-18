import 'package:flutter/widgets.dart';

import '../history/history.dart';

/// Provides route information and listens to history changes.
class UnrouteInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  UnrouteInformationProvider({required History history})
    : _history = history,
      _value = RouteInformation(
        uri: _locationToUri(history.location),
        state: history.location.state,
      ) {
    // Listen to history changes
    _unlisten = history.listen((event) {
      _value = RouteInformation(
        uri: _locationToUri(event.location),
        state: event.location.state,
      );
      notifyListeners();
    });
  }

  final History _history;
  RouteInformation _value;
  void Function()? _unlisten;

  static Uri _locationToUri(Location location) {
    return Uri(
      path: location.pathname,
      query: location.search.isEmpty ? null : location.search,
      fragment: location.hash.isEmpty ? null : location.hash,
    );
  }

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final newUri = routeInformation.uri;
    final currentUri = _locationToUri(_history.location);

    if (newUri != currentUri) {
      switch (type) {
        case RouteInformationReportingType.none:
        case RouteInformationReportingType.neglect:
          // Don't update history
          break;
        case RouteInformationReportingType.navigate:
          final path = Path(
            pathname: newUri.path,
            search: newUri.query,
            hash: newUri.fragment,
          );
          _history.push(path, routeInformation.state);
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
