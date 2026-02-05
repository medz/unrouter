import 'package:flutter/widgets.dart';
import 'package:roux/roux.dart';
import 'package:unstory/unstory.dart';

class UnrouterDelegate extends RouterDelegate<HistoryLocation>
    with ChangeNotifier {
  UnrouterDelegate(this.config);

  final RouterConfig config;
  final context = createRouter();

  @override
  Widget build(BuildContext context) {
    Navigator();
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
