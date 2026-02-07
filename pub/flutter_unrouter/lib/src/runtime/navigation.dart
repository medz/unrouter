import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    show UnrouterResolutionState, UnrouterStateSnapshot;
import 'package:unstory/unstory.dart';

import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';
import '../platform/route_information_provider.dart';

part 'navigation_runtime.dart';
part 'navigation_controller_lifecycle.dart';
part 'navigation_state.dart';

/// Input payload for [UnrouterHistoryStateComposer].
class UnrouterHistoryStateRequest {
  const UnrouterHistoryStateRequest({
    required this.uri,
    required this.action,
    required this.state,
    required this.currentState,
  });

  final Uri uri;
  final HistoryAction action;
  final Object? state;
  final Object? currentState;
}

/// Composes custom `history.state` payload before navigation writes.
typedef UnrouterHistoryStateComposer =
    Object? Function(UnrouterHistoryStateRequest request);

/// Runtime controller backing `BuildContext.unrouter`.
class UnrouterController<R extends RouteData> {
  UnrouterController({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required R? Function() routeGetter,
    required Uri Function() uriGetter,
    UnrouterStateSnapshot<RouteData> Function()? stateGetter,
  }) : this._(
         routeInformationProvider: routeInformationProvider,
         routeGetter: () => routeGetter(),
         uriGetter: uriGetter,
         stateGetter:
             stateGetter ??
             () => UnrouterStateSnapshot<RouteData>(
               uri: uriGetter(),
               route: routeGetter(),
               resolution: UnrouterResolutionState.unknown,
               routePath: null,
               routeName: null,
               error: null,
               stackTrace: null,
               lastAction: routeInformationProvider.lastAction,
               lastDelta: routeInformationProvider.lastDelta,
               historyIndex: routeInformationProvider.historyIndex,
             ),
         stateStore: _UnrouterStateStore(
           stateGetter:
               stateGetter ??
               () => UnrouterStateSnapshot<RouteData>(
                 uri: uriGetter(),
                 route: routeGetter(),
                 resolution: UnrouterResolutionState.unknown,
                 routePath: null,
                 routeName: null,
                 error: null,
                 stackTrace: null,
                 lastAction: routeInformationProvider.lastAction,
                 lastDelta: routeInformationProvider.lastDelta,
                 historyIndex: routeInformationProvider.historyIndex,
               ),
         ),
         navigationState: _UnrouterNavigationState(routeInformationProvider),
       );

  UnrouterController._({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required RouteData? Function() routeGetter,
    required Uri Function() uriGetter,
    required UnrouterStateSnapshot<RouteData> Function() stateGetter,
    required _UnrouterStateStore stateStore,
    required _UnrouterNavigationState navigationState,
    _UnrouterRouteRuntimeDriver? routeRuntime,
    Uri? Function(int index, {required bool initialLocation})?
    shellBranchTargetResolver,
    Uri? Function()? shellBranchPopResolver,
    _UnrouterNavigationRuntime? navigationRuntime,
  }) : _routeInformationProvider = routeInformationProvider,
       _routeGetter = routeGetter,
       _uriGetter = uriGetter,
       _stateGetter = stateGetter,
       _stateStore = stateStore,
       _navigationState = navigationState {
    if (shellBranchTargetResolver != null) {
      _shellBranchTargetResolver = shellBranchTargetResolver;
    }
    if (shellBranchPopResolver != null) {
      _shellBranchPopResolver = shellBranchPopResolver;
    }
    _routeRuntime = routeRuntime;
    _navigationRuntime =
        navigationRuntime ??
        _UnrouterNavigationRuntime(
          routeInformationProvider: _routeInformationProvider,
          navigationState: _navigationState,
          composeHistoryState: _composeHistoryStateForRuntime,
          resolveShellBranchTarget: _resolveShellBranchTarget,
          popShellBranchTarget: _popShellBranchTarget,
        );
  }

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final RouteData? Function() _routeGetter;
  final Uri Function() _uriGetter;
  final UnrouterStateSnapshot<RouteData> Function() _stateGetter;
  final _UnrouterStateStore _stateStore;
  final _UnrouterNavigationState _navigationState;
  late final _UnrouterNavigationRuntime _navigationRuntime;
  UnrouterHistoryStateComposer? _historyStateComposer;
  _UnrouterRouteRuntimeDriver? _routeRuntime;
  bool _isDisposed = false;
  Uri? Function(int index, {required bool initialLocation})
  _shellBranchTargetResolver = _defaultShellBranchTargetResolver;
  Uri? Function() _shellBranchPopResolver = _defaultShellBranchPopResolver;
  late final ValueListenable<UnrouterStateSnapshot<R>> _stateListenable =
      _UnrouterTypedStateListenable<R>(_stateStore.listenable);

  static Uri? _defaultShellBranchTargetResolver(
    int _, {
    required bool initialLocation,
  }) {
    return null;
  }

  static Uri? _defaultShellBranchPopResolver() {
    return null;
  }

  /// Current typed route object.
  R? get route {
    final value = _routeGetter();
    if (value == null) {
      return null;
    }
    return value as R;
  }

  /// Current location URI.
  Uri get uri => _uriGetter();

  /// Whether browser history can go back.
  bool get canGoBack => _routeInformationProvider.canGoBack;

  /// Last history action applied by route information provider.
  HistoryAction get lastAction => _routeInformationProvider.lastAction;

  /// Last history delta used for `go(delta)` style operations.
  int? get lastDelta => _routeInformationProvider.lastDelta;

  /// Current history index when available from provider.
  int? get historyIndex => _routeInformationProvider.historyIndex;

  /// Raw `history.state` payload of current location.
  Object? get historyState => _routeInformationProvider.value.state;

  UnrouterStateSnapshot<R> get state => _stateStore.current.cast<R>();

  ValueListenable<UnrouterStateSnapshot<R>> get stateListenable {
    return _stateListenable;
  }

  /// Generates href for a typed route.
  String href(R route) {
    return _routeInformationProvider.history.createHref(route.toUri());
  }

  /// Generates href for a URI.
  String hrefUri(Uri uri) {
    return _routeInformationProvider.history.createHref(uri);
  }

  /// Navigates to [route] using history push-like semantics.
  void go(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    goUri(
      route.toUri(),
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Navigates to [uri] using history push-like semantics.
  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _goUriViaRuntime(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Replaces current entry with [route].
  void replace(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    replaceUri(
      route.toUri(),
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Replaces current entry with [uri].
  void replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _replaceUriViaRuntime(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Pushes [route] and resolves typed result on pop.
  Future<T?> push<T extends Object?>(R route, {Object? state}) {
    return pushUri<T>(route.toUri(), state: state);
  }

  /// Pushes [uri] and resolves typed result on pop.
  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    return _pushUriViaRuntime<T>(uri, state: state);
  }

  /// Pops current entry and optionally completes pending push result.
  bool pop<T extends Object?>([T? result]) {
    return _popViaRuntime(result);
  }

  /// Pops history until [uri] is reached.
  void popToUri(Uri uri, {Object? state, Object? result}) {
    _popToUriViaRuntime(uri, state: state, result: result);
  }

  /// Goes back one history entry.
  bool back() {
    return _backViaRuntime();
  }

  /// Goes forward one history entry.
  void forward() {
    _forwardViaRuntime();
  }

  /// Moves history cursor by [delta].
  void goDelta(int delta) {
    _goDeltaViaRuntime(delta);
  }

  /// Switches active shell branch.
  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _switchBranchViaRuntime(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Pops active shell branch stack.
  bool popBranch([Object? result]) {
    return _popBranchViaRuntime(result);
  }

  /// Casts controller to another typed route view over the same runtime.
  UnrouterController<S> cast<S extends RouteData>() {
    return UnrouterController<S>._(
      routeInformationProvider: _routeInformationProvider,
      routeGetter: _routeGetter,
      uriGetter: _uriGetter,
      stateGetter: _stateGetter,
      stateStore: _stateStore,
      navigationState: _navigationState,
      routeRuntime: _routeRuntime,
      shellBranchTargetResolver: _shellBranchTargetResolver,
      shellBranchPopResolver: _shellBranchPopResolver,
      navigationRuntime: _navigationRuntime,
    );
  }

  void _goUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _navigationRuntime.goUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  void _replaceUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _navigationRuntime.replaceUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  Future<T?> _pushUriViaRuntime<T extends Object?>(Uri uri, {Object? state}) {
    return _navigationRuntime.pushUri<T>(uri, state: state);
  }

  bool _popViaRuntime([Object? result]) {
    return _navigationRuntime.pop(result);
  }

  void _popToUriViaRuntime(Uri uri, {Object? state, Object? result}) {
    _navigationRuntime.popToUri(uri, state: state, result: result);
  }

  bool _backViaRuntime() {
    return _navigationRuntime.back();
  }

  void _forwardViaRuntime() {
    _navigationRuntime.forward();
  }

  void _goDeltaViaRuntime(int delta) {
    _navigationRuntime.goDelta(delta);
  }

  bool _switchBranchViaRuntime(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _navigationRuntime.switchBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  bool _popBranchViaRuntime([Object? result]) {
    return _navigationRuntime.popBranch(result);
  }

  Future<void> _dispatchRouteRequest(Uri uri, {Object? state}) {
    final routeRuntime = _routeRuntime;
    if (routeRuntime == null) {
      throw StateError('Route runtime is not configured for this controller.');
    }
    return routeRuntime.resolveRequest(uri, state: state);
  }

  Uri? _resolveShellBranchTarget(int index, {required bool initialLocation}) {
    return _shellBranchTargetResolver(index, initialLocation: initialLocation);
  }

  Uri? _popShellBranchTarget() {
    return _shellBranchPopResolver();
  }

  Object? _composeHistoryState({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
  }) {
    final composer = _historyStateComposer;
    if (composer == null) {
      return state;
    }

    return composer(
      UnrouterHistoryStateRequest(
        uri: uri,
        action: action,
        state: state,
        currentState: historyState,
      ),
    );
  }

  Object? _composeHistoryStateForRuntime({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
  }) {
    return _composeHistoryState(uri: uri, action: action, state: state);
  }
}
