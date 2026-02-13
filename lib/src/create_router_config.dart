import 'package:flutter/widgets.dart' hide Router;
import 'package:unstory/unstory.dart';

import 'router.dart';

RouterConfig<HistoryLocation> createRouterConfig(Router router) {
  return RouterConfig(routerDelegate: _RouterDelegate(router));
}

class _RouterDelegate extends RouterDelegate<HistoryLocation> {
  _RouterDelegate(this.router);

  final Router router;
  final cleanups = <VoidCallback, VoidCallback>{};

  @override
  HistoryLocation get currentConfiguration => router.history.location;

  @override
  void addListener(VoidCallback listener) {
    if (cleanups.containsKey(listener)) {
      throw StateError('Listener already added');
    }
    cleanups[listener] = router.history.listen((_) => listener());
  }

  @override
  void removeListener(VoidCallback listener) {
    cleanups[listener]?.call();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  Future<bool> popRoute() {
    // TODO: implement popRoute
    throw UnimplementedError();
  }

  @override
  Future<void> setNewRoutePath(HistoryLocation configuration) {
    // TODO: implement setNewRoutePath
    throw UnimplementedError();
  }
}
