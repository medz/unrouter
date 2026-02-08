import 'dart:async';

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
  R? get route => _source.route as R?;

  @override
  Uri get uri => _source.uri;

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
  void go(R route, {Object? state}) {
    _source.go(route, state: state);
  }

  @override
  void goUri(Uri uri, {Object? state}) {
    _source.goUri(uri, state: state);
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
  bool back() {
    return _source.back();
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
  Future<void> sync(Uri uri, {Object? state}) {
    return _source.sync(uri, state: state);
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
