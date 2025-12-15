import 'package:flutter/foundation.dart' show VoidCallback;
export 'package:flutter/foundation.dart' show VoidCallback;

enum NavigationType { pop, push }

enum NavigationDirection { forward, back, unknown }

class NavigationInformation {
  const NavigationInformation({
    required this.type,
    required this.direction,
    required this.delta,
  });

  final NavigationType type;
  final NavigationDirection direction;
  final int delta;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationInformation &&
        other.type == type &&
        other.direction == direction &&
        other.delta == delta;
  }

  @override
  int get hashCode => Object.hash(type, direction, delta);
}

typedef NavigationCallback =
    void Function(String to, String from, NavigationInformation info);

abstract interface class RouterHistory {
  String get base;
  String get location;
  Object? get state;

  void push(String to, [Object? state]);
  void replace(String to, [Object? state]);
  void go(int delta);
  void back();
  void forward();
  VoidCallback listen(NavigationCallback callback);
  String createHref(String location);
  void destroy();
}
