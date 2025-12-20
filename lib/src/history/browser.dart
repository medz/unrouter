import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '_utils.dart';
import 'history.dart';

/// Internal state stored in a browser history entry.
///
/// This is used to keep extra metadata (like an index) alongside the
/// user-provided entry state.
class _HistoryState {
  /// The user-provided state passed to [History.push] / [History.replace].
  final Object? userData;

  /// The current position in the history stack, as tracked by `unrouter`.
  final int index;

  /// An internal identifier for the entry.
  final String? identifier;

  const _HistoryState({required this.index, this.identifier, this.userData});

  /// Converts this object into a plain `Map` suitable for serialization.
  Map<String, dynamic> toJson() => {
    'index': index,
    'identifier': identifier,
    'userData': userData,
  };

  /// Creates an instance from a JSON-like `Map`.
  factory _HistoryState.fromJson(Map<dynamic, dynamic> json) => _HistoryState(
    index: json['index'] as int? ?? 0,
    identifier: json['identifier'] as String?,
    userData: json['userData'],
  );
}

/// Base class for web [History] implementations backed by `window.history`.
///
/// This class wires up the browser `popstate` event and implements:
/// - [push] / [replace] (synchronous, do not emit events)
/// - [go] / [back] / [forward] (emit events asynchronously via `popstate`)
///
/// Subclasses are responsible for:
/// - Exposing the current [location] by reading from `window.location`
/// - Converting a target [Uri] into an `href` string via [createHref]
///
/// `unrouter` stores additional metadata in `window.history.state` so it can
/// compute a [HistoryEvent.delta] when navigating back/forward.
abstract class UrlBasedHistory extends History {
  UrlBasedHistory({web.Window? window}) {
    this.window = window ?? web.document.defaultView ?? web.window;
    index = state?.index ?? 0;
    if (index == 0) {
      final state = _HistoryState(
        identifier: this.state?.identifier ?? generateIdentifier(),
        userData: this.state?.userData,
        index: index,
      );
      this.window.history.replaceState(state.toJson().jsify(), '');
    }

    this.window.addEventListener('popstate', didPopJsFunction);
  }

  late final web.Window window;

  @override
  late int index;

  final listeners = <void Function(HistoryEvent event)>[];
  late final JSFunction didPopJsFunction = didPop.toJS;

  @override
  HistoryAction action = .pop;

  @override
  void push(Uri uri, [Object? state]) {
    action = .push;
    index = (this.state?.index ?? 0) + 1;
    final historyState = _HistoryState(
      userData: state,
      index: index,
      identifier: generateIdentifier(),
    );

    window.history.pushState(
      historyState.toJson().jsify(),
      '',
      createHref(uri),
    );
  }

  @override
  void replace(Uri uri, [Object? state]) {
    action = .replace;
    index = this.state?.index ?? 0;
    final historyState = _HistoryState(
      identifier: this.state?.identifier ?? generateIdentifier(),
      index: index,
      userData: state,
    );

    window.history.replaceState(
      historyState.toJson().jsify(),
      '',
      createHref(uri),
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

/// A web [History] that uses path-based URLs (e.g. `/about`).
///
/// The current location is read from `window.location` using:
/// - `pathname` as [Uri.path]
/// - `search` as [Uri.query]
/// - `hash` as [Uri.fragment]
class BrowserHistory extends UrlBasedHistory {
  /// Creates a [BrowserHistory] that reads/writes path-based URLs.
  ///
  /// If [window] is omitted, the default browser window is used.
  BrowserHistory({super.window});

  @override
  RouteInformation get location {
    final web.Location(:pathname, :search, :hash) = window.location;
    final uri = Uri(
      path: pathname.startsWith('/') ? pathname : '/$pathname',
      query: search.startsWith('?') ? search.substring(1) : search,
      fragment: hash.startsWith('#') ? hash.substring(1) : hash,
    );
    return RouteInformation(uri: uri, state: state?.userData);
  }

  @override
  String createHref(Uri uri) => uri.toString();
}

/// A web [History] that stores the route inside the URL fragment (e.g. `/#/about`).
///
/// This strategy commonly works on static hosts without server-side rewrite
/// rules, because the browser will only request `/` from the server.
class HashHistory extends UrlBasedHistory {
  /// Creates a [HashHistory] that stores the route in `location.hash`.
  ///
  /// If [window] is omitted, the default browser window is used.
  HashHistory({super.window});

  @override
  RouteInformation get location {
    final web.Location(:hash) = window.location;
    final path = hash.startsWith('#') ? hash.substring(1) : hash;
    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    return RouteInformation(uri: uri, state: state?.userData);
  }

  @override
  String createHref(Uri uri) {
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
    buffer.write('#${uri.path}');
    if (uri.hasQuery) {
      buffer.write('?${uri.query}');
    }
    if (uri.hasFragment) {
      buffer.write('#${uri.fragment}');
    }

    return buffer.toString();
  }
}

extension on UrlBasedHistory {
  _HistoryState? get state {
    final dartified = window.history.state.dartify();
    if (dartified is Map) {
      return _HistoryState.fromJson(dartified);
    }
    return null;
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
