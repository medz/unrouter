part of 'navigation.dart';

extension UnrouterControllerLifecycleMethods<R extends RouteData>
    on UnrouterController<R> {
  void setHistoryStateComposer(UnrouterHistoryStateComposer? composer) {
    _historyStateComposer = composer;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerHistoryStateComposerChanged,
      payload: <String, Object?>{'enabled': composer != null},
    );
  }

  void configureRouteMachine<Resolution, ResolutionType extends Enum>({
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
    required int maxRedirectHops,
    required RedirectLoopPolicy redirectLoopPolicy,
    RedirectDiagnosticsCallback? onRedirectDiagnostics,
  }) {
    final hadRouteMachine = _routeMachine != null;
    _routeMachine?.dispose();
    _routeMachine = _UnrouterRouteMachineDriverImpl<Resolution, ResolutionType>(
      routeInformationProvider: _routeInformationProvider,
      resolver: resolver,
      currentResolutionType: currentResolutionType,
      currentResolutionUri: currentResolutionUri,
      resolutionTypeOf: resolutionTypeOf,
      resolutionUriOf: resolutionUriOf,
      redirectUriOf: redirectUriOf,
      isRedirect: isRedirect,
      isBlocked: isBlocked,
      buildUnmatchedResolution: buildUnmatchedResolution,
      buildErrorResolution: buildErrorResolution,
      mapResolutionType: mapResolutionType,
      onCommit: onCommit,
      onTransition: _recordRouteMachineTransition,
      maxRedirectHops: maxRedirectHops,
      redirectLoopPolicy: redirectLoopPolicy,
      onRedirectDiagnostics: onRedirectDiagnostics,
    );
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerRouteMachineConfigured,
      payload: <String, Object?>{
        'hadRouteMachine': hadRouteMachine,
        'maxRedirectHops': maxRedirectHops,
        'redirectLoopPolicy': redirectLoopPolicy.name,
        'redirectDiagnosticsEnabled': onRedirectDiagnostics != null,
      },
    );
  }

  void setShellBranchResolvers({
    required Uri? Function(int index, {required bool initialLocation})
    resolveTarget,
    required Uri? Function() popTarget,
  }) {
    _shellBranchTargetResolver = resolveTarget;
    _shellBranchPopResolver = popTarget;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerShellResolversChanged,
      payload: const <String, Object?>{'enabled': true},
    );
  }

  void clearShellBranchResolvers() {
    final hadCustomResolvers = _hasCustomShellBranchResolvers;
    _shellBranchTargetResolver =
        UnrouterController._defaultShellBranchTargetResolver;
    _shellBranchPopResolver = UnrouterController._defaultShellBranchPopResolver;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerShellResolversChanged,
      payload: <String, Object?>{
        'enabled': false,
        'hadCustomShellResolvers': hadCustomResolvers,
      },
    );
  }

  void clearHistoryStateComposer() {
    setHistoryStateComposer(null);
  }

  void publishState() {
    _stateStore.refresh();
  }

  void clearStateTimeline() {
    _stateStore.clearTimeline();
  }

  void clearMachineTimeline() {
    _machineStore.clear();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _recordControllerLifecycleTransition(
      UnrouterMachineEvent.controllerDisposed,
      payload: <String, Object?>{
        'hadRouteMachine': _routeMachine != null,
        'hadHistoryStateComposer': _historyStateComposer != null,
        'hadCustomShellResolvers': _hasCustomShellBranchResolvers,
      },
    );
    _historyStateComposer = null;
    _routeMachine?.dispose();
    _routeMachine = null;
    _shellBranchTargetResolver =
        UnrouterController._defaultShellBranchTargetResolver;
    _shellBranchPopResolver = UnrouterController._defaultShellBranchPopResolver;
    _navigationMachine.dispose();
    _navigationState.dispose();
    _stateStore.dispose();
  }
}
