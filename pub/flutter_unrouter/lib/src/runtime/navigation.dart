import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    as core
    show
        RouteRecord,
        RouteResolution,
        RouteResolutionType,
        Unrouter,
        UnrouterController;
import 'package:unrouter/unrouter.dart' show UnrouterStateSnapshot;
import 'package:unstory/unstory.dart';

import '../core/route_data.dart';
import '../platform/route_information_provider.dart';

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
    required core.Unrouter<RouteData> coreRouter,
    required UnrouterRouteInformationProvider routeInformationProvider,
    bool resolveInitialRoute = false,
  }) : this._(
         _UnrouterControllerRuntime(
           coreRouter: coreRouter,
           routeInformationProvider: routeInformationProvider,
           resolveInitialRoute: resolveInitialRoute,
         ),
       );

  UnrouterController._(this._runtime)
    : _stateListenable = _UnrouterTypedStateListenable<R>(
        _runtime.stateListenable,
      );

  final _UnrouterControllerRuntime _runtime;
  final ValueListenable<UnrouterStateSnapshot<R>> _stateListenable;

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
    final value = _runtime.coreController.route;
    if (value == null) {
      return null;
    }
    return value as R;
  }

  /// Current location URI.
  Uri get uri => _runtime.coreController.uri;

  /// Whether browser history can go back.
  bool get canGoBack => _runtime.coreController.canGoBack;

  /// Last history action applied by route information provider.
  HistoryAction get lastAction => _runtime.coreController.lastAction;

  /// Last history delta used for `go(delta)` style operations.
  int? get lastDelta => _runtime.coreController.lastDelta;

  /// Current history index when available from provider.
  int? get historyIndex => _runtime.coreController.historyIndex;

  /// Raw `history.state` payload of current location.
  Object? get historyState => _runtime.routeInformationProvider.value.state;

  core.RouteResolution<R> get resolution {
    return _castResolution<R>(_runtime.coreController.resolution);
  }

  UnrouterStateSnapshot<R> get state => _runtime.coreController.state.cast<R>();

  ValueListenable<UnrouterStateSnapshot<R>> get stateListenable {
    return _stateListenable;
  }

  /// Generates href for a typed route.
  String href(R route) {
    return _runtime.coreController.href(route);
  }

  /// Generates href for a URI.
  String hrefUri(Uri uri) {
    return _runtime.coreController.hrefUri(uri);
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
    _runtime.coreController.goUri(
      uri,
      state: _composeHistoryState(
        uri: uri,
        action: HistoryAction.replace,
        state: state,
      ),
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
    _runtime.coreController.replaceUri(
      uri,
      state: _composeHistoryState(
        uri: uri,
        action: HistoryAction.replace,
        state: state,
      ),
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
    return _runtime.coreController.pushUri<T>(
      uri,
      state: _composeHistoryState(
        uri: uri,
        action: HistoryAction.push,
        state: state,
      ),
    );
  }

  /// Pops current entry and optionally completes pending push result.
  bool pop<T extends Object?>([T? result]) {
    return _runtime.coreController.pop(result);
  }

  /// Pops history until [uri] is reached.
  void popToUri(Uri uri, {Object? state, Object? result}) {
    _runtime.coreController.popToUri(
      uri,
      state: _composeHistoryState(
        uri: uri,
        action: HistoryAction.replace,
        state: state,
      ),
      result: result,
    );
  }

  /// Goes back one history entry.
  bool back() {
    return _runtime.coreController.back();
  }

  /// Goes forward one history entry.
  void forward() {
    _runtime.coreController.forward();
  }

  /// Moves history cursor by [delta].
  void goDelta(int delta) {
    _runtime.coreController.goDelta(delta);
  }

  /// Switches active shell branch.
  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    Uri? target;
    try {
      target = _runtime.shellBranchTargetResolver(
        index,
        initialLocation: initialLocation,
      );
    } on RangeError {
      return false;
    } on ArgumentError {
      return false;
    }

    if (target == null) {
      return false;
    }

    _runtime.coreController.replaceUri(
      target,
      state: _composeHistoryState(
        uri: target,
        action: HistoryAction.replace,
        state: null,
      ),
      completePendingResult: completePendingResult,
      result: result,
    );
    return true;
  }

  /// Pops active shell branch stack.
  bool popBranch([Object? result]) {
    final target = _runtime.shellBranchPopResolver();
    if (target == null) {
      return false;
    }

    _runtime.coreController.replaceUri(
      target,
      state: _composeHistoryState(
        uri: target,
        action: HistoryAction.replace,
        state: null,
      ),
      completePendingResult: true,
      result: result,
    );
    return true;
  }

  /// Casts controller to another typed route view over the same runtime.
  UnrouterController<S> cast<S extends RouteData>() {
    return UnrouterController<S>._(_runtime);
  }

  /// Sets or clears custom history state composer.
  void setHistoryStateComposer(UnrouterHistoryStateComposer? composer) {
    _runtime.historyStateComposer = composer;
  }

  /// Clears custom history state composer.
  void clearHistoryStateComposer() {
    _runtime.historyStateComposer = null;
  }

  /// Registers shell branch URI resolvers.
  void setShellBranchResolvers({
    required Uri? Function(int index, {required bool initialLocation})
    resolveTarget,
    required Uri? Function() popTarget,
  }) {
    _runtime.shellBranchTargetResolver = resolveTarget;
    _runtime.shellBranchPopResolver = popTarget;
  }

  /// Clears custom shell branch URI resolvers.
  void clearShellBranchResolvers() {
    _runtime.shellBranchTargetResolver = _defaultShellBranchTargetResolver;
    _runtime.shellBranchPopResolver = _defaultShellBranchPopResolver;
  }

  /// Dispatches a route-resolution request through the internal route runtime.
  Future<void> dispatchRouteRequest(Uri uri, {Object? state}) {
    return _runtime.coreController.dispatchRouteRequest(uri, state: state);
  }

  /// Forces current state publication to listeners.
  void publishState() {
    _runtime.publishState();
  }

  /// Disposes controller runtime resources.
  void dispose() {
    _runtime.dispose();
  }

  Object? _composeHistoryState({
    required Uri uri,
    required HistoryAction action,
    required Object? state,
  }) {
    final composer = _runtime.historyStateComposer;
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
}

class _UnrouterControllerRuntime {
  _UnrouterControllerRuntime({
    required core.Unrouter<RouteData> coreRouter,
    required this.routeInformationProvider,
    required bool resolveInitialRoute,
  }) {
    _history = _UnrouterProviderBackedHistory(routeInformationProvider);
    coreController = core.UnrouterController<RouteData>(
      router: coreRouter,
      history: _history,
      resolveInitialRoute: resolveInitialRoute,
      disposeHistory: false,
    );
    stateListenable = ValueNotifier<UnrouterStateSnapshot<RouteData>>(
      coreController.state,
    );
    _stateSubscription = coreController.states.listen((snapshot) {
      stateListenable.value = snapshot;
    });
    publishState();
  }

  final UnrouterRouteInformationProvider routeInformationProvider;
  late final _UnrouterProviderBackedHistory _history;
  late final core.UnrouterController<RouteData> coreController;
  late final ValueNotifier<UnrouterStateSnapshot<RouteData>> stateListenable;

  UnrouterHistoryStateComposer? historyStateComposer;
  Uri? Function(int index, {required bool initialLocation})
  shellBranchTargetResolver =
      UnrouterController._defaultShellBranchTargetResolver;
  Uri? Function() shellBranchPopResolver =
      UnrouterController._defaultShellBranchPopResolver;

  late final StreamSubscription<UnrouterStateSnapshot<RouteData>>
  _stateSubscription;
  bool _isDisposed = false;

  void publishState() {
    if (_isDisposed) {
      return;
    }
    stateListenable.value = coreController.state;
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _stateSubscription.cancel();
    coreController.dispose();
    stateListenable.dispose();
  }
}

class _UnrouterProviderBackedHistory extends History {
  _UnrouterProviderBackedHistory(this._provider);

  final UnrouterRouteInformationProvider _provider;

  @override
  String get base => _provider.history.base;

  @override
  HistoryAction get action => _provider.lastAction;

  @override
  HistoryLocation get location {
    return HistoryLocation(_provider.value.uri, _provider.value.state);
  }

  @override
  int? get index => _provider.historyIndex;

  @override
  String createHref(Uri uri) => _provider.history.createHref(uri);

  @override
  void push(Uri uri, {Object? state}) {
    _provider.push(uri, state: state);
  }

  @override
  void replace(Uri uri, {Object? state}) {
    _provider.replace(uri, state: state);
  }

  @override
  void go(int delta, {bool triggerListeners = true}) {
    if (triggerListeners) {
      _provider.go(delta);
      return;
    }
    _provider.history.go(delta, triggerListeners: false);
  }

  @override
  void Function() listen(HistoryListener listener) {
    void onChanged() {
      if (_provider.lastAction != HistoryAction.pop) {
        return;
      }
      listener(
        HistoryEvent(
          action: HistoryAction.pop,
          location: HistoryLocation(_provider.value.uri, _provider.value.state),
          delta: _provider.lastDelta,
        ),
      );
    }

    _provider.addListener(onChanged);
    return () {
      _provider.removeListener(onChanged);
    };
  }

  @override
  void dispose() {}
}

core.RouteResolution<S> _castResolution<S extends RouteData>(
  core.RouteResolution<RouteData> raw,
) {
  switch (raw.type) {
    case core.RouteResolutionType.pending:
      return core.RouteResolution<S>.pending(raw.uri);
    case core.RouteResolutionType.unmatched:
      return core.RouteResolution<S>.unmatched(raw.uri);
    case core.RouteResolutionType.blocked:
      return core.RouteResolution<S>.blocked(raw.uri);
    case core.RouteResolutionType.redirect:
      final redirectUri = raw.redirectUri;
      if (redirectUri == null) {
        return core.RouteResolution<S>.error(
          uri: raw.uri,
          error: StateError('Redirect resolution is missing target uri.'),
          stackTrace: StackTrace.current,
        );
      }
      return core.RouteResolution<S>.redirect(
        uri: raw.uri,
        redirectUri: redirectUri,
      );
    case core.RouteResolutionType.error:
      return core.RouteResolution<S>.error(
        uri: raw.uri,
        error: raw.error ?? StateError('Unknown route resolution error.'),
        stackTrace: raw.stackTrace ?? StackTrace.current,
      );
    case core.RouteResolutionType.matched:
      final record = raw.record;
      final route = raw.route;
      if (record == null || route == null) {
        return core.RouteResolution<S>.error(
          uri: raw.uri,
          error: StateError('Matched resolution is missing route metadata.'),
          stackTrace: StackTrace.current,
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

class _UnrouterTypedStateListenable<R extends RouteData>
    implements ValueListenable<UnrouterStateSnapshot<R>> {
  const _UnrouterTypedStateListenable(this._source);

  final ValueListenable<UnrouterStateSnapshot<RouteData>> _source;

  @override
  UnrouterStateSnapshot<R> get value => _source.value.cast<R>();

  @override
  void addListener(VoidCallback listener) {
    _source.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _source.removeListener(listener);
  }
}

class UnrouterScope extends InheritedWidget {
  const UnrouterScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final UnrouterController<RouteData> controller;

  /// Reads untyped controller from widget tree.
  static UnrouterController<RouteData> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UnrouterScope>();
    if (scope != null) {
      return scope.controller;
    }

    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('UnrouterScope was not found in context.'),
      ErrorDescription(
        'No Unrouter widget is available above this BuildContext.',
      ),
    ]);
  }

  /// Reads typed controller from widget tree.
  static UnrouterController<R> ofAs<R extends RouteData>(BuildContext context) {
    return of(context).cast<R>();
  }

  @override
  bool updateShouldNotify(UnrouterScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// `BuildContext` helpers for core router access.
extension UnrouterBuildContextExtension on BuildContext {
  /// Returns the untyped router controller.
  UnrouterController<RouteData> get unrouter => UnrouterScope.of(this);

  /// Returns a typed router controller.
  UnrouterController<R> unrouterAs<R extends RouteData>() {
    return UnrouterScope.ofAs<R>(this);
  }
}
