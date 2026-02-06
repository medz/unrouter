import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/devtools.dart';
import 'package:unstory/unstory.dart';

void main() {
  group('Performance budgets', () {
    test('typed machine transition projection stays within scale budgets', () {
      final scenarios = <_PerformanceScenario>[
        _PerformanceScenario(
          entryCount: 400,
          rounds: 40,
          maxElapsed: const Duration(seconds: 3),
        ),
        _PerformanceScenario(
          entryCount: 1200,
          rounds: 25,
          maxElapsed: const Duration(seconds: 5),
        ),
        _PerformanceScenario(
          entryCount: 2400,
          rounds: 12,
          maxElapsed: const Duration(seconds: 6),
        ),
      ];

      for (final scenario in scenarios) {
        final entries = List<UnrouterMachineTransitionEntry>.generate(
          scenario.entryCount,
          _typedEntryForIndex,
        );
        final stopwatch = Stopwatch()..start();
        var checksum = 0;
        for (var round = 0; round < scenario.rounds; round++) {
          for (final entry in entries) {
            final typed = entry.typed;
            checksum += typed.sequence;
            final payloadChecksum = switch (typed.payload.kind) {
              UnrouterMachineTypedPayloadKind.actionEnvelope =>
                (typed.payload as UnrouterMachineActionEnvelopeTypedPayload)
                        .failure
                        ?.message
                        .length ??
                    0,
              UnrouterMachineTypedPayloadKind.navigation =>
                (typed.payload as UnrouterMachineNavigationTypedPayload)
                        .afterHistoryIndex ??
                    0,
              UnrouterMachineTypedPayloadKind.route =>
                (typed.payload as UnrouterMachineRouteTypedPayload)
                        .generation ??
                    0,
              UnrouterMachineTypedPayloadKind.controller =>
                (typed.payload as UnrouterMachineControllerTypedPayload)
                        .historyIndex ??
                    0,
              UnrouterMachineTypedPayloadKind.generic => 1,
            };
            checksum += payloadChecksum;
          }
        }
        stopwatch.stop();
        expect(
          checksum,
          greaterThan(0),
          reason: 'checksum must be non-zero for ${scenario.entryCount}',
        );
        expect(
          stopwatch.elapsed,
          lessThan(scenario.maxElapsed),
          reason:
              'typed projection exceeded budget for entryCount=${scenario.entryCount}',
        );
      }
    });

    test(
      'replay action-envelope compatibility validation stays within scale budgets',
      () {
        final scenarios = <_PerformanceScenario>[
          _PerformanceScenario(
            entryCount: 300,
            rounds: 30,
            maxElapsed: const Duration(seconds: 3),
          ),
          _PerformanceScenario(
            entryCount: 900,
            rounds: 20,
            maxElapsed: const Duration(seconds: 6),
          ),
          _PerformanceScenario(
            entryCount: 1800,
            rounds: 10,
            maxElapsed: const Duration(seconds: 6),
          ),
        ];

        for (final scenario in scenarios) {
          final store = UnrouterInspectorReplayStore();
          final startAt = DateTime(2026, 2, 6, 14, 0, 0);
          for (var i = 0; i < scenario.entryCount; i++) {
            store.add(
              UnrouterInspectorEmission(
                reason: UnrouterInspectorEmissionReason.manual,
                recordedAt: startAt.add(Duration(milliseconds: i)),
                report: <String, Object?>{
                  'machineTimelineTail': <Object?>[
                    _actionEnvelopeEntryForIndex(i).toJson(),
                  ],
                },
              ),
            );
          }

          final stopwatch = Stopwatch()..start();
          late UnrouterInspectorReplayValidationResult result;
          for (var round = 0; round < scenario.rounds; round++) {
            result = store.validateActionEnvelopeCompatibility();
          }
          stopwatch.stop();

          expect(result.errorCount, 0);
          expect(result.warningCount, 0);
          expect(
            stopwatch.elapsed,
            lessThan(scenario.maxElapsed),
            reason:
                'compat validation exceeded budget for entryCount=${scenario.entryCount}',
          );
          store.dispose();
        }
      },
    );
  });
}

class _PerformanceScenario {
  const _PerformanceScenario({
    required this.entryCount,
    required this.rounds,
    required this.maxElapsed,
  });

  final int entryCount;
  final int rounds;
  final Duration maxElapsed;
}

UnrouterMachineTransitionEntry _typedEntryForIndex(int index) {
  final selector = index % 3;
  if (selector == 0) {
    return _actionEnvelopeEntryForIndex(index);
  }
  if (selector == 1) {
    return UnrouterMachineTransitionEntry(
      sequence: index + 1,
      recordedAt: DateTime(
        2026,
        2,
        6,
        14,
        30,
        0,
      ).add(Duration(milliseconds: index)),
      source: UnrouterMachineSource.route,
      event: UnrouterMachineEvent.commit,
      from: _stateForIndex(index),
      to: _stateForIndex(index + 1),
      payload: <String, Object?>{
        'requestUri': '/users/${(index % 50) + 1}',
        'hop': index % 8,
      },
    );
  }
  return UnrouterMachineTransitionEntry(
    sequence: index + 1,
    recordedAt: DateTime(
      2026,
      2,
      6,
      14,
      45,
      0,
    ).add(Duration(milliseconds: index)),
    source: UnrouterMachineSource.controller,
    event: UnrouterMachineEvent.initialized,
    from: _stateForIndex(index),
    to: _stateForIndex(index),
    payload: <String, Object?>{'historyIndex': index},
  );
}

UnrouterMachineTransitionEntry _actionEnvelopeEntryForIndex(int index) {
  final rejected = index % 3 == 0;
  final actionEvent = rejected
      ? UnrouterMachineEvent.back
      : UnrouterMachineEvent.pop;
  final actionState = rejected
      ? UnrouterMachineActionEnvelopeState.rejected
      : UnrouterMachineActionEnvelopeState.completed;
  final rejectCode = rejected
      ? UnrouterMachineActionRejectCode.noBackHistory
      : null;
  final rejectReason = rejected
      ? 'No history entry is available for back navigation.'
      : null;
  final failure = rejected
      ? <String, Object?>{
          'code': rejectCode!.name,
          'message': rejectReason,
          'category': UnrouterMachineActionFailureCategory.history.name,
          'retryable': true,
          'metadata': const <String, Object?>{},
        }
      : null;

  return UnrouterMachineTransitionEntry(
    sequence: index + 1,
    recordedAt: DateTime(
      2026,
      2,
      6,
      14,
      0,
      0,
    ).add(Duration(milliseconds: index)),
    source: UnrouterMachineSource.controller,
    event: UnrouterMachineEvent.actionEnvelope,
    from: _stateForIndex(index),
    to: _stateForIndex(index),
    payload: <String, Object?>{
      'actionEnvelopeSchemaVersion':
          UnrouterMachineActionEnvelope.schemaVersion,
      'actionEnvelopeEventVersion': UnrouterMachineActionEnvelope.eventVersion,
      'actionEnvelopeProducer': UnrouterMachineActionEnvelope.producer,
      'actionEnvelopePhase': 'dispatch',
      'actionEvent': actionEvent.name,
      'actionState': actionState.name,
      'actionFailure': failure,
      'actionRejectCode': rejectCode?.name,
      'actionRejectReason': rejectReason,
      'actionEnvelope': <String, Object?>{
        'schemaVersion': UnrouterMachineActionEnvelope.schemaVersion,
        'eventVersion': UnrouterMachineActionEnvelope.eventVersion,
        'producer': UnrouterMachineActionEnvelope.producer,
        'state': actionState.name,
        'event': actionEvent.name,
        'isAccepted': !rejected,
        'isRejected': rejected,
        'isDeferred': false,
        'isCompleted': !rejected,
        'rejectCode': rejectCode?.name,
        'rejectReason': rejectReason,
        'failure': failure,
        'hasValue': true,
        'valueType': rejected ? 'bool' : 'int',
      },
    },
  );
}

UnrouterMachineState _stateForIndex(int index) {
  final userId = (index % 50) + 1;
  return UnrouterMachineState(
    uri: Uri(path: '/users/$userId'),
    resolution: UnrouterResolutionState.matched,
    routePath: '/users/:id',
    routeName: 'UserRoute',
    historyAction: HistoryAction.push,
    historyDelta: 1,
    historyIndex: index,
    canGoBack: index > 0,
  );
}
