import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roux/roux.dart' as roux;
import 'package:unstory/unstory.dart';

import 'guard.dart';
import 'inlet.dart';
import 'route_record.dart';
import 'route_params.dart';
import 'url_search_params.dart';
import 'utils.dart';

/// Public router contract used by Unrouter integrations.
abstract interface class Unrouter {
  /// Underlying history implementation.
  History get history;

  /// Name-to-path matcher used for named navigation.
  roux.Router<String> get aliases;

  /// Path-to-record matcher used for route resolution.
  roux.Router<RouteRecord> get matcher;

  /// Navigates by relative history delta.
  void go(int delta);

  /// Navigates one entry forward in history.
  void forward();

  /// Navigates one entry backward in history.
  void back();

  /// Pushes a new location resolved from [pathOrName].
  ///
  /// Resolution order is:
  /// 1. Route name alias
  /// 2. Absolute path
  ///
  /// When both inline query and [query] are provided, [query] overrides keys
  /// with the same name.
  Future<void> push<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  });

  /// Replaces the current location with [pathOrName].
  ///
  /// Uses the same resolution and query-merge rules as [push].
  Future<void> replace<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  });

  /// Pops one history entry.
  ///
  /// Returns `false` when no previous entry exists.
  Future<bool> pop<T>([T? result]);
}

/// Creates a router instance with route matching, navigation, and guards.
///
/// [routes] defines the route tree.
/// [guards] are global guards executed before route-level guards.
/// [base] configures the history base path.
/// [maxRedirectDepth] limits chained guard redirects.
/// [history] can override the default history implementation.
/// [strategy] selects browser/history strategy when [history] is omitted.
///
/// Throws an [ArgumentError] when [maxRedirectDepth] is less than `1`.
Unrouter createRouter({
  required Iterable<Inlet> routes,
  Iterable<Guard>? guards,
  String base = '/',
  int maxRedirectDepth = 8,
  History? history,
  HistoryStrategy strategy = HistoryStrategy.browser,
}) {
  if (maxRedirectDepth < 1) {
    throw ArgumentError.value(
      maxRedirectDepth,
      'maxRedirectDepth',
      'maxRedirectDepth must be greater than 0.',
    );
  }
  history ??= createHistory(base: normalizePath([base]), strategy: strategy);
  final router = _RouterImpl(
    history: history,
    aliases: roux.Router<String>(),
    matcher: roux.Router<RouteRecord>(),
    maxRedirectDepth: maxRedirectDepth,
  );
  for (final route in routes) {
    router.aliases.addAll(route.makeAliasRoutes());
    router.matcher.addAll(route.makeRouteRecords(guards));
  }

  return router;
}

extension on Inlet {
  Map<String, String> makeAliasRoutes() {
    final routes = <String, String>{};
    void collect(Inlet route, String parentPath) {
      final fullPath = normalizePath([parentPath, route.path]);
      final name = route.name;
      if (name case final alias? when alias.isNotEmpty) {
        final key = normalizePath([alias]);
        final previous = routes[key];
        if (previous != null && previous != fullPath) {
          throw StateError('Duplicate route alias "$alias".');
        }
        routes[key] = fullPath;
      }

      for (final child in route.children) {
        collect(child, fullPath);
      }
    }

    collect(this, '/');
    return routes;
  }

  Map<String, RouteRecord> makeRouteRecords([Iterable<Guard>? global]) {
    final routes = <String, RouteRecord>{};

    void collect(
      Inlet route,
      String parent,
      Iterable<ViewBuilder>? parentViews,
      Iterable<Guard>? parentGuards,
      Map<String, Object?>? parentMeta,
    ) {
      final path = normalizePath([parent, route.path]);
      final views = <ViewBuilder>[...?parentViews, route.view];
      final guards = <Guard>[...?parentGuards, ...route.guards];

      final previous = routes[path];
      if (previous != null) {
        final viewRelation = _relation(previous.views, views);
        if (viewRelation == _SequenceRelation.incompatible) {
          throw StateError('Duplicate route views "$path".');
        }

        final guardRelation = _relation(previous.guards, guards);
        if (guardRelation == _SequenceRelation.incompatible ||
            (viewRelation == _SequenceRelation.same &&
                guardRelation == _SequenceRelation.strictPrefix)) {
          throw StateError('Duplicate route guards "$path".');
        }
      }

      final meta = Map<String, Object?>.unmodifiable({
        ...?parentMeta,
        ...?route.meta,
      });
      routes[path] = RouteRecord(views: views, guards: guards, meta: meta);

      for (final child in route.children) {
        collect(child, path, views, guards, meta);
      }
    }

    collect(this, '/', null, global, null);
    return routes;
  }

  _SequenceRelation _relation<T>(Iterable<T> previous, Iterable<T> next) {
    if (next.length < previous.length) {
      return _SequenceRelation.incompatible;
    }

    for (var i = 0; i < previous.length; i++) {
      if (previous.elementAtOrNull(i) != next.elementAtOrNull(i)) {
        return _SequenceRelation.incompatible;
      }
    }

    if (next.length == previous.length) {
      return _SequenceRelation.same;
    }
    return _SequenceRelation.strictPrefix;
  }
}

enum _SequenceRelation { same, strictPrefix, incompatible }

class _RouterImpl extends ChangeNotifier implements Unrouter {
  _RouterImpl({
    required this.history,
    required this.aliases,
    required this.matcher,
    required this.maxRedirectDepth,
  }) : _lastAllowedLocation = history.location {
    _removeHistoryListener = history.listen(_enqueueHistoryEvent);
  }

  @override
  final History history;

  @override
  final roux.Router<String> aliases;

  @override
  final roux.Router<RouteRecord> matcher;

  final int maxRedirectDepth;

  late final void Function() _removeHistoryListener;
  HistoryLocation _lastAllowedLocation;
  Future<void> _historyQueue = Future<void>.value();
  bool _disposed = false;

  @override
  void back() => history.back();

  @override
  void forward() => history.forward();

  @override
  void go(int delta) => history.go(delta, triggerListeners: true);

  @override
  Future<bool> pop<T>([T? result]) {
    final index = history.index;
    if (index != null && index <= 0) {
      return Future.value(false);
    }

    history.back();
    return Future.value(true);
  }

  @override
  Future<void> push<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  }) {
    return _navigate(
      action: HistoryAction.push,
      pathOrName: pathOrName,
      params: params,
      query: query,
      state: state,
    );
  }

  @override
  Future<void> replace<T>(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    T? state,
  }) {
    return _navigate(
      action: HistoryAction.replace,
      pathOrName: pathOrName,
      params: params,
      query: query,
      state: state,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _removeHistoryListener();
    super.dispose();
  }

  Future<void> _navigate({
    required HistoryAction action,
    required String pathOrName,
    Map<String, String>? params,
    URLSearchParams? query,
    Object? state,
  }) async {
    final from = history.location;
    final target = _resolveNavigationTarget(
      pathOrName,
      params: params,
      query: query,
      state: state,
    );
    final result = await _runGuards(action: action, from: from, target: target);
    if (result.blocked) return;

    final next = result.target!;
    if (result.redirected) {
      history.replace(next.uri, state: next.state);
      _reportLocationChange(from);
      return;
    }

    switch (action) {
      case HistoryAction.push:
        history.push(next.uri, state: next.state);
      case HistoryAction.replace:
        history.replace(next.uri, state: next.state);
      case HistoryAction.pop:
        throw StateError(
          'Invalid navigation action "pop" for push/replace flow.',
        );
    }
    _reportLocationChange(from);
  }

  _NavigationTarget _resolveNavigationTarget(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    Object? state,
  }) {
    final input = pathOrName.trim();
    if (input.isEmpty) {
      throw ArgumentError.value(
        pathOrName,
        'pathOrName',
        'Path or route name must not be empty.',
      );
    }

    final parsed = Uri.parse(input);
    final aliasKey = normalizePath([parsed.path]);
    final alias = aliases.match(aliasKey);
    if (alias != null) {
      final resolvedPath = _fillRoutePattern(alias.data, params ?? const {});
      return _resolveByPath(
        path: resolvedPath,
        baseQuery: parsed.query,
        query: query,
        fragment: parsed.fragment,
        state: state,
      );
    }

    if (!parsed.path.startsWith('/')) {
      throw StateError('Route name "$pathOrName" was not found.');
    }
    if (params case final values? when values.isNotEmpty) {
      throw ArgumentError.value(
        params,
        'params',
        'Path navigation does not accept params.',
      );
    }

    return _resolveByPath(
      path: normalizePath([parsed.path]),
      baseQuery: parsed.query,
      query: query,
      fragment: parsed.fragment,
      state: state,
    );
  }

  _NavigationTarget _resolveByPath({
    required String path,
    required String baseQuery,
    required URLSearchParams? query,
    required String fragment,
    required Object? state,
  }) {
    final mergedQuery = _mergeQueries(baseQuery, query);
    final uri = Uri(
      path: path,
      query: mergedQuery.isEmpty ? null : mergedQuery,
      fragment: fragment.isEmpty ? null : fragment,
    );
    final match = matcher.match(uri.path);
    if (match == null) {
      throw StateError('No route matched path "${uri.path}".');
    }

    return _NavigationTarget(
      uri: uri,
      state: state,
      record: match.data,
      params: RouteParams(match.params ?? const <String, String>{}),
      query: URLSearchParams(mergedQuery),
    );
  }

  String _mergeQueries(String baseQuery, URLSearchParams? override) {
    final merged = URLSearchParams(baseQuery);
    if (override == null) return merged.toString();

    final grouped = <String, List<String>>{};
    for (final entry in override) {
      (grouped[entry.key] ??= <String>[]).add(entry.value);
    }

    for (final entry in grouped.entries) {
      merged.delete(entry.key);
      for (final value in entry.value) {
        merged.append(entry.key, value);
      }
    }
    return merged.toString();
  }

  String _fillRoutePattern(String pattern, Map<String, String> params) {
    if (pattern == '/') {
      if (params.isNotEmpty) {
        throw ArgumentError.value(
          params,
          'params',
          'Route "/" does not accept params.',
        );
      }
      return '/';
    }

    final consumed = <String>{};
    final segments = <String>[];

    for (final segment in pattern.split('/')) {
      if (segment.isEmpty) continue;

      if (segment.startsWith(':')) {
        final name = segment.substring(1);
        if (name.isEmpty) {
          throw StateError('Invalid route pattern "$pattern".');
        }

        final value = params[name];
        if (value == null || value.isEmpty) {
          throw ArgumentError.value(
            params,
            'params',
            'Missing required param "$name".',
          );
        }
        if (value.contains('/')) {
          throw ArgumentError.value(
            params,
            'params',
            'Param "$name" must not contain "/".',
          );
        }

        consumed.add(name);
        segments.add(Uri.encodeComponent(value));
        continue;
      }

      if (segment == '*') {
        final wildcard = params['wildcard'];
        if (wildcard == null) {
          throw ArgumentError.value(
            params,
            'params',
            'Missing required param "wildcard".',
          );
        }
        consumed.add('wildcard');
        for (final part in wildcard.split('/')) {
          if (part.isEmpty) continue;
          segments.add(Uri.encodeComponent(part));
        }
        continue;
      }

      segments.add(segment);
    }

    final extra = params.keys.where((key) => !consumed.contains(key));
    if (extra.isNotEmpty) {
      throw ArgumentError.value(
        params,
        'params',
        'Unexpected params: ${extra.join(', ')}.',
      );
    }

    return normalizePath(segments);
  }

  Future<_GuardEvaluation> _runGuards({
    required HistoryAction action,
    required HistoryLocation from,
    required _NavigationTarget target,
  }) async {
    var current = target;
    var redirects = 0;
    while (true) {
      if (redirects > maxRedirectDepth) {
        throw StateError(
          'Guard redirect loop exceeded max depth $maxRedirectDepth.',
        );
      }

      final record = current.record;
      final guards = record?.guards ?? const <Guard>[];
      if (guards.isEmpty) {
        return _GuardEvaluation.allowed(current, redirected: redirects > 0);
      }

      final context = GuardContext(
        from: from,
        to: HistoryLocation(current.uri, current.state),
        action: action,
        params: current.params,
        query: current.query,
        meta: record?.meta ?? const <String, Object?>{},
        state: current.state,
      );

      var redirected = false;
      for (final guard in guards) {
        final result = await guard(context);
        switch (result) {
          case GuardAllow():
            continue;
          case GuardBlock():
            return const _GuardEvaluation.blocked();
          case GuardRedirect(
            :final pathOrName,
            :final params,
            :final query,
            :final state,
          ):
            redirects += 1;
            current = _resolveNavigationTarget(
              pathOrName,
              params: params,
              query: query,
              state: state ?? current.state,
            );
            redirected = true;
        }
        if (redirected) break;
      }

      if (!redirected) {
        return _GuardEvaluation.allowed(current, redirected: redirects > 0);
      }
    }
  }

  void _enqueueHistoryEvent(HistoryEvent event) {
    if (_disposed || event.action != HistoryAction.pop) return;
    _historyQueue = _historyQueue
        .catchError((_, _) {})
        .then((_) => _processHistoryEvent(event))
        .catchError((Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              context: ErrorDescription('while processing history pop event'),
            ),
          );
        });
  }

  Future<void> _processHistoryEvent(HistoryEvent event) async {
    if (_disposed) return;

    final from = _lastAllowedLocation;
    final incoming = event.location;
    if (_isSameLocation(from, incoming)) {
      return;
    }

    final target = _targetFromHistory(incoming);
    if (target == null) {
      _reportLocationChange(from, next: incoming);
      return;
    }

    final result = await _runGuards(
      action: HistoryAction.pop,
      from: from,
      target: target,
    );
    if (result.blocked) {
      history.replace(from.uri, state: from.state);
      return;
    }

    final accepted = result.target!;
    if (result.redirected) {
      history.replace(accepted.uri, state: accepted.state);
      _reportLocationChange(from);
      return;
    }

    _reportLocationChange(from, next: incoming);
  }

  _NavigationTarget? _targetFromHistory(HistoryLocation location) {
    final match = matcher.match(location.path);
    if (match == null) {
      return null;
    }

    return _NavigationTarget(
      uri: location.uri,
      state: location.state,
      record: match.data,
      params: RouteParams(match.params ?? const <String, String>{}),
      query: URLSearchParams(location.query),
    );
  }

  void _reportLocationChange(
    HistoryLocation previous, {
    HistoryLocation? next,
  }) {
    final current = next ?? history.location;
    if (_isSameLocation(previous, current)) {
      return;
    }

    _lastAllowedLocation = current;
    notifyListeners();
  }

  bool _isSameLocation(HistoryLocation a, HistoryLocation b) {
    return a.uri == b.uri && a.state == b.state;
  }
}

final class _GuardEvaluation {
  const _GuardEvaluation.allowed(this.target, {required this.redirected})
    : blocked = false;

  const _GuardEvaluation.blocked()
    : blocked = true,
      redirected = false,
      target = null;

  final bool blocked;
  final bool redirected;
  final _NavigationTarget? target;
}

final class _NavigationTarget {
  const _NavigationTarget({
    required this.uri,
    required this.record,
    required this.params,
    required this.query,
    required this.state,
  });

  final Uri uri;
  final RouteRecord? record;
  final RouteParams params;
  final URLSearchParams query;
  final Object? state;
}
