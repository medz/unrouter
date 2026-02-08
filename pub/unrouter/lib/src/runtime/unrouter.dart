import 'dart:async';
import 'dart:collection';

import 'package:roux/roux.dart';
import 'package:unstory/unstory.dart';

import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';
import '../core/route_guards.dart';
import '../core/route_records.dart';
import '../core/route_state.dart';
import 'state.dart';
import 'unrouter_controller_cast_view.dart';

export '../core/redirect_diagnostics.dart';

/// Platform-agnostic router configuration entrypoint for typed URL-first
/// resolution.
class Unrouter<R extends RouteData> {
  Unrouter({
    required List<RouteRecord<R>> routes,
    this.maxRedirectHops = 8,
    this.redirectLoopPolicy = RedirectLoopPolicy.error,
    this.onRedirectDiagnostics,
  }) : assert(routes.isNotEmpty, 'Unrouter routes must not be empty.'),
       assert(
         maxRedirectHops > 0,
         'Unrouter maxRedirectHops must be greater than zero.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       _matcher = _createMatcher(routes);

  /// Immutable route table consumed by the matcher.
  final List<RouteRecord<R>> routes;
  final RouterContext<RouteRecord<R>> _matcher;

  /// Redirect hop limit used to prevent infinite redirect chains.
  final int maxRedirectHops;

  /// Policy used when redirect loops are detected.
  final RedirectLoopPolicy redirectLoopPolicy;

  /// Callback invoked when redirect safety checks emit diagnostics.
  final RedirectDiagnosticsCallback? onRedirectDiagnostics;

  /// Resolves [uri] to a typed route, redirect, block, or error result.
  Future<RouteResolution<R>> resolve(
    Uri uri, {
    RouteExecutionSignal signal = const RouteNeverCancelledSignal(),
  }) async {
    final normalizedUri = _normalizeUri(uri);
    final lookupPath = _normalizeLookupPath(normalizedUri.path);
    final matched = findRoute<RouteRecord<R>>(_matcher, null, lookupPath);
    if (matched == null) {
      return RouteResolution.unmatched(normalizedUri);
    }

    final params = matched.params ?? const <String, String>{};
    final state = RouteState(
      location: HistoryLocation(normalizedUri),
      params: params,
    );

    late final R route;
    try {
      route = matched.data.parse(state);
    } catch (error, stackTrace) {
      return RouteResolution.error(
        uri: normalizedUri,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final context = RouteContext<RouteData>(
      uri: normalizedUri,
      route: route,
      signal: signal,
    );

    try {
      signal.throwIfCancelled();

      final redirectUri = await matched.data.runRedirect(context);
      signal.throwIfCancelled();
      if (redirectUri != null) {
        return RouteResolution.redirect(
          uri: normalizedUri,
          redirectUri: _normalizeUri(redirectUri),
        );
      }

      final guardResult = await matched.data.runGuards(context);
      signal.throwIfCancelled();
      if (guardResult.isRedirect) {
        final target = guardResult.uri;
        if (target == null) {
          return RouteResolution.error(
            uri: normalizedUri,
            error: StateError(
              'Route guard returned redirect without target uri for path '
              '"${matched.data.path}".',
            ),
            stackTrace: StackTrace.current,
          );
        }

        return RouteResolution.redirect(
          uri: normalizedUri,
          redirectUri: _normalizeUri(target),
        );
      }

      if (guardResult.isBlocked) {
        return RouteResolution.blocked(normalizedUri);
      }

      Object? loaderData;
      final record = matched.data;
      if (record case DataRouteDefinition<R, Object?> dataRoute) {
        loaderData = await dataRoute.load(context);
      }
      signal.throwIfCancelled();

      return RouteResolution.matched(
        uri: normalizedUri,
        route: route,
        record: matched.data,
        loaderData: loaderData,
      );
    } on RouteExecutionCancelledException {
      rethrow;
    } catch (error, stackTrace) {
      return RouteResolution.error(
        uri: normalizedUri,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static RouterContext<RouteRecord<R>> _createMatcher<R extends RouteData>(
    List<RouteRecord<R>> routes,
  ) {
    final matcher = createRouter<RouteRecord<R>>(caseSensitive: true);
    for (final route in routes) {
      addRoute<RouteRecord<R>>(matcher, null, route.path, route);
    }
    return matcher;
  }

  static Uri _normalizeUri(Uri uri) {
    final normalizedPath = _normalizeLookupPath(uri.path);
    if (normalizedPath == uri.path) {
      return uri;
    }

    return uri.replace(path: normalizedPath);
  }

  static String _normalizeLookupPath(String path) {
    if (path.isEmpty) {
      return '/';
    }

    if (!path.startsWith('/')) {
      return '/$path';
    }

    return path;
  }
}

/// Route resolution lifecycle state.
enum RouteResolutionType {
  pending,
  matched,
  unmatched,
  redirect,
  blocked,
  error,
}

/// Result returned by [Unrouter.resolve].
class RouteResolution<R extends RouteData> {
  const RouteResolution._({
    required this.type,
    required this.uri,
    this.record,
    this.route,
    this.loaderData,
    this.redirectUri,
    this.error,
    this.stackTrace,
  });

  factory RouteResolution.pending(Uri uri) {
    return RouteResolution._(type: RouteResolutionType.pending, uri: uri);
  }

  factory RouteResolution.matched({
    required Uri uri,
    required RouteRecord<R> record,
    required R route,
    Object? loaderData,
  }) {
    return RouteResolution._(
      type: RouteResolutionType.matched,
      uri: uri,
      record: record,
      route: route,
      loaderData: loaderData,
    );
  }

  factory RouteResolution.unmatched(Uri uri) {
    return RouteResolution._(type: RouteResolutionType.unmatched, uri: uri);
  }

  factory RouteResolution.redirect({
    required Uri uri,
    required Uri redirectUri,
  }) {
    return RouteResolution._(
      type: RouteResolutionType.redirect,
      uri: uri,
      redirectUri: redirectUri,
    );
  }

  factory RouteResolution.blocked(Uri uri) {
    return RouteResolution._(type: RouteResolutionType.blocked, uri: uri);
  }

  factory RouteResolution.error({
    required Uri uri,
    required Object error,
    required StackTrace stackTrace,
  }) {
    return RouteResolution._(
      type: RouteResolutionType.error,
      uri: uri,
      error: error,
      stackTrace: stackTrace,
    );
  }

  final RouteResolutionType type;
  final Uri uri;
  final RouteRecord<R>? record;
  final R? route;
  final Object? loaderData;
  final Uri? redirectUri;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isPending => type == RouteResolutionType.pending;

  bool get isMatched => type == RouteResolutionType.matched;

  bool get isUnmatched => type == RouteResolutionType.unmatched;

  bool get isRedirect => type == RouteResolutionType.redirect;

  bool get isBlocked => type == RouteResolutionType.blocked;

  bool get hasError => type == RouteResolutionType.error;
}

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

/// Composes custom history state payload before navigation writes.
typedef UnrouterHistoryStateComposer =
    Object? Function(UnrouterHistoryStateRequest request);

/// Platform-agnostic runtime controller for [Unrouter].
///
/// This controller is designed for pure Dart usage while keeping method names
/// aligned with adapter packages.
class UnrouterController<R extends RouteData> {
  static Uri? _defaultShellBranchTargetResolver(
    int _, {
    required bool initialLocation,
  }) {
    return null;
  }

  static Uri? _defaultShellBranchPopResolver() {
    return null;
  }

  UnrouterController({
    required Unrouter<R> router,
    History? history,
    bool resolveInitialRoute = true,
    bool disposeHistory = true,
  }) : this._(
         router: router,
         history: history ?? MemoryHistory(),
         resolveInitialRoute: resolveInitialRoute,
         disposeHistory: disposeHistory,
       );

  UnrouterController._({
    required Unrouter<R> router,
    required History history,
    required bool resolveInitialRoute,
    required bool disposeHistory,
  }) : _router = router,
       _history = history,
       _disposeHistory = disposeHistory,
       _lastAction = history.action,
       _trackedHistoryIndex = history.index ?? 0,
       _resolution = RouteResolution<R>.pending(history.location.uri),
       _state = StateSnapshot<R>(
         uri: history.location.uri,
         route: null,
         resolution: ResolutionState.pending,
         routePath: null,
         routeName: null,
         error: null,
         stackTrace: null,
         lastAction: history.action,
         lastDelta: null,
         historyIndex: history.index,
       ) {
    _unlisten = _history.listen(_onHistoryChanged);
    if (resolveInitialRoute) {
      _scheduleResolve(_history.location.uri, state: _history.location.state);
    }
  }

  final Unrouter<R> _router;
  final History _history;
  final bool _disposeHistory;

  late final void Function() _unlisten;

  final StreamController<StateSnapshot<R>> _stateController =
      StreamController<StateSnapshot<R>>.broadcast();
  final List<Completer<Object?>> _pendingPushResults = <Completer<Object?>>[];
  final ListQueue<Object?> _popResultQueue = ListQueue<Object?>();

  RouteResolution<R> _resolution;
  StateSnapshot<R> _state;
  int _trackedHistoryIndex;
  HistoryAction _lastAction;
  int? _lastDelta;
  bool _hasCommittedResolution = false;
  int _generation = 0;
  Uri? _resolvingUri;
  Future<void>? _resolvingFuture;
  _RedirectChainState? _redirectChain;
  bool _isDisposed = false;
  UnrouterHistoryStateComposer? _historyStateComposer;
  Uri? Function(int index, {required bool initialLocation})
  _shellBranchTargetResolver = _defaultShellBranchTargetResolver;
  Uri? Function() _shellBranchPopResolver = _defaultShellBranchPopResolver;

  /// Underlying history abstraction.
  History get history => _history;

  /// Current typed route object.
  R? get route => _state.route;

  /// Current location URI.
  Uri get uri => _history.location.uri;

  /// Whether history can go back.
  bool get canGoBack => (_history.index ?? 0) > 0;

  /// Last history action observed by this controller.
  HistoryAction get lastAction => _lastAction;

  /// Last history delta observed by this controller.
  int? get lastDelta => _lastDelta;

  /// Current history index when available.
  int? get historyIndex => _history.index;

  /// Raw history state payload of current location.
  Object? get historyState => _history.location.state;

  /// Current runtime snapshot.
  StateSnapshot<R> get state => _state;

  /// Current route resolution.
  RouteResolution<R> get resolution => _resolution;

  /// Broadcast stream of state updates.
  Stream<StateSnapshot<R>> get states => _stateController.stream;

  /// Pending resolution task, or an already completed future when idle.
  Future<void> get idle => _resolvingFuture ?? Future<void>.value();

  /// Generates href for a typed route.
  String href(R route) {
    return _history.createHref(route.toUri());
  }

  /// Generates href for a URI.
  String hrefUri(Uri uri) {
    return _history.createHref(uri);
  }

  /// Navigates to [route] using replace-like semantics.
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

  /// Navigates to [uri] using replace-like semantics.
  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    if (_isDisposed) {
      return;
    }
    final composedState = _composeHistoryState(
      uri: uri,
      action: HistoryAction.replace,
      state: state,
    );
    if (completePendingResult) {
      _completeTopPending(result);
    }
    _history.replace(uri, state: composedState);
    _lastAction = HistoryAction.replace;
    _lastDelta = null;
    _trackedHistoryIndex = _history.index ?? _trackedHistoryIndex;
    _scheduleResolve(uri, state: composedState);
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
    goUri(
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
    if (_isDisposed) {
      return Future<T?>.value(null);
    }
    final composedState = _composeHistoryState(
      uri: uri,
      action: HistoryAction.push,
      state: state,
    );

    final completer = Completer<Object?>();
    _pendingPushResults.add(completer);
    _history.push(uri, state: composedState);
    _lastAction = HistoryAction.push;
    _lastDelta = null;
    _trackedHistoryIndex = _history.index ?? (_trackedHistoryIndex + 1);
    _scheduleResolve(uri, state: composedState);
    return completer.future.then((value) => value as T?);
  }

  /// Pops current entry and optionally completes pending push result.
  bool pop<T extends Object?>([T? result]) {
    if (_isDisposed || !canGoBack) {
      return false;
    }
    _popResultQueue.addLast(result);
    _history.back();
    return true;
  }

  /// Pops by replacing with [uri] and completes top pending result.
  void popToUri(Uri uri, {Object? state, Object? result}) {
    if (_isDisposed) {
      return;
    }
    final composedState = _composeHistoryState(
      uri: uri,
      action: HistoryAction.replace,
      state: state,
    );
    _completeTopPending(result);
    _history.replace(uri, state: composedState);
    _lastAction = HistoryAction.replace;
    _lastDelta = null;
    _trackedHistoryIndex = _history.index ?? _trackedHistoryIndex;
    _scheduleResolve(uri, state: composedState);
  }

  /// Goes back one history entry.
  bool back() {
    if (_isDisposed || !canGoBack) {
      return false;
    }
    _history.back();
    return true;
  }

  /// Goes forward one history entry.
  void forward() {
    if (_isDisposed) {
      return;
    }
    _history.forward();
  }

  /// Moves history cursor by [delta].
  void goDelta(int delta) {
    if (_isDisposed) {
      return;
    }
    _history.go(delta);
  }

  /// Sets or clears custom history state composer.
  void setHistoryStateComposer(UnrouterHistoryStateComposer? composer) {
    _historyStateComposer = composer;
  }

  /// Clears custom history state composer.
  void clearHistoryStateComposer() {
    _historyStateComposer = null;
  }

  /// Registers shell branch URI resolvers.
  void setShellBranchResolvers({
    required Uri? Function(int index, {required bool initialLocation})
    resolveTarget,
    required Uri? Function() popTarget,
  }) {
    _shellBranchTargetResolver = resolveTarget;
    _shellBranchPopResolver = popTarget;
  }

  /// Clears custom shell branch URI resolvers.
  void clearShellBranchResolvers() {
    _shellBranchTargetResolver = _defaultShellBranchTargetResolver;
    _shellBranchPopResolver = _defaultShellBranchPopResolver;
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
      target = _shellBranchTargetResolver(
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

    replaceUri(
      target,
      state: null,
      completePendingResult: completePendingResult,
      result: result,
    );
    return true;
  }

  /// Pops active shell branch stack.
  bool popBranch([Object? result]) {
    final target = _shellBranchPopResolver();
    if (target == null) {
      return false;
    }

    replaceUri(
      target,
      state: null,
      completePendingResult: true,
      result: result,
    );
    return true;
  }

  /// Casts controller to another typed route view over the same runtime.
  UnrouterController<S> cast<S extends RouteData>() {
    if (this is UnrouterController<S>) {
      return this as UnrouterController<S>;
    }
    return UnrouterControllerCastView<S>(this);
  }

  /// Resolves [uri] and commits router state.
  Future<void> dispatchRouteRequest(Uri uri, {Object? state}) {
    if (_isDisposed) {
      return Future<void>.value();
    }

    final activeUri = _resolvingUri;
    final activeFuture = _resolvingFuture;
    if (activeUri != null &&
        activeFuture != null &&
        _isSameUri(activeUri, uri)) {
      return activeFuture;
    }

    final request = _resolve(uri, state: state);
    _resolvingUri = uri;
    _resolvingFuture = request.whenComplete(() {
      if (identical(_resolvingFuture, request)) {
        _resolvingUri = null;
        _resolvingFuture = null;
      }
    });
    return _resolvingFuture!;
  }

  /// Forces state publication to listeners.
  void publishState() {
    if (_isDisposed) {
      return;
    }
    _emitState(_state);
  }

  /// Disposes controller resources.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _unlisten();
    if (_disposeHistory) {
      _history.dispose();
    }
    for (final completer in _pendingPushResults) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _pendingPushResults.clear();
    _popResultQueue.clear();
    _stateController.close();
    _redirectChain = null;
    _resolvingUri = null;
    _resolvingFuture = null;
  }

  Future<void> _resolve(Uri uri, {Object? state}) async {
    final generation = ++_generation;
    final previousResolution = _resolution;
    final previousSnapshot = _state;
    final previousUri = _state.uri;
    _prepareRedirectChain(uri);
    _setPending(uri);

    bool isCancelled() {
      return generation != _generation;
    }

    Uri currentUri = uri;
    while (true) {
      RouteResolution<R> resolution;
      try {
        resolution = await _router.resolve(
          currentUri,
          signal: _ControllerRouteExecutionSignal(isCancelled: isCancelled),
        );
      } on RouteExecutionCancelledException {
        return;
      }
      if (isCancelled()) {
        return;
      }

      if (resolution.isRedirect) {
        final redirectUri = resolution.redirectUri;
        if (redirectUri == null) {
          _clearRedirectChain();
          _commitResolution(
            RouteResolution<R>.error(
              uri: currentUri,
              error: StateError('Redirect resolution is missing target uri.'),
              stackTrace: StackTrace.current,
            ),
          );
          return;
        }

        final diagnostics = _registerRedirect(
          uri: currentUri,
          redirectUri: redirectUri,
        );
        if (diagnostics != null) {
          _reportRedirectDiagnostics(diagnostics);
          _clearRedirectChain();
          _commitResolution(
            RouteResolution<R>.error(
              uri: currentUri,
              error: StateError(_buildRedirectErrorMessage(diagnostics)),
              stackTrace: StackTrace.current,
            ),
          );
          return;
        }

        _history.replace(redirectUri, state: state);
        _lastAction = HistoryAction.replace;
        _lastDelta = null;
        _trackedHistoryIndex = _history.index ?? _trackedHistoryIndex;
        currentUri = redirectUri;
        _setPending(currentUri);
        continue;
      }

      if (resolution.isBlocked) {
        _clearRedirectChain();
        if (_hasCommittedResolution) {
          if (!_isSameUri(currentUri, previousUri)) {
            _history.replace(previousUri, state: state);
            _lastAction = HistoryAction.replace;
            _lastDelta = null;
            _trackedHistoryIndex = _history.index ?? _trackedHistoryIndex;
          }
          _updateState(
            StateSnapshot<R>(
              uri: previousSnapshot.uri,
              route: previousSnapshot.route,
              resolution: previousSnapshot.resolution,
              routePath: previousSnapshot.routePath,
              routeName: previousSnapshot.routeName,
              error: previousSnapshot.error,
              stackTrace: previousSnapshot.stackTrace,
              lastAction: _lastAction,
              lastDelta: _lastDelta,
              historyIndex: _history.index,
            ),
          );
          _resolution = previousResolution;
          return;
        }

        _commitResolution(RouteResolution<R>.unmatched(currentUri));
        return;
      }

      _clearRedirectChain();
      _commitResolution(resolution);
      return;
    }
  }

  void _onHistoryChanged(HistoryEvent event) {
    if (_isDisposed) {
      return;
    }

    _lastAction = event.action;
    _lastDelta = event.delta;
    final previousIndex = _trackedHistoryIndex;
    final nextIndex = _resolveHistoryIndex(
      fallbackIndex: previousIndex,
      historyIndex: _history.index,
      action: event.action,
      delta: event.delta,
    );
    if (event.action == HistoryAction.pop) {
      final poppedCount = _resolvePoppedCount(
        previousIndex: previousIndex,
        nextIndex: nextIndex,
        delta: event.delta,
      );
      _completePoppedEntries(poppedCount);
    }
    _trackedHistoryIndex = nextIndex;
    _scheduleResolve(event.location.uri, state: event.location.state);
  }

  void _setPending(Uri uri) {
    _resolution = RouteResolution<R>.pending(uri);
    final pending = StateSnapshot<R>(
      uri: uri,
      route: null,
      resolution: ResolutionState.pending,
      routePath: null,
      routeName: null,
      error: null,
      stackTrace: null,
      lastAction: _lastAction,
      lastDelta: _lastDelta,
      historyIndex: _history.index,
    );
    _updateState(pending);
  }

  void _commitResolution(RouteResolution<R> resolution) {
    _resolution = resolution;
    _hasCommittedResolution = true;
    final snapshot = StateSnapshot<R>(
      uri: resolution.uri,
      route: resolution.route,
      resolution: _mapResolutionState(resolution.type),
      routePath: resolution.record?.path,
      routeName: resolution.record?.name,
      error: resolution.error,
      stackTrace: resolution.stackTrace,
      lastAction: _lastAction,
      lastDelta: _lastDelta,
      historyIndex: _history.index,
    );
    _updateState(snapshot);
  }

  void _updateState(StateSnapshot<R> next) {
    if (_isSameSnapshot(_state, next)) {
      return;
    }
    _state = next;
    _emitState(next);
  }

  void _emitState(StateSnapshot<R> snapshot) {
    if (_stateController.isClosed) {
      return;
    }
    _stateController.add(snapshot);
  }

  bool _isSameSnapshot(StateSnapshot<R> a, StateSnapshot<R> b) {
    return a.uri.toString() == b.uri.toString() &&
        _routeIdentity(a.route) == _routeIdentity(b.route) &&
        a.resolution == b.resolution &&
        a.routePath == b.routePath &&
        a.routeName == b.routeName &&
        a.error == b.error &&
        a.stackTrace == b.stackTrace &&
        a.lastAction == b.lastAction &&
        a.lastDelta == b.lastDelta &&
        a.historyIndex == b.historyIndex;
  }

  String? _routeIdentity(RouteData? route) {
    if (route == null) {
      return null;
    }
    return '${route.runtimeType}:${route.toUri()}';
  }

  void _scheduleResolve(Uri uri, {Object? state}) {
    unawaited(dispatchRouteRequest(uri, state: state));
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

  int _resolveHistoryIndex({
    required int fallbackIndex,
    required int? historyIndex,
    required HistoryAction action,
    required int? delta,
  }) {
    if (historyIndex != null) {
      return historyIndex;
    }

    switch (action) {
      case HistoryAction.push:
        return fallbackIndex + 1;
      case HistoryAction.replace:
        return fallbackIndex;
      case HistoryAction.pop:
        final movement = delta ?? 0;
        final next = fallbackIndex + movement;
        if (next < 0) {
          return 0;
        }
        return next;
    }
  }

  int _resolvePoppedCount({
    required int previousIndex,
    required int nextIndex,
    required int? delta,
  }) {
    if (delta != null) {
      if (delta < 0) {
        return -delta;
      }
      return 0;
    }

    if (nextIndex < previousIndex) {
      return previousIndex - nextIndex;
    }

    return 0;
  }

  void _completePoppedEntries(int poppedCount) {
    for (var i = 0; i < poppedCount; i++) {
      final result = i == 0 && _popResultQueue.isNotEmpty
          ? _popResultQueue.removeFirst()
          : null;
      _completeTopPending(result);
    }
  }

  void _completeTopPending(Object? result) {
    if (_pendingPushResults.isEmpty) {
      return;
    }

    final completer = _pendingPushResults.removeLast();
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void _prepareRedirectChain(Uri incomingUri) {
    final chain = _redirectChain;
    if (chain == null) {
      return;
    }

    final expected = chain.expectedNextUri;
    if (expected != null && _isSameUri(expected, incomingUri)) {
      chain.expectedNextUri = null;
      return;
    }

    _clearRedirectChain();
  }

  RedirectDiagnostics? _registerRedirect({
    required Uri uri,
    required Uri redirectUri,
  }) {
    var chain = _redirectChain;
    if (chain == null) {
      chain = _RedirectChainState.initial(uri);
      _redirectChain = chain;
    } else {
      chain.recordCurrent(uri);
    }

    chain.hops += 1;
    final trailCandidate = chain.trailWith(redirectUri);
    if (chain.hops > _router.maxRedirectHops) {
      return RedirectDiagnostics(
        reason: RedirectDiagnosticsReason.maxHopsExceeded,
        currentUri: uri,
        redirectUri: redirectUri,
        trail: trailCandidate,
        hop: chain.hops,
        maxHops: _router.maxRedirectHops,
        loopPolicy: _router.redirectLoopPolicy,
      );
    }

    final redirectKey = redirectUri.toString();
    if (_router.redirectLoopPolicy == RedirectLoopPolicy.error &&
        chain.seen.contains(redirectKey)) {
      return RedirectDiagnostics(
        reason: RedirectDiagnosticsReason.loopDetected,
        currentUri: uri,
        redirectUri: redirectUri,
        trail: trailCandidate,
        hop: chain.hops,
        maxHops: _router.maxRedirectHops,
        loopPolicy: _router.redirectLoopPolicy,
      );
    }

    chain.acceptRedirect(redirectUri);
    return null;
  }

  void _clearRedirectChain() {
    if (_redirectChain == null) {
      return;
    }
    _redirectChain = null;
  }

  void _reportRedirectDiagnostics(RedirectDiagnostics diagnostics) {
    final callback = _router.onRedirectDiagnostics;
    if (callback == null) {
      return;
    }
    callback(diagnostics);
  }

  String _buildRedirectErrorMessage(RedirectDiagnostics diagnostics) {
    final trail = diagnostics.trail.map((uri) => uri.toString()).join(' -> ');
    switch (diagnostics.reason) {
      case RedirectDiagnosticsReason.loopDetected:
        return 'Redirect loop detected '
            '(policy: ${diagnostics.loopPolicy.name}, '
            'hop ${diagnostics.hop}/${diagnostics.maxHops}): $trail';
      case RedirectDiagnosticsReason.maxHopsExceeded:
        return 'Maximum redirect hops (${diagnostics.maxHops}) exceeded '
            'at hop ${diagnostics.hop} '
            '(policy: ${diagnostics.loopPolicy.name}): $trail';
    }
  }

  bool _isSameUri(Uri a, Uri b) {
    return a.toString() == b.toString();
  }

  ResolutionState _mapResolutionState(RouteResolutionType type) {
    switch (type) {
      case RouteResolutionType.pending:
        return ResolutionState.pending;
      case RouteResolutionType.matched:
        return ResolutionState.matched;
      case RouteResolutionType.unmatched:
        return ResolutionState.unmatched;
      case RouteResolutionType.redirect:
        return ResolutionState.redirect;
      case RouteResolutionType.blocked:
        return ResolutionState.blocked;
      case RouteResolutionType.error:
        return ResolutionState.error;
    }
  }
}

class _ControllerRouteExecutionSignal implements RouteExecutionSignal {
  const _ControllerRouteExecutionSignal({required bool Function() isCancelled})
    : _isCancelled = isCancelled;

  final bool Function() _isCancelled;

  @override
  bool get isCancelled => _isCancelled();

  @override
  void throwIfCancelled() {
    if (isCancelled) {
      throw const RouteExecutionCancelledException();
    }
  }
}

class _RedirectChainState {
  _RedirectChainState({required this.trail}) {
    seen = trail.map((uri) => uri.toString()).toSet();
  }

  factory _RedirectChainState.initial(Uri uri) {
    return _RedirectChainState(trail: <Uri>[uri]);
  }

  final List<Uri> trail;
  late final Set<String> seen;
  int hops = 0;
  Uri? expectedNextUri;

  void recordCurrent(Uri uri) {
    final uriKey = uri.toString();
    if (trail.isEmpty || trail.last.toString() != uriKey) {
      trail.add(uri);
    }
    seen.add(uriKey);
  }

  List<Uri> trailWith(Uri uri) {
    final uriKey = uri.toString();
    if (trail.isNotEmpty && trail.last.toString() == uriKey) {
      return List<Uri>.unmodifiable(trail);
    }
    return List<Uri>.unmodifiable(<Uri>[...trail, uri]);
  }

  void acceptRedirect(Uri redirectUri) {
    final redirectKey = redirectUri.toString();
    seen.add(redirectKey);
    if (trail.isEmpty || trail.last.toString() != redirectKey) {
      trail.add(redirectUri);
    }
    expectedNextUri = redirectUri;
  }
}
