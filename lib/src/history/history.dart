import 'package:flutter/widgets.dart';

enum HistoryAction { pop, push, replace }

/// Internal state stored in browser history.
/// Contains framework metadata (index, identifier) and user data.
class HistoryState {
  final Object? userData;
  final int index;
  final String? identifier;

  const HistoryState({required this.index, this.identifier, this.userData});

  /// Convert to a plain Map for serialization
  Map<String, dynamic> toJson() => {
        'index': index,
        'identifier': identifier,
        'userData': userData,
      };

  /// Create from a plain Map
  factory HistoryState.fromJson(Map<dynamic, dynamic> json) => HistoryState(
        index: json['index'] as int? ?? 0,
        identifier: json['identifier'] as String?,
        userData: json['userData'],
      );
}

class HistoryEvent {
  final HistoryAction action;
  final RouteInformation location;
  final int? delta;

  const HistoryEvent({
    required this.action,
    required this.location,
    this.delta,
  });
}

abstract class History {
  const History();

  HistoryAction get action;
  RouteInformation get location;

  String createHref(Uri uri);

  void push(Uri uri, [Object? state]);
  void replace(Uri uri, [Object? state]);

  void go(int delta);
  void back() => go(-1);
  void forward() => go(1);

  void Function() listen(void Function(HistoryEvent event) listener);
  void dispose();
}
