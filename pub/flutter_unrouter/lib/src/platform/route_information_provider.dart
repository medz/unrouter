import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

class UnrouterRouteInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  UnrouterRouteInformationProvider(this.history)
    : _lastAction = history.action,
      _lastDelta = null,
      value = RouteInformation(
        uri: history.location.uri,
        state: history.location.state,
      ) {
    _unlisten = history.listen((event) {
      _lastAction = event.action;
      _lastDelta = event.delta;
      _syncFromHistory();
    });
  }

  final History history;
  late final VoidCallback _unlisten;
  HistoryAction _lastAction;
  int? _lastDelta;

  @override
  RouteInformation value;

  HistoryAction get lastAction => _lastAction;

  int? get lastDelta => _lastDelta;

  int? get historyIndex => history.index;

  bool get canGoBack => (history.index ?? 0) > 0;

  void push(Uri uri, {Object? state}) {
    _lastAction = HistoryAction.push;
    _lastDelta = null;
    history.push(uri, state: state);
    _update(uri, state);
  }

  void replace(Uri uri, {Object? state}) {
    _lastAction = HistoryAction.replace;
    _lastDelta = null;
    history.replace(uri, state: state);
    _update(uri, state);
  }

  void go(int delta) {
    history.go(delta);
  }

  void back() {
    history.back();
  }

  void forward() {
    history.forward();
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    switch (type) {
      case RouteInformationReportingType.navigate:
        push(routeInformation.uri, state: routeInformation.state);
      case RouteInformationReportingType.neglect:
        replace(routeInformation.uri, state: routeInformation.state);
      case RouteInformationReportingType.none:
        value = routeInformation;
    }
  }

  void _syncFromHistory() {
    final location = history.location;
    _update(location.uri, location.state);
  }

  void _update(Uri uri, Object? state) {
    value = RouteInformation(uri: uri, state: state);
    notifyListeners();
  }

  @override
  void dispose() {
    _unlisten();
    history.dispose();
    super.dispose();
  }
}
