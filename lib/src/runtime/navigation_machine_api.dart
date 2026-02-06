part of 'navigation.dart';

class UnrouterMachine<R extends RouteData> {
  const UnrouterMachine._(this._host);

  final _UnrouterMachineHost<R> _host;

  UnrouterMachineState get state => _host.machineState;

  List<UnrouterMachineTransitionEntry> get timeline {
    return _host.machineTimeline;
  }

  List<UnrouterMachineTypedTransition> get typedTimeline {
    return _host.machineTimeline
        .map((entry) => entry.typed)
        .toList(growable: false);
  }

  T dispatchTyped<T>(UnrouterMachineCommand<T> command) {
    return _host.dispatchMachineCommand<T>(command);
  }

  Object? dispatch(UnrouterMachineCommand<dynamic> command) {
    return _host.dispatchMachineCommand(command);
  }

  T dispatchAction<T>(UnrouterMachineAction<T> action) {
    return dispatchTyped(action.toCommand());
  }

  Object? dispatchActionUntyped(UnrouterMachineAction<dynamic> action) {
    return dispatch(action.toCommand());
  }

  UnrouterMachineActionEnvelope<T> dispatchActionEnvelope<T>(
    UnrouterMachineAction<T> action,
  ) {
    final value = dispatchAction<T>(action);
    final envelope = _resolveActionEnvelope(action.event, value);
    _host.recordActionEnvelope(envelope);
    _recordDeferredSettlement(action.event, envelope);
    return envelope;
  }

  UnrouterMachineActionEnvelope<Object?> dispatchActionEnvelopeUntyped(
    UnrouterMachineAction<dynamic> action,
  ) {
    final value = dispatchActionUntyped(action);
    final envelope = _resolveActionEnvelope<Object?>(action.event, value);
    _host.recordActionEnvelope(envelope);
    _recordDeferredSettlement(action.event, envelope);
    return envelope;
  }

  UnrouterMachineActionEnvelope<T> _resolveActionEnvelope<T>(
    UnrouterMachineEvent event,
    T value,
  ) {
    if (value is Future<Object?>) {
      return UnrouterMachineActionEnvelope<T>.deferred(
        event: event,
        value: value,
      );
    }
    if (value is bool && value == false) {
      return UnrouterMachineActionEnvelope<T>.rejected(
        event: event,
        value: value,
        failure: _resolveRejectFailure(event),
      );
    }
    if (value == null) {
      return UnrouterMachineActionEnvelope<T>.accepted(event: event);
    }
    return UnrouterMachineActionEnvelope<T>.completed(
      event: event,
      value: value,
    );
  }

  UnrouterMachineActionRejectCode _resolveRejectCode(
    UnrouterMachineEvent event,
  ) {
    switch (event) {
      case UnrouterMachineEvent.back:
        return UnrouterMachineActionRejectCode.noBackHistory;
      case UnrouterMachineEvent.pop:
        return UnrouterMachineActionRejectCode.popRejected;
      case UnrouterMachineEvent.switchBranch:
        return UnrouterMachineActionRejectCode.branchUnavailable;
      case UnrouterMachineEvent.popBranch:
        return UnrouterMachineActionRejectCode.branchEmpty;
      case UnrouterMachineEvent.initialized:
      case UnrouterMachineEvent.controllerRouteMachineConfigured:
      case UnrouterMachineEvent.controllerHistoryStateComposerChanged:
      case UnrouterMachineEvent.controllerShellResolversChanged:
      case UnrouterMachineEvent.controllerDisposed:
      case UnrouterMachineEvent.actionEnvelope:
      case UnrouterMachineEvent.goUri:
      case UnrouterMachineEvent.replaceUri:
      case UnrouterMachineEvent.pushUri:
      case UnrouterMachineEvent.popToUri:
      case UnrouterMachineEvent.forward:
      case UnrouterMachineEvent.goDelta:
      case UnrouterMachineEvent.request:
      case UnrouterMachineEvent.requestDeduplicated:
      case UnrouterMachineEvent.resolveStart:
      case UnrouterMachineEvent.resolveCancelled:
      case UnrouterMachineEvent.resolveCancelledSignal:
      case UnrouterMachineEvent.resolveFinished:
      case UnrouterMachineEvent.redirectMissingTarget:
      case UnrouterMachineEvent.redirectDiagnosticsError:
      case UnrouterMachineEvent.redirectAccepted:
      case UnrouterMachineEvent.blockedFallback:
      case UnrouterMachineEvent.blockedNoop:
      case UnrouterMachineEvent.blockedUnmatched:
      case UnrouterMachineEvent.commit:
      case UnrouterMachineEvent.redirectRegistered:
      case UnrouterMachineEvent.redirectChainCleared:
        return UnrouterMachineActionRejectCode.unknown;
    }
  }

  String _resolveRejectReason(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return 'Machine command returned false.';
      case UnrouterMachineActionRejectCode.noBackHistory:
        return 'No history entry is available for back navigation.';
      case UnrouterMachineActionRejectCode.popRejected:
        return 'Pop was rejected because no pending push result can be completed.';
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return 'Target shell branch is unavailable.';
      case UnrouterMachineActionRejectCode.branchEmpty:
        return 'Active shell branch has no pop target.';
      case UnrouterMachineActionRejectCode.deferredError:
        return 'Deferred action future completed with an error.';
    }
  }

  UnrouterMachineActionFailure _resolveRejectFailure(
    UnrouterMachineEvent event,
  ) {
    final code = _resolveRejectCode(event);
    return UnrouterMachineActionFailure(
      code: code,
      message: _resolveRejectReason(code),
      category: _resolveRejectCategory(code),
      retryable: _resolveRejectRetryable(code),
    );
  }

  UnrouterMachineActionFailureCategory _resolveRejectCategory(
    UnrouterMachineActionRejectCode code,
  ) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return UnrouterMachineActionFailureCategory.unknown;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
        return UnrouterMachineActionFailureCategory.history;
      case UnrouterMachineActionRejectCode.branchUnavailable:
      case UnrouterMachineActionRejectCode.branchEmpty:
        return UnrouterMachineActionFailureCategory.shell;
      case UnrouterMachineActionRejectCode.deferredError:
        return UnrouterMachineActionFailureCategory.asynchronous;
    }
  }

  bool _resolveRejectRetryable(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return false;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
      case UnrouterMachineActionRejectCode.branchEmpty:
      case UnrouterMachineActionRejectCode.deferredError:
        return true;
    }
  }

  void _recordDeferredSettlement<T>(
    UnrouterMachineEvent event,
    UnrouterMachineActionEnvelope<T> envelope,
  ) {
    if (!envelope.isDeferred) {
      return;
    }
    final deferred = envelope.value;
    if (deferred is! Future<Object?>) {
      return;
    }
    final startedAt = DateTime.now();
    unawaited(
      deferred.then(
        (value) {
          _host.recordActionEnvelope<Object?>(
            UnrouterMachineActionEnvelope<Object?>.completed(
              event: event,
              value: value,
            ),
            phase: 'settled',
            metadata: <String, Object?>{
              'deferredOutcome': 'completed',
              'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
            },
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          final failure = UnrouterMachineActionFailure(
            code: UnrouterMachineActionRejectCode.deferredError,
            message: '$error',
            category: UnrouterMachineActionFailureCategory.asynchronous,
            retryable: true,
            metadata: <String, Object?>{
              'errorType': error.runtimeType.toString(),
              'stackTrace': stackTrace.toString(),
            },
          );
          _host.recordActionEnvelope<Object?>(
            UnrouterMachineActionEnvelope<Object?>.rejected(
              event: event,
              failure: failure,
            ),
            phase: 'settled',
            metadata: <String, Object?>{
              'deferredOutcome': 'rejected',
              'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
              'error': error.toString(),
              'errorType': error.runtimeType.toString(),
            },
          );
        },
      ),
    );
  }
}
