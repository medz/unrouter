part of 'navigation.dart';

/// Lifecycle/configuration methods exposed on [UnrouterController].
extension UnrouterControllerLifecycleMethods<R extends RouteData>
    on UnrouterController<R> {
  /// Sets or clears custom history state composer.
  void setHistoryStateComposer(UnrouterHistoryStateComposer? composer) {
    _historyStateComposer = composer;
  }

  /// Configures internal route runtime used by delegate resolution.
  void configureRouteRuntime<Resolution, ResolutionType extends Enum>({
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
    RedirectDiagnosticsCallback? onRedirectDiagnostics,
  }) {
    _routeRuntime?.dispose();
    _routeRuntime = _UnrouterRouteRuntimeDriverImpl<Resolution, ResolutionType>(
      routeInformationProvider: _routeInformationProvider,
      resolver: resolver,
      currentResolutionUri: currentResolutionUri,
      resolutionTypeOf: resolutionTypeOf,
      redirectUriOf: redirectUriOf,
      isRedirect: isRedirect,
      isBlocked: isBlocked,
      buildUnmatchedResolution: buildUnmatchedResolution,
      buildErrorResolution: buildErrorResolution,
      onCommit: onCommit,
      maxRedirectHops: maxRedirectHops,
      redirectLoopPolicy: redirectLoopPolicy,
      onRedirectDiagnostics: onRedirectDiagnostics,
    );
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
    _shellBranchTargetResolver =
        UnrouterController._defaultShellBranchTargetResolver;
    _shellBranchPopResolver = UnrouterController._defaultShellBranchPopResolver;
  }

  /// Clears custom history state composer.
  void clearHistoryStateComposer() {
    setHistoryStateComposer(null);
  }

  /// Dispatches a route-resolution request through the internal route runtime.
  Future<void> dispatchRouteRequest(Uri uri, {Object? state}) {
    return _dispatchRouteRequest(uri, state: state);
  }

  /// Forces current state publication to listeners.
  void publishState() {
    _stateStore.refresh();
  }

  /// Clears bounded state timeline.
  void clearStateTimeline() {
    _stateStore.clearTimeline();
  }

  /// Disposes controller runtime resources.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _historyStateComposer = null;
    _routeRuntime?.dispose();
    _routeRuntime = null;
    _shellBranchTargetResolver =
        UnrouterController._defaultShellBranchTargetResolver;
    _shellBranchPopResolver = UnrouterController._defaultShellBranchPopResolver;
    _navigationRuntime.dispose();
    _navigationState.dispose();
    _stateStore.dispose();
  }
}
