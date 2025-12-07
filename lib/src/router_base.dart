import 'package:flutter/widgets.dart' show RouteInformationParser, RouterDelegate;
import 'location.dart';

/// Public router surface.
abstract interface class Router {
  void back();
  void forward();
  void go(int delta);
  void push(RouteLocation location);
  void replace(RouteLocation location);

  RouterDelegate<Uri> get delegate;
  RouteInformationParser<Uri> get informationParser;
}
