import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart'
    as core
    show
        RouteRecord,
        RouteResolution,
        RouteResolutionType,
        UnrouterController,
        UnrouterStateSnapshot;
import 'package:unstory/unstory.dart';

import '../core/route_data.dart';

/// Runtime controller backed by core `unrouter` controller.
///
/// This wrapper provides adapter-level typing and `cast()` while delegating all
/// runtime behavior to core.
class UnrouterController<R extends RouteData> {
  UnrouterController._(this._coreController);

  factory UnrouterController.fromCore(
    core.UnrouterController<dynamic> coreController,
  ) {
    return UnrouterController<R>._(coreController);
  }

  final core.UnrouterController<dynamic> _coreController;

  R? get route {
    final value = _coreController.route;
    if (value == null) {
      return null;
    }
    return value as R;
  }

  Uri get uri => _coreController.uri;

  bool get canGoBack => _coreController.canGoBack;

  HistoryAction get lastAction => _coreController.lastAction;

  int? get lastDelta => _coreController.lastDelta;

  int? get historyIndex => _coreController.historyIndex;

  Object? get historyState => _coreController.historyState;

  core.RouteResolution<R> get resolution {
    return _castResolution<R>(_coreController.resolution);
  }

  core.UnrouterStateSnapshot<R> get state => _coreController.state.cast<R>();

  Stream<core.UnrouterStateSnapshot<R>> get states {
    return _coreController.states.map((snapshot) => snapshot.cast<R>());
  }

  Future<void> get idle => _coreController.idle;

  String href(R route) {
    return _coreController.href(route);
  }

  String hrefUri(Uri uri) {
    return _coreController.hrefUri(uri);
  }

  void go(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _coreController.go(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _coreController.goUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  void replace(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _coreController.replace(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  void replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _coreController.replaceUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  Future<T?> push<T extends Object?>(R route, {Object? state}) {
    return _coreController.push<T>(route, state: state);
  }

  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    return _coreController.pushUri<T>(uri, state: state);
  }

  bool pop<T extends Object?>([T? result]) {
    return _coreController.pop(result);
  }

  void popToUri(Uri uri, {Object? state, Object? result}) {
    _coreController.popToUri(uri, state: state, result: result);
  }

  bool back() {
    return _coreController.back();
  }

  void forward() {
    _coreController.forward();
  }

  void goDelta(int delta) {
    _coreController.goDelta(delta);
  }

  UnrouterController<S> cast<S extends RouteData>() {
    return UnrouterController<S>._(_coreController);
  }

  Future<void> dispatchRouteRequest(Uri uri, {Object? state}) {
    return _coreController.dispatchRouteRequest(uri, state: state);
  }

  void publishState() {
    _coreController.publishState();
  }

  void dispose() {
    _coreController.dispose();
  }
}

class UnrouterScope extends InheritedComponent {
  const UnrouterScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final UnrouterController<RouteData> controller;

  static UnrouterController<RouteData> of(BuildContext context) {
    final scope = context
        .dependOnInheritedComponentOfExactType<UnrouterScope>();
    if (scope != null) {
      return scope.controller;
    }

    throw StateError(
      'UnrouterScope was not found in context. '
      'No UnrouterRouter is available above this BuildContext.',
    );
  }

  static UnrouterController<R> ofAs<R extends RouteData>(BuildContext context) {
    return of(context).cast<R>();
  }

  @override
  bool updateShouldNotify(UnrouterScope oldComponent) {
    return controller != oldComponent.controller;
  }
}

/// `BuildContext` helpers for Jaspr router access.
extension UnrouterBuildContextExtension on BuildContext {
  /// Returns an untyped router controller.
  UnrouterController<RouteData> get unrouter => UnrouterScope.of(this);

  /// Returns a typed router controller.
  UnrouterController<R> unrouterAs<R extends RouteData>() {
    return UnrouterScope.ofAs<R>(this);
  }
}

core.RouteResolution<S> _castResolution<S extends RouteData>(
  core.RouteResolution<dynamic> raw,
) {
  switch (raw.type) {
    case core.RouteResolutionType.pending:
      return core.RouteResolution<S>.pending(raw.uri);
    case core.RouteResolutionType.unmatched:
      return core.RouteResolution<S>.unmatched(raw.uri);
    case core.RouteResolutionType.redirect:
      return core.RouteResolution<S>.redirect(
        uri: raw.uri,
        redirectUri: raw.redirectUri!,
      );
    case core.RouteResolutionType.blocked:
      return core.RouteResolution<S>.blocked(raw.uri);
    case core.RouteResolutionType.error:
      return core.RouteResolution<S>.error(
        uri: raw.uri,
        error: raw.error!,
        stackTrace: raw.stackTrace ?? StackTrace.current,
      );
    case core.RouteResolutionType.matched:
      final record = raw.record;
      final route = raw.route;
      if (record == null || route == null) {
        throw StateError(
          'Matched resolution must contain route record and route.',
        );
      }

      return core.RouteResolution<S>.matched(
        uri: raw.uri,
        record: record as core.RouteRecord<S>,
        route: route as S,
        loaderData: raw.loaderData,
      );
  }
}
