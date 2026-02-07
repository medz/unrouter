part of 'navigation.dart';

typedef _UnrouterHistoryStateComposerFn =
    Object? Function({
      required Uri uri,
      required HistoryAction action,
      required Object? state,
    });

class _UnrouterNavigationRuntime {
  _UnrouterNavigationRuntime({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required _UnrouterNavigationState navigationState,
    required _UnrouterHistoryStateComposerFn composeHistoryState,
    required Uri? Function(int index, {required bool initialLocation})
    resolveShellBranchTarget,
    required Uri? Function() popShellBranchTarget,
  }) : _routeInformationProvider = routeInformationProvider,
       _navigationState = navigationState,
       _composeHistoryState = composeHistoryState,
       _resolveShellBranchTarget = resolveShellBranchTarget,
       _popShellBranchTarget = popShellBranchTarget;

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final _UnrouterNavigationState _navigationState;
  final _UnrouterHistoryStateComposerFn _composeHistoryState;
  final Uri? Function(int index, {required bool initialLocation})
  _resolveShellBranchTarget;
  final Uri? Function() _popShellBranchTarget;

  void goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    final composedState = _composeHistoryState(
      uri: uri,
      action: HistoryAction.replace,
      state: state,
    );
    if (completePendingResult) {
      _navigationState.replaceAsPop(uri, state: composedState, result: result);
      return;
    }

    _routeInformationProvider.replace(uri, state: composedState);
  }

  void replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    final composedState = _composeHistoryState(
      uri: uri,
      action: HistoryAction.replace,
      state: state,
    );
    if (completePendingResult) {
      _navigationState.replaceAsPop(uri, state: composedState, result: result);
      return;
    }

    _routeInformationProvider.replace(uri, state: composedState);
  }

  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    final composedState = _composeHistoryState(
      uri: uri,
      action: HistoryAction.push,
      state: state,
    );
    return _navigationState.pushForResult<T>(uri, state: composedState);
  }

  bool pop([Object? result]) {
    return _navigationState.popWithResult<Object?>(result);
  }

  void popToUri(Uri uri, {Object? state, Object? result}) {
    _navigationState.replaceAsPop(
      uri,
      state: _composeHistoryState(
        uri: uri,
        action: HistoryAction.replace,
        state: state,
      ),
      result: result,
    );
  }

  bool back() {
    if (!_routeInformationProvider.canGoBack) {
      return false;
    }
    _routeInformationProvider.back();
    return true;
  }

  void forward() {
    _routeInformationProvider.forward();
  }

  void goDelta(int delta) {
    _routeInformationProvider.go(delta);
  }

  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    Uri? target;
    try {
      target = _resolveShellBranchTarget(
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

    final composedState = _composeHistoryState(
      uri: target,
      action: HistoryAction.replace,
      state: null,
    );
    if (completePendingResult) {
      _navigationState.replaceAsPop(
        target,
        state: composedState,
        result: result,
      );
      return true;
    }

    _routeInformationProvider.replace(target, state: composedState);
    return true;
  }

  bool popBranch([Object? result]) {
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
      result: result,
    );
    return true;
  }

  void dispose() {}
}

abstract interface class _UnrouterRouteRuntimeDriver {
  Future<void> resolveRequest(Uri uri, {Object? state});

  void dispose();
}

class _UnrouterRouteRuntimeDriverImpl<Resolution, ResolutionType extends Enum>
    implements _UnrouterRouteRuntimeDriver {
  _UnrouterRouteRuntimeDriverImpl({
    required UnrouterRouteInformationProvider routeInformationProvider,
    required Future<Resolution?> Function(
      Uri uri, {
      required bool Function() isCancelled,
    })
    resolver,
    required Uri Function() currentResolutionUri,
    required ResolutionType Function(Resolution resolution) resolutionTypeOf,
    required Uri? Function(Resolution resolution) redirectUriOf,
    required bool Function(ResolutionType type) isRedirect,
    required bool Function(ResolutionType type) isBlocked,
    required Resolution Function(Uri uri) buildUnmatchedResolution,
    required Resolution Function(Uri uri, Object error, StackTrace stackTrace)
    buildErrorResolution,
    required void Function(Resolution resolution) onCommit,
    required int maxRedirectHops,
    required RedirectLoopPolicy redirectLoopPolicy,
    required RedirectDiagnosticsCallback? onRedirectDiagnostics,
  }) : _routeInformationProvider = routeInformationProvider,
       _resolver = resolver,
       _currentResolutionUri = currentResolutionUri,
       _resolutionTypeOf = resolutionTypeOf,
       _redirectUriOf = redirectUriOf,
       _isRedirect = isRedirect,
       _isBlocked = isBlocked,
       _buildUnmatchedResolution = buildUnmatchedResolution,
       _buildErrorResolution = buildErrorResolution,
       _onCommit = onCommit,
       _maxRedirectHops = maxRedirectHops,
       _redirectLoopPolicy = redirectLoopPolicy,
       _onRedirectDiagnostics = onRedirectDiagnostics;

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final Future<Resolution?> Function(
    Uri uri, {
    required bool Function() isCancelled,
  })
  _resolver;
  final Uri Function() _currentResolutionUri;
  final ResolutionType Function(Resolution resolution) _resolutionTypeOf;
  final Uri? Function(Resolution resolution) _redirectUriOf;
  final bool Function(ResolutionType type) _isRedirect;
  final bool Function(ResolutionType type) _isBlocked;
  final Resolution Function(Uri uri) _buildUnmatchedResolution;
  final Resolution Function(Uri uri, Object error, StackTrace stackTrace)
  _buildErrorResolution;
  final void Function(Resolution resolution) _onCommit;
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
    _prepareRedirectChain(uri);

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

  @override
  void dispose() {
    _resolvingUri = null;
    _resolvingFuture = null;
    _redirectChain = null;
  }

  Future<void> _resolve(Uri uri, {Object? state}) async {
    final generation = ++_generation;
    final previousUri = _currentResolutionUri();

    bool isCancelled() {
      return generation != _generation;
    }

    final nextResolution = await _resolver(uri, isCancelled: isCancelled);

    if (nextResolution == null || isCancelled()) {
      return;
    }

    final nextType = _resolutionTypeOf(nextResolution);

    if (_isRedirect(nextType)) {
      final redirectUri = _redirectUriOf(nextResolution);
      if (redirectUri == null) {
        _clearRedirectChain();
        _commit(
          _buildErrorResolution(
            uri,
            StateError('Redirect resolution is missing target uri.'),
            StackTrace.current,
          ),
        );
        return;
      }

      final diagnostics = _registerRedirect(uri: uri, redirectUri: redirectUri);
      if (diagnostics != null) {
        _reportRedirectDiagnostics(diagnostics);
        _clearRedirectChain();
        _commit(
          _buildErrorResolution(
            uri,
            StateError(_buildRedirectErrorMessage(diagnostics)),
            StackTrace.current,
          ),
        );
        return;
      }

      _routeInformationProvider.replace(redirectUri, state: state);
      return;
    }

    if (_isBlocked(nextType)) {
      _clearRedirectChain();
      if (_hasCommittedResolution) {
        final fallbackUri = previousUri;
        if (!_isSameUri(uri, fallbackUri)) {
          _routeInformationProvider.replace(fallbackUri, state: state);
        }
        return;
      }

      _commit(_buildUnmatchedResolution(uri));
      return;
    }

    _commit(nextResolution);
  }

  void _commit(Resolution resolution) {
    _clearRedirectChain();
    _hasCommittedResolution = true;
    _onCommit(resolution);
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
    return null;
  }

  void _clearRedirectChain() {
    if (_redirectChain == null) {
      return;
    }
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
