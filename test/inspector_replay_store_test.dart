import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/devtools.dart';
import 'package:unstory/unstory.dart';

void main() {
  group('UnrouterInspectorReplayStore', () {
    testWidgets('captures bridge stream via fromBridge', (tester) async {
      UnrouterInspector<AppRoute>? inspector;
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        routes: [
          route<HomeRoute>(
            path: '/',
            parse: (_) => const HomeRoute(),
            builder: (context, _) {
              inspector ??= context.unrouterAs<AppRoute>().inspector;
              return TextButton(
                key: const Key('replay-store-to-user'),
                onPressed: () {
                  context.unrouter.push(const UserRoute(id: 9));
                },
                child: const Text('home'),
              );
            },
          ),
          route<UserRoute>(
            path: '/users/:id',
            parse: (state) => UserRoute(id: state.pathInt('id')),
            builder: (_, route) => Text('user:${route.id}'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final bridge = UnrouterInspectorBridge<AppRoute>(
        inspector: inspector!,
        emitInitial: false,
      );
      final replay = UnrouterInspectorReplayStore.fromBridge(bridge: bridge);

      bridge.emit();
      await tester.pump();
      await tester.tap(find.byKey(const Key('replay-store-to-user')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(replay.value.entries, isNotEmpty);
      expect(
        replay.value.latestEntry?.emission.report['routePath'],
        '/users/:id',
      );
      expect(
        replay.value.latestEntry?.emission.report['machineTimelineTail'],
        isA<List<Object?>>(),
      );

      replay.dispose();
      bridge.dispose();
    });

    test('captures emissions with bounded buffer and exports json', () async {
      final controller = StreamController<UnrouterInspectorEmission>.broadcast(
        sync: true,
      );
      final store = UnrouterInspectorReplayStore(
        stream: controller.stream,
        config: const UnrouterInspectorReplayStoreConfig(maxEntries: 2),
      );

      controller.add(
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/',
          at: DateTime(2026, 2, 6, 10, 0, 0),
        ),
      );
      controller.add(
        _emission(
          reason: UnrouterInspectorEmissionReason.stateChanged,
          uri: '/users/1',
          at: DateTime(2026, 2, 6, 10, 0, 1),
        ),
      );
      controller.add(
        _emission(
          reason: UnrouterInspectorEmissionReason.redirectChanged,
          uri: '/users/2',
          at: DateTime(2026, 2, 6, 10, 0, 2),
        ),
      );

      final state = store.value;
      expect(state.entries, hasLength(2));
      expect(state.entries.first.sequence, 2);
      expect(state.entries.last.sequence, 3);
      expect(state.emittedCount, 3);
      expect(state.droppedCount, 1);

      final payload = store.exportJson();
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['version'], UnrouterInspectorReplayStore.schemaVersion);
      expect(decoded['entryCount'], 2);
      final entries = decoded['entries'] as List<Object?>;
      expect(entries, hasLength(2));

      store.dispose();
      await controller.close();
    });

    test('imports exported payload and appends entries when requested', () {
      final source = UnrouterInspectorReplayStore();
      source.addAll(<UnrouterInspectorEmission>[
        _emission(
          reason: UnrouterInspectorEmissionReason.initial,
          uri: '/',
          at: DateTime(2026, 2, 6, 9, 0, 0),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.stateChanged,
          uri: '/users/7',
          at: DateTime(2026, 2, 6, 9, 0, 1),
        ),
      ]);

      final payload = source.exportJson();
      final imported = UnrouterInspectorReplayStore();
      imported.importJson(payload);

      expect(imported.value.entries, hasLength(2));
      expect(imported.value.entries.first.sequence, 1);
      expect(
        imported.value.entries.last.emission.reason,
        UnrouterInspectorEmissionReason.stateChanged,
      );

      imported.importJson(payload, clearExisting: false);
      expect(imported.value.entries, hasLength(4));
      expect(imported.value.entries.last.sequence, 4);

      source.dispose();
      imported.dispose();
    });

    test('imports legacy emissions-list payload with normalized sequence', () {
      final store = UnrouterInspectorReplayStore();
      final payload = jsonEncode(<Map<String, Object?>>[
        <String, Object?>{
          'reason': UnrouterInspectorEmissionReason.manual.name,
          'recordedAt': DateTime(2026, 2, 6, 8, 0, 0).toIso8601String(),
          'report': <String, Object?>{'uri': '/legacy-a'},
        },
        <String, Object?>{
          'reason': UnrouterInspectorEmissionReason.stateChanged.name,
          'recordedAt': DateTime(2026, 2, 6, 8, 0, 1).toIso8601String(),
          'report': <String, Object?>{'uri': '/legacy-b'},
        },
      ]);

      store.importJson(payload);

      expect(store.value.entries, hasLength(2));
      expect(store.value.entries.first.sequence, 1);
      expect(store.value.entries.last.sequence, 2);
      expect(
        store.value.entries.last.emission.reason,
        UnrouterInspectorEmissionReason.stateChanged,
      );

      store.dispose();
    });

    test('replays selected sequence range in order', () async {
      final store = UnrouterInspectorReplayStore();
      store.addAll(<UnrouterInspectorEmission>[
        _emission(
          reason: UnrouterInspectorEmissionReason.initial,
          uri: '/',
          at: DateTime(2026, 2, 6, 11, 0, 0),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/users/1',
          at: DateTime(2026, 2, 6, 11, 0, 1),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.stateChanged,
          uri: '/users/2',
          at: DateTime(2026, 2, 6, 11, 0, 2),
        ),
      ]);

      final replayed = <UnrouterInspectorEmissionReason>[];
      final delivered = await store.replay(
        fromSequence: 2,
        toSequence: 3,
        onEmission: (event) {
          replayed.add(event.reason);
        },
      );

      expect(delivered, 2);
      expect(replayed, <UnrouterInspectorEmissionReason>[
        UnrouterInspectorEmissionReason.manual,
        UnrouterInspectorEmissionReason.stateChanged,
      ]);
      expect(store.value.isReplaying, isFalse);
      expect(store.value.replayedCount, 2);

      store.dispose();
    });

    test('stopReplay interrupts delayed playback', () async {
      final store = UnrouterInspectorReplayStore();
      store.addAll(<UnrouterInspectorEmission>[
        _emission(
          reason: UnrouterInspectorEmissionReason.initial,
          uri: '/',
          at: DateTime(2026, 2, 6, 12, 0, 0),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/a',
          at: DateTime(2026, 2, 6, 12, 0, 1),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.stateChanged,
          uri: '/b',
          at: DateTime(2026, 2, 6, 12, 0, 2),
        ),
      ]);

      var replayed = 0;
      final future = store.replay(
        step: const Duration(milliseconds: 80),
        onEmission: (_) {
          replayed += 1;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      store.stopReplay();
      final delivered = await future;

      expect(delivered, lessThan(3));
      expect(replayed, equals(delivered));
      expect(store.value.isReplaying, isFalse);

      store.dispose();
    });

    test('validates action-envelope compatibility metadata', () {
      final store = UnrouterInspectorReplayStore();
      store.add(
        UnrouterInspectorEmission(
          reason: UnrouterInspectorEmissionReason.manual,
          recordedAt: DateTime(2026, 2, 6, 13, 0, 0),
          report: <String, Object?>{
            'machineTimelineTail': <Object?>[
              <String, Object?>{
                'event': UnrouterMachineEvent.actionEnvelope.name,
                'payload': <String, Object?>{
                  'actionEnvelopeSchemaVersion':
                      UnrouterMachineActionEnvelope.schemaVersion,
                  'actionEnvelopeEventVersion':
                      UnrouterMachineActionEnvelope.eventVersion,
                  'actionState': 'rejected',
                  'actionFailure': <String, Object?>{
                    'code': UnrouterMachineActionRejectCode.noBackHistory.name,
                    'message': 'No history entry is available.',
                    'category': 'history',
                    'retryable': true,
                    'metadata': <String, Object?>{},
                  },
                },
              },
            ],
          },
        ),
      );

      final result = store.validateActionEnvelopeCompatibility();
      expect(result.entryCount, 1);
      expect(result.hasIssues, isFalse);
      expect(result.errorCount, 0);
      expect(result.warningCount, 0);

      store.dispose();
    });

    test('reports incompatible action-envelope schema versions', () {
      final store = UnrouterInspectorReplayStore();
      store.add(
        UnrouterInspectorEmission(
          reason: UnrouterInspectorEmissionReason.manual,
          recordedAt: DateTime(2026, 2, 6, 13, 10, 0),
          report: <String, Object?>{
            'machineTimelineTail': <Object?>[
              <String, Object?>{
                'event': UnrouterMachineEvent.actionEnvelope.name,
                'payload': <String, Object?>{
                  'actionEnvelopeSchemaVersion': 999,
                  'actionEnvelopeEventVersion':
                      UnrouterMachineActionEnvelope.eventVersion,
                  'actionState': 'rejected',
                  'actionFailure': <String, Object?>{
                    'code': UnrouterMachineActionRejectCode.unknown.name,
                    'message': 'x',
                    'category': 'unknown',
                    'retryable': false,
                    'metadata': <String, Object?>{},
                  },
                },
              },
            ],
          },
        ),
      );

      final result = store.validateActionEnvelopeCompatibility();
      expect(result.hasIssues, isTrue);
      expect(result.errorCount, 1);
      expect(
        result.issues.single.code,
        UnrouterInspectorReplayValidationIssueCode
            .actionEnvelopeSchemaIncompatible,
      );

      store.dispose();
    });

    test('warns when rejected envelope misses structured failure', () {
      final store = UnrouterInspectorReplayStore();
      store.add(
        UnrouterInspectorEmission(
          reason: UnrouterInspectorEmissionReason.manual,
          recordedAt: DateTime(2026, 2, 6, 13, 20, 0),
          report: <String, Object?>{
            'machineTimelineTail': <Object?>[
              <String, Object?>{
                'event': UnrouterMachineEvent.actionEnvelope.name,
                'payload': <String, Object?>{
                  'actionEnvelopeSchemaVersion':
                      UnrouterMachineActionEnvelope.schemaVersion,
                  'actionEnvelopeEventVersion':
                      UnrouterMachineActionEnvelope.eventVersion,
                  'actionState': 'rejected',
                },
              },
            ],
          },
        ),
      );

      final result = store.validateActionEnvelopeCompatibility();
      expect(result.hasIssues, isTrue);
      expect(result.errorCount, 0);
      expect(result.warningCount, 1);
      expect(
        result.issues.single.code,
        UnrouterInspectorReplayValidationIssueCode.actionEnvelopeFailureMissing,
      );

      store.dispose();
    });

    test('warns when controller lifecycle coverage is incomplete', () {
      final store = UnrouterInspectorReplayStore();
      store.add(
        UnrouterInspectorEmission(
          reason: UnrouterInspectorEmissionReason.manual,
          recordedAt: DateTime(2026, 2, 6, 13, 30, 0),
          report: <String, Object?>{
            'machineTimelineTail': <Object?>[
              <String, Object?>{
                'source': UnrouterMachineSource.controller.name,
                'event':
                    UnrouterMachineEvent.controllerShellResolversChanged.name,
                'payload': <String, Object?>{'enabled': true},
              },
            ],
          },
        ),
      );

      final result = store.validateCompatibility();
      expect(result.hasIssues, isTrue);
      expect(result.errorCount, 0);
      expect(result.warningCount, 2);
      expect(
        result.issues
            .where(
              (issue) =>
                  issue.code ==
                  UnrouterInspectorReplayValidationIssueCode
                      .controllerLifecycleCoverageMissing,
            )
            .map((issue) => issue.machineEvent)
            .toSet(),
        {
          UnrouterMachineEvent.initialized,
          UnrouterMachineEvent.controllerRouteMachineConfigured,
        },
      );

      store.dispose();
    });

    test('validates controller lifecycle replay fixture', () {
      final store = UnrouterInspectorReplayStore();
      store.importJson(
        File(
          'test/fixtures/replay_controller_lifecycle.json',
        ).readAsStringSync(),
      );
      final result = store.validateCompatibility();
      expect(result.hasIssues, isFalse);
      store.dispose();
    });
  });
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

UnrouterInspectorEmission _emission({
  required UnrouterInspectorEmissionReason reason,
  required String uri,
  required DateTime at,
}) {
  return UnrouterInspectorEmission(
    reason: reason,
    recordedAt: at,
    report: <String, Object?>{
      'uri': uri,
      'routePath': uri,
      'resolution': UnrouterResolutionState.matched.name,
    },
  );
}
