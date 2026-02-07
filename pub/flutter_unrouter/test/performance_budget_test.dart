import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/machine.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
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
      source: UnrouterMachineSource.navigation,
      event: UnrouterMachineEvent.goUri,
      from: _stateForIndex(index),
      to: _stateForIndex(index + 1),
      payload: <String, Object?>{
        'beforeAction': HistoryAction.replace.name,
        'afterAction': HistoryAction.push.name,
        'beforeDelta': 0,
        'afterDelta': 1,
        'beforeHistoryIndex': index,
        'afterHistoryIndex': index + 1,
        'beforeCanGoBack': index > 0,
        'afterCanGoBack': true,
      },
    );
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
