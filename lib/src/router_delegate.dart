import 'package:flutter/widgets.dart';

import 'history/types.dart';
import 'routes.dart';
import 'router_state.dart';

/// The router delegate that manages navigation state and builds the widget tree.
class UnrouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  UnrouterDelegate({required this.routes});

  /// The root routes configuration.
  final Routes routes;

  /// The underlying history implementation.
  RouterHistory? _history;

  /// Current route information.
  RouteInformation _currentConfiguration = RouteInformation(
    uri: Uri.parse('/'),
  );

  /// Unlisten callback from history.
  VoidCallback? _unlistenHistory;

  /// Attaches the history implementation.
  void attachHistory(RouterHistory history) {
    _history = history;

    // Listen to history changes
    _unlistenHistory = history.listen((to, from, info) {
      _currentConfiguration = RouteInformation(
        uri: Uri.parse(to),
        state: history.state,
      );
      notifyListeners();
    });

    // Initialize with current location
    _currentConfiguration = RouteInformation(
      uri: Uri.parse(history.location),
      state: history.state,
    );
  }

  @override
  RouteInformation? get currentConfiguration => _currentConfiguration;

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {
    _currentConfiguration = configuration;

    // Update history if needed
    final location = configuration.uri.path;
    if (_history != null && _history!.location != location) {
      _history!.push(location, configuration.state);
    }

    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    // Create router state and provide it to the widget tree
    return RouterStateProvider(
      state: RouterState(
        location: _currentConfiguration.uri.path,
        params: {},
        remainingPath: _currentConfiguration.uri.path.split('/')
          ..removeWhere((s) => s.isEmpty),
      ),
      child: routes,
    );
  }

  @override
  Future<bool> popRoute() async {
    // Handle back button press
    if (_history != null) {
      _history!.back();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _unlistenHistory?.call();
    super.dispose();
  }
}
