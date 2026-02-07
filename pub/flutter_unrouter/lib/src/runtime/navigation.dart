import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unrouter/machine.dart';
import 'package:unrouter/unrouter.dart'
    show
        UnrouterResolutionState,
        UnrouterStateSnapshot,
        UnrouterStateTimelineEntry;
import 'package:unstory/unstory.dart';

import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';
import '../platform/route_information_provider.dart';

export 'package:unrouter/machine.dart';

part 'navigation_machine_runtime.dart';
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

class _UnrouterControllerMachineHost<R extends RouteData>
    implements UnrouterMachineHost<R> {
  const _UnrouterControllerMachineHost(this._controller);

  final UnrouterController<R> _controller;

  @override
  UnrouterMachineState get machineState => _controller._machineState;

  @override
  List<UnrouterMachineTransitionEntry> get machineTimeline {
    return _controller._machineTimeline;
  }

  @override
  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _controller._goUriViaRuntime(
      uri,
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
    _controller._replaceUriViaRuntime(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  @override
  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    return _controller._pushUriViaRuntime<T>(uri, state: state);
  }

  @override
  bool pop([Object? result]) {
    return _controller._popViaRuntime(result);
  }

  @override
  void popToUri(Uri uri, {Object? state, Object? result}) {
    _controller._popToUriViaRuntime(uri, state: state, result: result);
  }

  @override
  bool back() {
    return _controller._backViaRuntime();
  }

  @override
  void forward() {
    _controller._forwardViaRuntime();
  }

  @override
  void goDelta(int delta) {
    _controller._goDeltaViaRuntime(delta);
  }

  @override
  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _controller._switchBranchViaRuntime(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  @override
  bool popBranch([Object? result]) {
    return _controller._popBranchViaRuntime(result);
  }
}

/// Runtime controller backing `BuildContext.unrouter`.
class UnrouterController<R extends RouteData> {
  UnrouterController({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required R? Function() routeGetter,
    required Uri Function() uriGetter,
    UnrouterStateSnapshot<RouteData> Function()? stateGetter,
    int stateTimelineLimit = 64,
    int machineTimelineLimit = 256,
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
           timelineLimit: stateTimelineLimit,
         ),
         navigationState: _UnrouterNavigationState(routeInformationProvider),
         machineStore: _UnrouterMachineTransitionStore(
           limit: machineTimelineLimit,
         ),
       );

  UnrouterController._({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required RouteData? Function() routeGetter,
    required Uri Function() uriGetter,
    required UnrouterStateSnapshot<RouteData> Function() stateGetter,
    required _UnrouterStateStore stateStore,
    required _UnrouterNavigationState navigationState,
    required _UnrouterMachineTransitionStore machineStore,
    _UnrouterRouteMachineDriver? routeMachine,
    Uri? Function(int index, {required bool initialLocation})?
    shellBranchTargetResolver,
    Uri? Function()? shellBranchPopResolver,
    _UnrouterNavigationMachine? navigationMachine,
  }) : _routeInformationProvider = routeInformationProvider,
       _routeGetter = routeGetter,
       _uriGetter = uriGetter,
       _stateGetter = stateGetter,
       _stateStore = stateStore,
       _navigationState = navigationState,
       _machineStore = machineStore {
    if (shellBranchTargetResolver != null) {
      _shellBranchTargetResolver = shellBranchTargetResolver;
    }
    if (shellBranchPopResolver != null) {
      _shellBranchPopResolver = shellBranchPopResolver;
    }
    _routeMachine = routeMachine;
    _machineReducer = _UnrouterMachineReducer(
      stateGetter: _captureMachineState,
      transitionStore: _machineStore,
    );
    _navigationMachine =
        navigationMachine ??
        _UnrouterNavigationMachine(
          routeInformationProvider: _routeInformationProvider,
          navigationState: _navigationState,
          composeHistoryState: _composeHistoryStateAsMachine,
          resolveShellBranchTarget: _resolveShellBranchTarget,
          popShellBranchTarget: _popShellBranchTarget,
          onTransition: _recordNavigationMachineTransition,
        );
    _navigationDispatch = _UnrouterNavigationDispatchAdapter(
      _navigationMachine,
    );
    if (_machineStore.entries.isEmpty) {
      final current = _captureMachineState();
      _recordMachineTransition(
        source: UnrouterMachineSource.controller,
        event: UnrouterMachineEvent.initialized,
        from: current,
        to: current,
        payload: <String, Object?>{
          'historyIndex': _routeInformationProvider.historyIndex,
        },
      );
    }
  }

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final RouteData? Function() _routeGetter;
  final Uri Function() _uriGetter;
  final UnrouterStateSnapshot<RouteData> Function() _stateGetter;
  final _UnrouterStateStore _stateStore;
  final _UnrouterNavigationState _navigationState;
  final _UnrouterMachineTransitionStore _machineStore;
  late final _UnrouterMachineReducer _machineReducer;
  late final _UnrouterNavigationMachine _navigationMachine;
  late final _UnrouterNavigationDispatchAdapter _navigationDispatch;
  UnrouterHistoryStateComposer? _historyStateComposer;
  _UnrouterRouteMachineDriver? _routeMachine;
  bool _isDisposed = false;
  Uri? Function(int index, {required bool initialLocation})
  _shellBranchTargetResolver = _defaultShellBranchTargetResolver;
  Uri? Function() _shellBranchPopResolver = _defaultShellBranchPopResolver;
  late final ValueListenable<UnrouterStateSnapshot<R>> _stateListenable =
      _UnrouterTypedStateListenable<R>(_stateStore.listenable);
  late final UnrouterMachineHost<R> _machineHost =
      _UnrouterControllerMachineHost<R>(this);

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

  List<UnrouterStateTimelineEntry<R>> get stateTimeline {
    return List<UnrouterStateTimelineEntry<R>>.unmodifiable(
      _stateStore.timeline.map((entry) => entry.cast<R>()),
    );
  }

  List<UnrouterMachineTransitionEntry> get _machineTimeline {
    return _machineStore.entries;
  }

  UnrouterMachineState get _machineState => _captureMachineState();

  /// Machine facade for command dispatch.
  UnrouterMachine<R> get machine => UnrouterMachine<R>.host(_machineHost);

  /// Records a machine transition into the bounded timeline.
  void _recordMachineTransition({
    required UnrouterMachineSource source,
    required UnrouterMachineEvent event,
    UnrouterMachineState? from,
    UnrouterMachineState? to,
    Uri? fromUri,
    Uri? toUri,
    UnrouterResolutionState? fromResolution,
    UnrouterResolutionState? toResolution,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    _machineReducer.reduce(
      source: source,
      event: event,
      from: from,
      to: to,
      fromUri: fromUri,
      toUri: toUri,
      fromResolution: fromResolution,
      toResolution: toResolution,
      payload: payload,
    );
  }

  /// Dispatches a machine command.
  T _dispatchMachineCommand<T extends Object?>(
    UnrouterMachineCommand<T> command,
  ) {
    return command.execute(_machineHost);
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
    _dispatchMachineCommand<void>(
      UnrouterMachineCommand.goUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
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
    _dispatchMachineCommand<void>(
      UnrouterMachineCommand.replaceUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  /// Pushes [route] and resolves typed result on pop.
  Future<T?> push<T extends Object?>(R route, {Object? state}) {
    return pushUri<T>(route.toUri(), state: state);
  }

  /// Pushes [uri] and resolves typed result on pop.
  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    return _dispatchMachineCommand<Future<T?>>(
      UnrouterMachineCommand.pushUri<T>(uri, state: state),
    );
  }

  /// Pops current entry and optionally completes pending push result.
  bool pop<T extends Object?>([T? result]) {
    return _dispatchMachineCommand<bool>(UnrouterMachineCommand.pop(result));
  }

  /// Pops history until [uri] is reached.
  void popToUri(Uri uri, {Object? state, Object? result}) {
    _dispatchMachineCommand<void>(
      UnrouterMachineCommand.popToUri(uri, state: state, result: result),
    );
  }

  /// Goes back one history entry.
  bool back() {
    return _dispatchMachineCommand<bool>(UnrouterMachineCommand.back());
  }

  /// Goes forward one history entry.
  void forward() {
    _dispatchMachineCommand<void>(UnrouterMachineCommand.forward());
  }

  /// Moves history cursor by [delta].
  void goDelta(int delta) {
    _dispatchMachineCommand<void>(UnrouterMachineCommand.goDelta(delta));
  }

  /// Switches active shell branch.
  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _dispatchMachineCommand<bool>(
      UnrouterMachineCommand.switchBranch(
        index,
        initialLocation: initialLocation,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  /// Pops active shell branch stack.
  bool popBranch([Object? result]) {
    return _dispatchMachineCommand<bool>(
      UnrouterMachineCommand.popBranch(result),
    );
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
      machineStore: _machineStore,
      routeMachine: _routeMachine,
      shellBranchTargetResolver: _shellBranchTargetResolver,
      shellBranchPopResolver: _shellBranchPopResolver,
      navigationMachine: _navigationMachine,
    );
  }

  void _goUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _navigationDispatch.dispatch<void>(
      _UnrouterMachineGoUriEvent(
        uri: uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  void _replaceUriViaRuntime(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    _navigationDispatch.dispatch<void>(
      _UnrouterMachineReplaceUriEvent(
        uri: uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  Future<T?> _pushUriViaRuntime<T extends Object?>(Uri uri, {Object? state}) {
    return _navigationDispatch.dispatch<Future<T?>>(
      _UnrouterMachinePushUriEvent<T>(uri: uri, state: state),
    );
  }

  bool _popViaRuntime([Object? result]) {
    return _navigationDispatch.dispatch<bool>(_UnrouterMachinePopEvent(result));
  }

  void _popToUriViaRuntime(Uri uri, {Object? state, Object? result}) {
    _navigationDispatch.dispatch<void>(
      _UnrouterMachinePopToUriEvent(state: state, uri: uri, result: result),
    );
  }

  bool _backViaRuntime() {
    return _navigationDispatch.dispatch<bool>(
      const _UnrouterMachineBackEvent(),
    );
  }

  void _forwardViaRuntime() {
    _navigationDispatch.dispatch<void>(const _UnrouterMachineForwardEvent());
  }

  void _goDeltaViaRuntime(int delta) {
    _navigationDispatch.dispatch<void>(_UnrouterMachineGoDeltaEvent(delta));
  }

  bool _switchBranchViaRuntime(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _navigationDispatch.dispatch<bool>(
      _UnrouterMachineSwitchBranchEvent(
        index: index,
        initialLocation: initialLocation,
        completePendingResult: completePendingResult,
        result: result,
      ),
    );
  }

  bool _popBranchViaRuntime([Object? result]) {
    return _navigationDispatch.dispatch<bool>(
      _UnrouterMachinePopBranchEvent(result),
    );
  }

  Future<void> _dispatchRouteRequest(Uri uri, {Object? state}) {
    final routeMachine = _routeMachine;
    if (routeMachine == null) {
      throw StateError('Route machine is not configured for this controller.');
    }
    return routeMachine.resolveRequest(uri, state: state);
  }

  Uri? _resolveShellBranchTarget(int index, {required bool initialLocation}) {
    return _shellBranchTargetResolver(index, initialLocation: initialLocation);
  }

  Uri? _popShellBranchTarget() {
    return _shellBranchPopResolver();
  }

  bool get _hasCustomShellBranchResolvers {
    return !identical(
          _shellBranchTargetResolver,
          _defaultShellBranchTargetResolver,
        ) ||
        !identical(_shellBranchPopResolver, _defaultShellBranchPopResolver);
  }

  void _recordControllerLifecycleTransition(
    UnrouterMachineEvent event, {
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    final current = _captureMachineState();
    _recordMachineTransition(
      source: UnrouterMachineSource.controller,
      event: event,
      from: current,
      to: current,
      payload: payload,
    );
  }

  void _recordRouteMachineTransition(
    _UnrouterRouteMachineTransition transition,
  ) {
    _recordMachineTransition(
      source: UnrouterMachineSource.route,
      event: transition.event,
      fromUri: transition.requestUri,
      toUri: transition.targetUri,
      toResolution: transition.toResolution,
      payload: <String, Object?>{
        'generation': transition.generation,
        ...transition.payload,
      },
    );
  }

  void _recordNavigationMachineTransition(
    _UnrouterNavigationMachineTransition transition,
  ) {
    final routeSnapshot = _stateStore.current;
    _recordMachineTransition(
      source: UnrouterMachineSource.navigation,
      event: transition.event,
      from: _machineStateFromNavigation(
        transition.before,
        routeSnapshot: routeSnapshot,
      ),
      to: _machineStateFromNavigation(
        transition.after,
        routeSnapshot: routeSnapshot,
      ),
      payload: <String, Object?>{
        'beforeAction': transition.before.lastAction.name,
        'afterAction': transition.after.lastAction.name,
        'beforeDelta': transition.before.lastDelta,
        'afterDelta': transition.after.lastDelta,
        'beforeHistoryIndex': transition.before.historyIndex,
        'afterHistoryIndex': transition.after.historyIndex,
        'beforeCanGoBack': transition.before.canGoBack,
        'afterCanGoBack': transition.after.canGoBack,
      },
    );
  }

  UnrouterMachineState _captureMachineState() {
    final snapshot = _stateStore.current;
    return UnrouterMachineState(
      uri: snapshot.uri,
      resolution: snapshot.resolution,
      routePath: snapshot.routePath,
      routeName: snapshot.routeName,
      historyAction: snapshot.lastAction,
      historyDelta: snapshot.lastDelta,
      historyIndex: snapshot.historyIndex,
      canGoBack: _routeInformationProvider.canGoBack,
    );
  }

  UnrouterMachineState _machineStateFromNavigation(
    _UnrouterNavigationMachineState navigation, {
    required UnrouterStateSnapshot<RouteData> routeSnapshot,
  }) {
    return UnrouterMachineState(
      uri: navigation.uri,
      resolution: routeSnapshot.resolution,
      routePath: routeSnapshot.routePath,
      routeName: routeSnapshot.routeName,
      historyAction: navigation.lastAction,
      historyDelta: navigation.lastDelta,
      historyIndex: navigation.historyIndex,
      canGoBack: navigation.canGoBack,
    );
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

  Object? _composeHistoryStateAsMachine({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
  }) {
    return _composeHistoryState(uri: uri, action: action, state: state);
  }
}
