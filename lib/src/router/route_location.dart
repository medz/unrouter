import 'package:flutter/widgets.dart';

/// A [RouteInformation] with an optional matched route name.
///
/// `name` is populated when the current location matches a named [Inlet].
@immutable
class RouteLocation extends RouteInformation {
  const RouteLocation({required super.uri, super.state, this.name});

  /// The matched route name for this location, if any.
  final String? name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteLocation &&
        other.uri == uri &&
        other.state == state &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(uri, state, name);
}

/// Adds a `name` getter to [RouteInformation].
///
/// Returns `null` unless the instance is a [RouteLocation].
extension RouteInformationName on RouteInformation {
  String? get name =>
      this is RouteLocation ? (this as RouteLocation).name : null;
}
