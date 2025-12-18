import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '_utils.dart';
import 'history.dart';

abstract class UrlBasedHistory extends History {
  UrlBasedHistory({web.Window? window}) {
    this.window = window ?? web.document.defaultView ?? web.window;
    index = state?.index ?? 0;
    if (index == 0) {
      final state = HistoryState(
        identifier: this.state?.identifier ?? generateIdentifier(),
        userData: this.state?.userData,
        index: index,
      );
      this.window.history.replaceState(state.toJson().jsify(), '');
    }

    this.window.addEventListener('popstate', didPopJsFunction);
  }

  late final web.Window window;
  late int index;

  final listeners = <void Function(HistoryEvent event)>[];
  late final JSFunction didPopJsFunction = didPop.toJS;

  @override
  HistoryAction action = .pop;

  @override
  void push(Path to, [Object? state]) {
    action = .push;
    index = (this.state?.index ?? 0) + 1;
    final location = createLocation(to, state: state);
    final historyState = HistoryState(
      userData: state,
      index: index,
      identifier: location.identifier,
    );

    window.history.pushState(
      historyState.toJson().jsify(),
      '',
      createHref(location),
    );
  }

  @override
  void replace(Path to, [Object? state]) {
    action = .replace;
    index = this.state?.index ?? 0;
    final location = createLocation(to, state: state);
    final historyState = HistoryState(
      identifier: location.identifier,
      index: index,
      userData: state,
    );

    window.history.replaceState(
      historyState.toJson().jsify(),
      '',
      createHref(location),
    );
  }

  @override
  void go(int delta) => window.history.go(delta);

  @override
  void Function() listen(void Function(HistoryEvent event) listener) {
    listeners.add(listener);
    return () {
      listeners.removeWhere((e) => e == listener);
    };
  }

  @override
  void dispose() {
    window.removeEventListener('popstate', didPopJsFunction);
    listeners.clear();
  }
}

class BrowserHistory extends UrlBasedHistory {
  @override
  Location get location {
    final web.Location(:pathname, :search, :hash) = window.location;
    final url = Uri(
      path: pathname.startsWith('/') ? pathname : '/$pathname',
      query: search.startsWith('?') ? search.substring(1) : search,
      fragment: hash.startsWith('#') ? hash.substring(1) : hash,
    );
    return createLocation(
      Path(pathname: url.path, search: url.query, hash: url.fragment),
      state: state?.userData,
      identifier: state?.identifier ?? 'default',
    );
  }

  @override
  String createHref(Path to) => to.toUri().toString();
}

class HashHistory extends UrlBasedHistory {
  @override
  Location get location {
    final web.Location(:hash) = window.location;
    final path = hash.startsWith('#') ? hash.substring(1) : hash;
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    return createLocation(
      Path(pathname: uri.path, search: uri.query, hash: uri.fragment),
      state: state?.userData,
      identifier: state?.identifier ?? 'default',
    );
  }

  @override
  String createHref(Path to) {
    // For HashHistory, the entire path (pathname + search + hash) goes in the fragment
    // Manually construct the URL to avoid encoding issues with nested #
    final buffer = StringBuffer();

    // Add base URL if there's a <base> tag
    final base = window.document.querySelector('base');
    if (base != null && base.getAttribute('href') != null) {
      final baseUri = Uri.parse(window.location.href).removeFragment();
      buffer.write(baseUri.toString());
    }

    // Add fragment with full path
    buffer.write('#${to.pathname}');
    if (to.search.isNotEmpty) {
      buffer.write('?${to.search}');
    }
    if (to.hash.isNotEmpty) {
      buffer.write('#${to.hash}');
    }

    return buffer.toString();
  }
}

extension on Path {
  Uri toUri() => Uri(path: pathname, query: search, fragment: hash);
}

extension on UrlBasedHistory {
  HistoryState? get state {
    final dartified = window.history.state.dartify();
    if (dartified is Map) {
      return HistoryState.fromJson(dartified);
    }
    return null;
  }

  Location createLocation(Path to, {Object? state, String? identifier}) {
    return Location(
      identifier: switch (to) {
        Location() => to.identifier,
        _ => identifier ?? generateIdentifier(),
      },
      pathname: to.pathname,
      search: to.search,
      hash: to.hash,
      state: state,
    );
  }

  void didPop(web.PopStateEvent _) {
    action = .pop;
    final nextIndex = state?.index;
    final delta = nextIndex == null ? null : nextIndex - index;
    index = nextIndex ?? 0;
    final event = HistoryEvent(
      action: action,
      location: location,
      delta: delta,
    );

    for (final e in listeners) {
      e(event);
    }
  }
}
