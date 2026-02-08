import 'dart:async';

import 'package:unstory/unstory.dart';

import '../core/route_data.dart';
import '../core/route_records.dart';
import 'state.dart';
import 'unrouter.dart';

/// Typed view over a core controller runtime.
///
/// This keeps one underlying runtime while allowing adapters to project the
/// controller as different route types.
final class UnrouterControllerCastView<R extends RouteData>
    implements UnrouterController<R> {
  const UnrouterControllerCastView(this._source);

  final UnrouterController _source;

  @override
  History get history => _source.history;

  @override
  R? get route => _source.route as R?;

  @override
  Uri get uri => _source.uri;

  @override
  bool get canGoBack => _source.canGoBack;

  @override
  HistoryAction get lastAction => _source.lastAction;

  @override
  int? get lastDelta => _source.lastDelta;

  @override
  int? get historyIndex => _source.historyIndex;

  @override
  Object? get historyState => _source.historyState;

  @override
  StateSnapshot<R> get state {
    return (_source.state as StateSnapshot<dynamic>).cast<R>();
  }

  @override
  RouteResolution<R> get resolution {
    return _castResolution<R>(_source.resolution as RouteResolution<dynamic>);
  }

  @override
  Stream<StateSnapshot<R>> get states {
    final stream = _source.states.cast<StateSnapshot<dynamic>>();
    return stream.map((snapshot) => snapshot.cast<R>());
  }

  @override
  Future<void> get idle => _source.idle;

  @override
  String href(R route) {
    return _source.href(route);
  }

  @override
  String hrefUri(Uri uri) {
    return _source.hrefUri(uri);
  }

  @override
  void go(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _source.go(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  @override
  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _source.goUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  @override
  void replace(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _source.replace(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  @override
  void replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _source.replaceUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  @override
  Future<T?> push<T extends Object?>(R route, {Object? state}) {
    return _source.push<T>(route, state: state);
  }

  @override
  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    return _source.pushUri<T>(uri, state: state);
  }

  @override
  bool pop<T extends Object?>([T? result]) {
    return _source.pop(result);
  }

  @override
  void popToUri(Uri uri, {Object? state, Object? result}) {
    _source.popToUri(uri, state: state, result: result);
  }

  @override
  bool back() {
    return _source.back();
  }

  @override
  void forward() {
    _source.forward();
  }

  @override
  void goDelta(int delta) {
    _source.goDelta(delta);
  }

  @override
  void setHistoryStateComposer(UnrouterHistoryStateComposer? composer) {
    _source.setHistoryStateComposer(composer);
  }

  @override
  void clearHistoryStateComposer() {
    _source.clearHistoryStateComposer();
  }

  @override
  void setShellBranchResolvers({
    required Uri? Function(int index, {required bool initialLocation})
    resolveTarget,
    required Uri? Function() popTarget,
  }) {
    _source.setShellBranchResolvers(
      resolveTarget: resolveTarget,
      popTarget: popTarget,
    );
  }

  @override
  void clearShellBranchResolvers() {
    _source.clearShellBranchResolvers();
  }

  @override
  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _source.switchBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  @override
  bool popBranch([Object? result]) {
    return _source.popBranch(result);
  }

  @override
  UnrouterController<S> cast<S extends RouteData>() {
    if (_source is UnrouterController<S>) {
      return _source;
    }
    return UnrouterControllerCastView<S>(_source);
  }

  @override
  Future<void> dispatchRouteRequest(Uri uri, {Object? state}) {
    return _source.dispatchRouteRequest(uri, state: state);
  }

  @override
  void publishState() {
    _source.publishState();
  }

  @override
  void dispose() {
    _source.dispose();
  }
}

RouteResolution<S> _castResolution<S extends RouteData>(
  RouteResolution<dynamic> raw,
) {
  switch (raw.type) {
    case RouteResolutionType.pending:
      return RouteResolution<S>.pending(raw.uri);
    case RouteResolutionType.unmatched:
      return RouteResolution<S>.unmatched(raw.uri);
    case RouteResolutionType.blocked:
      return RouteResolution<S>.blocked(raw.uri);
    case RouteResolutionType.redirect:
      final redirectUri = raw.redirectUri;
      if (redirectUri == null) {
        return RouteResolution<S>.error(
          uri: raw.uri,
          error: StateError('Redirect resolution is missing target uri.'),
          stackTrace: StackTrace.current,
        );
      }
      return RouteResolution<S>.redirect(
        uri: raw.uri,
        redirectUri: redirectUri,
      );
    case RouteResolutionType.error:
      return RouteResolution<S>.error(
        uri: raw.uri,
        error: raw.error ?? StateError('Unknown route resolution error.'),
        stackTrace: raw.stackTrace ?? StackTrace.current,
      );
    case RouteResolutionType.matched:
      final record = raw.record;
      final route = raw.route;
      if (record == null || route == null) {
        return RouteResolution<S>.error(
          uri: raw.uri,
          error: StateError('Matched resolution is missing route metadata.'),
          stackTrace: StackTrace.current,
        );
      }
      return RouteResolution<S>.matched(
        uri: raw.uri,
        record: record as RouteRecord<S>,
        route: route as S,
        loaderData: raw.loaderData,
      );
  }
}
