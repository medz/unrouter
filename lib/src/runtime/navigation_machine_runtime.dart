part of 'navigation.dart';

sealed class _UnrouterNavigationMachineEvent {
  const _UnrouterNavigationMachineEvent();

  UnrouterMachineEvent get event;
}

final class _UnrouterMachineGoUriEvent extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineGoUriEvent({
    required this.uri,
    required this.state,
    required this.completePendingResult,
    required this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goUri;
}

final class _UnrouterMachineReplaceUriEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineReplaceUriEvent({
    required this.uri,
    required this.state,
    required this.completePendingResult,
    required this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.replaceUri;
}

final class _UnrouterMachinePushUriEvent<T extends Object?>
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePushUriEvent({required this.uri, required this.state});

  final Uri uri;
  final Object? state;

  Future<T?> execute(
    _UnrouterNavigationState navigationState,
    Object? composedState,
  ) {
    return navigationState.pushForResult<T>(uri, state: composedState);
  }

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;
}

final class _UnrouterMachinePopEvent extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePopEvent(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pop;
}

final class _UnrouterMachinePopToUriEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePopToUriEvent({
    required this.uri,
    required this.state,
    required this.result,
  });

  final Uri uri;
  final Object? state;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popToUri;
}

final class _UnrouterMachineBackEvent extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineBackEvent();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.back;
}

final class _UnrouterMachineForwardEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineForwardEvent();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.forward;
}

final class _UnrouterMachineGoDeltaEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineGoDeltaEvent(this.delta);

  final int delta;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goDelta;
}

final class _UnrouterMachineSwitchBranchEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachineSwitchBranchEvent({
    required this.index,
    required this.initialLocation,
    required this.completePendingResult,
    required this.result,
  });

  final int index;
  final bool initialLocation;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.switchBranch;
}

final class _UnrouterMachinePopBranchEvent
    extends _UnrouterNavigationMachineEvent {
  const _UnrouterMachinePopBranchEvent(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popBranch;
}

class _UnrouterNavigationMachineState {
  const _UnrouterNavigationMachineState({
    required this.uri,
    required this.historyState,
    required this.lastAction,
    required this.lastDelta,
    required this.historyIndex,
    required this.canGoBack,
  });

  factory _UnrouterNavigationMachineState.fromProvider(
    UnrouterRouteInformationProvider provider,
  ) {
    return _UnrouterNavigationMachineState(
      uri: provider.value.uri,
      historyState: provider.value.state,
      lastAction: provider.lastAction,
      lastDelta: provider.lastDelta,
      historyIndex: provider.historyIndex,
      canGoBack: provider.canGoBack,
    );
  }

  final Uri uri;
  final Object? historyState;
  final HistoryAction lastAction;
  final int? lastDelta;
  final int? historyIndex;
  final bool canGoBack;
}

class _UnrouterNavigationMachineTransition {
  const _UnrouterNavigationMachineTransition({
    required this.sequence,
    required this.recordedAt,
    required this.event,
    required this.before,
    required this.after,
  });

  final int sequence;
  final DateTime recordedAt;
  final UnrouterMachineEvent event;
  final _UnrouterNavigationMachineState before;
  final _UnrouterNavigationMachineState after;
}

typedef _UnrouterHistoryStateComposerFn =
    Object? Function({
      required Uri uri,
      required HistoryAction action,
      required Object? state,
    });

class _UnrouterNavigationMachine {
  _UnrouterNavigationMachine({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required _UnrouterNavigationState navigationState,
    required _UnrouterHistoryStateComposerFn composeHistoryState,
    required Uri? Function(int index, {required bool initialLocation})
    resolveShellBranchTarget,
    required Uri? Function() popShellBranchTarget,
    required void Function(_UnrouterNavigationMachineTransition transition)
    onTransition,
    this.transitionLimit = 128,
  }) : assert(
         transitionLimit > 0,
         'Unrouter navigation machine transitionLimit must be greater than zero.',
       ),
       _routeInformationProvider = routeInformationProvider,
       _navigationState = navigationState,
       _composeHistoryState = composeHistoryState,
       _resolveShellBranchTarget = resolveShellBranchTarget,
       _popShellBranchTarget = popShellBranchTarget,
       _onTransition = onTransition,
       _state = _UnrouterNavigationMachineState.fromProvider(
         routeInformationProvider,
       ) {
    _appendTransition(
      _UnrouterNavigationMachineTransition(
        sequence: _sequence++,
        recordedAt: DateTime.now(),
        event: UnrouterMachineEvent.initialized,
        before: _state,
        after: _state,
      ),
    );
  }

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final _UnrouterNavigationState _navigationState;
  final _UnrouterHistoryStateComposerFn _composeHistoryState;
  final Uri? Function(int index, {required bool initialLocation})
  _resolveShellBranchTarget;
  final Uri? Function() _popShellBranchTarget;
  final void Function(_UnrouterNavigationMachineTransition transition)
  _onTransition;
  final int transitionLimit;
  final List<_UnrouterNavigationMachineTransition> _transitions =
      <_UnrouterNavigationMachineTransition>[];

  int _sequence = 0;
  _UnrouterNavigationMachineState _state;

  _UnrouterNavigationMachineState get state => _state;

  List<_UnrouterNavigationMachineTransition> get transitions {
    return List<_UnrouterNavigationMachineTransition>.unmodifiable(
      _transitions,
    );
  }

  Object? dispatch(_UnrouterNavigationMachineEvent event) {
    final before = _state;
    final result = switch (event) {
      _UnrouterMachineGoUriEvent() => _dispatchGo(event),
      _UnrouterMachineReplaceUriEvent() => _dispatchReplace(event),
      _UnrouterMachinePushUriEvent() => _dispatchPush(event),
      _UnrouterMachinePopEvent() => _dispatchPop(event),
      _UnrouterMachinePopToUriEvent() => _dispatchPopToUri(event),
      _UnrouterMachineBackEvent() => _dispatchBack(),
      _UnrouterMachineForwardEvent() => _dispatchForward(),
      _UnrouterMachineGoDeltaEvent() => _dispatchGoDelta(event),
      _UnrouterMachineSwitchBranchEvent() => _dispatchSwitchBranch(event),
      _UnrouterMachinePopBranchEvent() => _dispatchPopBranch(event),
    };

    _state = _UnrouterNavigationMachineState.fromProvider(
      _routeInformationProvider,
    );
    _appendTransition(
      _UnrouterNavigationMachineTransition(
        sequence: _sequence++,
        recordedAt: DateTime.now(),
        event: event.event,
        before: before,
        after: _state,
      ),
    );
    return result;
  }

  Object? _dispatchGo(_UnrouterMachineGoUriEvent event) {
    final composedState = _composeHistoryState(
      uri: event.uri,
      action: HistoryAction.replace,
      state: event.state,
    );
    if (event.completePendingResult) {
      _navigationState.replaceAsPop(
        event.uri,
        state: composedState,
        result: event.result,
      );
      return null;
    }

    _routeInformationProvider.replace(event.uri, state: composedState);
    return null;
  }

  Object? _dispatchReplace(_UnrouterMachineReplaceUriEvent event) {
    final composedState = _composeHistoryState(
      uri: event.uri,
      action: HistoryAction.replace,
      state: event.state,
    );
    if (event.completePendingResult) {
      _navigationState.replaceAsPop(
        event.uri,
        state: composedState,
        result: event.result,
      );
      return null;
    }

    _routeInformationProvider.replace(event.uri, state: composedState);
    return null;
  }

  Object _dispatchPush(_UnrouterMachinePushUriEvent event) {
    final composedState = _composeHistoryState(
      uri: event.uri,
      action: HistoryAction.push,
      state: event.state,
    );
    return event.execute(_navigationState, composedState);
  }

  bool _dispatchPop(_UnrouterMachinePopEvent event) {
    return _navigationState.popWithResult<Object?>(event.result);
  }

  Object? _dispatchPopToUri(_UnrouterMachinePopToUriEvent event) {
    _navigationState.replaceAsPop(
      event.uri,
      state: _composeHistoryState(
        uri: event.uri,
        action: HistoryAction.replace,
        state: event.state,
      ),
      result: event.result,
    );
    return null;
  }

  bool _dispatchBack() {
    if (!_routeInformationProvider.canGoBack) {
      return false;
    }
    _routeInformationProvider.back();
    return true;
  }

  Object? _dispatchForward() {
    _routeInformationProvider.forward();
    return null;
  }

  Object? _dispatchGoDelta(_UnrouterMachineGoDeltaEvent event) {
    _routeInformationProvider.go(event.delta);
    return null;
  }

  bool _dispatchSwitchBranch(_UnrouterMachineSwitchBranchEvent event) {
    Uri? target;
    try {
      target = _resolveShellBranchTarget(
        event.index,
        initialLocation: event.initialLocation,
      );
    } on RangeError {
      return false;
    } on ArgumentError {
      return false;
    }
    if (target == null) {
      return false;
    }

    final composedState = _composeHistoryState(
      uri: target,
      action: HistoryAction.replace,
      state: null,
    );
    if (event.completePendingResult) {
      _navigationState.replaceAsPop(
        target,
        state: composedState,
        result: event.result,
      );
      return true;
    }

    _routeInformationProvider.replace(target, state: composedState);
    return true;
  }

  bool _dispatchPopBranch(_UnrouterMachinePopBranchEvent event) {
    final target = _popShellBranchTarget();
    if (target == null) {
      return false;
    }

    _navigationState.replaceAsPop(
      target,
      state: _composeHistoryState(
        uri: target,
        action: HistoryAction.replace,
        state: null,
      ),
      result: event.result,
    );
    return true;
  }

  void _appendTransition(_UnrouterNavigationMachineTransition transition) {
    _transitions.add(transition);
    _onTransition(transition);
    if (_transitions.length > transitionLimit) {
      final removeCount = _transitions.length - transitionLimit;
      _transitions.removeRange(0, removeCount);
    }
  }

  void dispose() {
    _transitions.clear();
  }
}

class _UnrouterNavigationDispatchAdapter {
  const _UnrouterNavigationDispatchAdapter(this._machine);

  final _UnrouterNavigationMachine _machine;

  T dispatch<T>(_UnrouterNavigationMachineEvent event) {
    final result = _machine.dispatch(event);
    return result as T;
  }
}

class _UnrouterMachineTransitionStore {
  _UnrouterMachineTransitionStore({required this.limit})
    : assert(
        limit > 0,
        'Unrouter machineTimelineLimit must be greater than zero.',
      );

  final int limit;
  final List<UnrouterMachineTransitionEntry> _entries =
      <UnrouterMachineTransitionEntry>[];
  int _sequence = 0;

  List<UnrouterMachineTransitionEntry> get entries {
    return List<UnrouterMachineTransitionEntry>.unmodifiable(_entries);
  }

  void add({
    required UnrouterMachineSource source,
    required UnrouterMachineEvent event,
    required UnrouterMachineState from,
    required UnrouterMachineState to,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    _entries.add(
      UnrouterMachineTransitionEntry(
        sequence: _sequence++,
        recordedAt: DateTime.now(),
        source: source,
        event: event,
        from: from,
        to: to,
        payload: Map<String, Object?>.unmodifiable(
          Map<String, Object?>.from(payload),
        ),
      ),
    );
    if (_entries.length > limit) {
      final removeCount = _entries.length - limit;
      _entries.removeRange(0, removeCount);
    }
  }

  void clear() {
    _entries.clear();
  }
}

class _UnrouterMachineReducer {
  const _UnrouterMachineReducer({
    required UnrouterMachineState Function() stateGetter,
    required _UnrouterMachineTransitionStore transitionStore,
  }) : _stateGetter = stateGetter,
       _transitionStore = transitionStore;

  final UnrouterMachineState Function() _stateGetter;
  final _UnrouterMachineTransitionStore _transitionStore;

  void reduce({
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
    final baseline = _stateGetter();
    _transitionStore.add(
      source: source,
      event: event,
      from: _resolveMachineState(
        baseline,
        explicit: from,
        uri: fromUri,
        resolution: fromResolution,
      ),
      to: _resolveMachineState(
        baseline,
        explicit: to,
        uri: toUri,
        resolution: toResolution,
      ),
      payload: payload,
    );
  }

  UnrouterMachineState _resolveMachineState(
    UnrouterMachineState baseline, {
    required UnrouterMachineState? explicit,
    Uri? uri,
    UnrouterResolutionState? resolution,
  }) {
    final source = explicit ?? baseline;
    return source.copyWith(
      uri: uri ?? source.uri,
      resolution: resolution ?? source.resolution,
    );
  }
}

class _UnrouterRouteMachineTransition {
  const _UnrouterRouteMachineTransition({
    required this.event,
    required this.requestUri,
    required this.generation,
    this.targetUri,
    this.toResolution,
    this.payload = const <String, Object?>{},
  });

  final UnrouterMachineEvent event;
  final Uri requestUri;
  final int generation;
  final Uri? targetUri;
  final UnrouterResolutionState? toResolution;
  final Map<String, Object?> payload;
}

abstract interface class _UnrouterRouteMachineDriver {
  Future<void> resolveRequest(Uri uri, {Object? state});

  void dispose();
}

class _UnrouterRouteMachineDriverImpl<Resolution, ResolutionType extends Enum>
    implements _UnrouterRouteMachineDriver {
  _UnrouterRouteMachineDriverImpl({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required Future<Resolution?> Function(
      Uri uri, {
      required bool Function() isCancelled,
    })
    resolver,
    required ResolutionType Function() currentResolutionType,
    required Uri Function() currentResolutionUri,
    required ResolutionType Function(Resolution resolution) resolutionTypeOf,
    required Uri Function(Resolution resolution) resolutionUriOf,
    required Uri? Function(Resolution resolution) redirectUriOf,
    required bool Function(ResolutionType type) isRedirect,
    required bool Function(ResolutionType type) isBlocked,
    required Resolution Function(Uri uri) buildUnmatchedResolution,
    required Resolution Function(Uri uri, Object error, StackTrace stackTrace)
    buildErrorResolution,
    required UnrouterResolutionState Function(ResolutionType type)
    mapResolutionType,
    required void Function(Resolution resolution) onCommit,
    required void Function(_UnrouterRouteMachineTransition transition)
    onTransition,
    required int maxRedirectHops,
    required RedirectLoopPolicy redirectLoopPolicy,
    required RedirectDiagnosticsCallback? onRedirectDiagnostics,
  }) : _routeInformationProvider = routeInformationProvider,
       _resolver = resolver,
       _currentResolutionType = currentResolutionType,
       _currentResolutionUri = currentResolutionUri,
       _resolutionTypeOf = resolutionTypeOf,
       _resolutionUriOf = resolutionUriOf,
       _redirectUriOf = redirectUriOf,
       _isRedirect = isRedirect,
       _isBlocked = isBlocked,
       _buildUnmatchedResolution = buildUnmatchedResolution,
       _buildErrorResolution = buildErrorResolution,
       _mapResolutionType = mapResolutionType,
       _onCommit = onCommit,
       _onTransition = onTransition,
       _maxRedirectHops = maxRedirectHops,
       _redirectLoopPolicy = redirectLoopPolicy,
       _onRedirectDiagnostics = onRedirectDiagnostics;

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final Future<Resolution?> Function(
    Uri uri, {
    required bool Function() isCancelled,
  })
  _resolver;
  final ResolutionType Function() _currentResolutionType;
  final Uri Function() _currentResolutionUri;
  final ResolutionType Function(Resolution resolution) _resolutionTypeOf;
  final Uri Function(Resolution resolution) _resolutionUriOf;
  final Uri? Function(Resolution resolution) _redirectUriOf;
  final bool Function(ResolutionType type) _isRedirect;
  final bool Function(ResolutionType type) _isBlocked;
  final Resolution Function(Uri uri) _buildUnmatchedResolution;
  final Resolution Function(Uri uri, Object error, StackTrace stackTrace)
  _buildErrorResolution;
  final UnrouterResolutionState Function(ResolutionType type)
  _mapResolutionType;
  final void Function(Resolution resolution) _onCommit;
  final void Function(_UnrouterRouteMachineTransition transition) _onTransition;
  final int _maxRedirectHops;
  final RedirectLoopPolicy _redirectLoopPolicy;
  final RedirectDiagnosticsCallback? _onRedirectDiagnostics;

  int _generation = 0;
  bool _hasCommittedResolution = false;
  Uri? _resolvingUri;
  Future<void>? _resolvingFuture;
  _RedirectChainState? _redirectChain;

  @override
  Future<void> resolveRequest(Uri uri, {Object? state}) {
    final generationSnapshot = _generation;
    _emit(
      event: UnrouterMachineEvent.request,
      requestUri: uri,
      generation: generationSnapshot,
      payload: <String, Object?>{'hasState': state != null},
    );
    _prepareRedirectChain(uri, generation: generationSnapshot);

    final activeUri = _resolvingUri;
    final activeFuture = _resolvingFuture;
    if (activeUri != null &&
        activeFuture != null &&
        _isSameUri(activeUri, uri)) {
      _emit(
        event: UnrouterMachineEvent.requestDeduplicated,
        requestUri: uri,
        generation: generationSnapshot,
      );
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

  @override
  void dispose() {
    _resolvingUri = null;
    _resolvingFuture = null;
    _redirectChain = null;
  }

  Future<void> _resolve(Uri uri, {Object? state}) async {
    final generation = ++_generation;
    final previousType = _currentResolutionType();
    final previousUri = _currentResolutionUri();
    _emit(
      event: UnrouterMachineEvent.resolveStart,
      requestUri: uri,
      generation: generation,
      payload: <String, Object?>{'previousResolution': previousType.name},
    );

    bool isCancelled() {
      return generation != _generation;
    }

    final nextResolution = await _resolver(uri, isCancelled: isCancelled);

    if (nextResolution == null) {
      _emit(
        event: UnrouterMachineEvent.resolveCancelled,
        requestUri: uri,
        generation: generation,
      );
      return;
    }

    if (isCancelled()) {
      _emit(
        event: UnrouterMachineEvent.resolveCancelledSignal,
        requestUri: uri,
        generation: generation,
      );
      return;
    }

    final nextType = _resolutionTypeOf(nextResolution);
    final nextUri = _resolutionUriOf(nextResolution);
    _emit(
      event: UnrouterMachineEvent.resolveFinished,
      requestUri: uri,
      generation: generation,
      targetUri: nextUri,
      toResolution: _mapResolutionType(nextType),
    );

    if (_isRedirect(nextType)) {
      final redirectUri = _redirectUriOf(nextResolution);
      if (redirectUri == null) {
        _clearRedirectChain(generation: generation, requestUri: uri);
        _emit(
          event: UnrouterMachineEvent.redirectMissingTarget,
          requestUri: uri,
          generation: generation,
          toResolution: UnrouterResolutionState.error,
        );
        _commit(
          _buildErrorResolution(
            uri,
            StateError('Redirect resolution is missing target uri.'),
            StackTrace.current,
          ),
          generation: generation,
          requestUri: uri,
        );
        return;
      }

      final diagnostics = _registerRedirect(
        uri: uri,
        redirectUri: redirectUri,
        generation: generation,
      );
      if (diagnostics != null) {
        _reportRedirectDiagnostics(diagnostics);
        _clearRedirectChain(generation: generation, requestUri: uri);
        _emit(
          event: UnrouterMachineEvent.redirectDiagnosticsError,
          requestUri: uri,
          generation: generation,
          targetUri: redirectUri,
          toResolution: UnrouterResolutionState.error,
          payload: <String, Object?>{
            'reason': diagnostics.reason.name,
            'hop': diagnostics.hop,
            'maxHops': diagnostics.maxHops,
          },
        );
        _commit(
          _buildErrorResolution(
            uri,
            StateError(_buildRedirectErrorMessage(diagnostics)),
            StackTrace.current,
          ),
          generation: generation,
          requestUri: uri,
        );
        return;
      }

      _emit(
        event: UnrouterMachineEvent.redirectAccepted,
        requestUri: uri,
        generation: generation,
        targetUri: redirectUri,
        toResolution: UnrouterResolutionState.redirect,
      );
      _routeInformationProvider.replace(redirectUri, state: state);
      return;
    }

    if (_isBlocked(nextType)) {
      _clearRedirectChain(generation: generation, requestUri: uri);
      if (_hasCommittedResolution) {
        final fallbackUri = previousUri;
        if (!_isSameUri(uri, fallbackUri)) {
          _emit(
            event: UnrouterMachineEvent.blockedFallback,
            requestUri: uri,
            generation: generation,
            targetUri: fallbackUri,
            toResolution: UnrouterResolutionState.blocked,
          );
          _routeInformationProvider.replace(fallbackUri, state: state);
        } else {
          _emit(
            event: UnrouterMachineEvent.blockedNoop,
            requestUri: uri,
            generation: generation,
            targetUri: fallbackUri,
            toResolution: UnrouterResolutionState.blocked,
          );
        }
        return;
      }

      _emit(
        event: UnrouterMachineEvent.blockedUnmatched,
        requestUri: uri,
        generation: generation,
        toResolution: UnrouterResolutionState.unmatched,
      );
      _commit(
        _buildUnmatchedResolution(uri),
        generation: generation,
        requestUri: uri,
      );
      return;
    }

    _commit(nextResolution, generation: generation, requestUri: uri);
  }

  void _commit(
    Resolution resolution, {
    required int generation,
    required Uri requestUri,
  }) {
    _clearRedirectChain(generation: generation, requestUri: requestUri);
    _hasCommittedResolution = true;
    final type = _resolutionTypeOf(resolution);
    _emit(
      event: UnrouterMachineEvent.commit,
      requestUri: requestUri,
      generation: generation,
      targetUri: _resolutionUriOf(resolution),
      toResolution: _mapResolutionType(type),
    );
    _onCommit(resolution);
  }

  void _prepareRedirectChain(Uri incomingUri, {required int generation}) {
    final chain = _redirectChain;
    if (chain == null) {
      return;
    }

    final expected = chain.expectedNextUri;
    if (expected != null && _isSameUri(expected, incomingUri)) {
      chain.expectedNextUri = null;
      return;
    }

    _clearRedirectChain(generation: generation, requestUri: incomingUri);
  }

  RedirectDiagnostics? _registerRedirect({
    required Uri uri,
    required Uri redirectUri,
    required int generation,
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
    if (chain.hops > _maxRedirectHops) {
      return RedirectDiagnostics(
        reason: RedirectDiagnosticsReason.maxHopsExceeded,
        currentUri: uri,
        redirectUri: redirectUri,
        trail: trailCandidate,
        hop: chain.hops,
        maxHops: _maxRedirectHops,
        loopPolicy: _redirectLoopPolicy,
      );
    }

    final redirectKey = redirectUri.toString();
    if (_redirectLoopPolicy == RedirectLoopPolicy.error &&
        chain.seen.contains(redirectKey)) {
      return RedirectDiagnostics(
        reason: RedirectDiagnosticsReason.loopDetected,
        currentUri: uri,
        redirectUri: redirectUri,
        trail: trailCandidate,
        hop: chain.hops,
        maxHops: _maxRedirectHops,
        loopPolicy: _redirectLoopPolicy,
      );
    }

    chain.acceptRedirect(redirectUri);
    _emit(
      event: UnrouterMachineEvent.redirectRegistered,
      requestUri: uri,
      generation: generation,
      targetUri: redirectUri,
      toResolution: UnrouterResolutionState.redirect,
      payload: <String, Object?>{
        'hop': chain.hops,
        'maxHops': _maxRedirectHops,
      },
    );
    return null;
  }

  void _clearRedirectChain({required int generation, required Uri requestUri}) {
    if (_redirectChain == null) {
      return;
    }
    _emit(
      event: UnrouterMachineEvent.redirectChainCleared,
      requestUri: requestUri,
      generation: generation,
    );
    _redirectChain = null;
  }

  void _reportRedirectDiagnostics(RedirectDiagnostics diagnostics) {
    final callback = _onRedirectDiagnostics;
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

  void _emit({
    required UnrouterMachineEvent event,
    required Uri requestUri,
    required int generation,
    Uri? targetUri,
    UnrouterResolutionState? toResolution,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    _onTransition(
      _UnrouterRouteMachineTransition(
        event: event,
        requestUri: requestUri,
        generation: generation,
        targetUri: targetUri,
        toResolution: toResolution,
        payload: payload,
      ),
    );
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
