import 'package:flutter/foundation.dart' show Key;

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
  final Key key;
  final Object? state;

  const Location({
    super.pathname,
    super.search,
    super.hash,
    required this.key,
    this.state,
  });
}

enum HistoryAction { pop, push, replace }

class HistoryState {
  final Object? userData;
  final int index;
  final Key? key;

  const HistoryState({required this.index, this.key, this.userData});
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
