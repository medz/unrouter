class Path {
  final String pathname;
  final String search;
  final String hash;

  const Path({this.pathname = '/', this.search = '', this.hash = ''});

  factory Path.parse(String href) {
    final uri = Uri.parse(href);
    return Path(pathname: uri.path, search: uri.query, hash: uri.fragment);
  }
}

class Location extends Path {
  final String identifier;
  final Object? state;

  const Location({
    super.pathname,
    super.search,
    super.hash,
    required this.identifier,
    this.state,
  });
}

enum HistoryAction { pop, push, replace }

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
  final Location location;
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
  Location get location;

  String createHref(Path to);

  void push(Path to, [Object? state]);
  void replace(Path to, [Object? state]);

  void go(int delta);
  void back() => go(-1);
  void forward() => go(1);

  void Function() listen(void Function(HistoryEvent event) listener);
  void dispose();
}
