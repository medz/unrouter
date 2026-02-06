import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  testWidgets('renders entries and supports selection controls', (
    tester,
  ) async {
    final controller = StreamController<UnrouterInspectorEmission>.broadcast(
      sync: true,
    );
    final panel = UnrouterInspectorPanelAdapter(stream: controller.stream);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(panel: panel),
          ),
        ),
      ),
    );

    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/',
        uri: '/',
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.stateChanged,
        path: '/users/:id',
        uri: '/users/42',
      ),
    );
    await tester.pump();

    expect(find.textContaining('entries=2/200'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.textContaining('selected=#2 stateChanged'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unrouter-panel-prev')));
    await tester.pump();
    expect(panel.value.selectedSequence, 1);
    expect(find.textContaining('selected=#1 manual'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unrouter-panel-next')));
    await tester.pump();
    expect(panel.value.selectedSequence, 2);

    await tester.tap(find.byKey(const Key('unrouter-panel-latest')));
    await tester.pump();
    expect(panel.value.selectedSequence, 2);

    await tester.tap(find.byKey(const Key('unrouter-panel-clear')));
    await tester.pump();
    expect(panel.value.entries, isEmpty);
    expect(find.textContaining('entries=0/200'), findsOneWidget);

    panel.dispose();
    await controller.close();
  });

  testWidgets('supports query/reason filtering and export selected payload', (
    tester,
  ) async {
    final controller = StreamController<UnrouterInspectorEmission>.broadcast(
      sync: true,
    );
    final panel = UnrouterInspectorPanelAdapter(stream: controller.stream);
    String? exported;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(
              panel: panel,
              query: '/users/',
              reasons: const {UnrouterInspectorEmissionReason.stateChanged},
              onExportSelected: (value) {
                exported = value;
              },
            ),
          ),
        ),
      ),
    );

    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/',
        uri: '/',
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.stateChanged,
        path: '/users/:id',
        uri: '/users/42',
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.redirectChanged,
        path: '/redirect',
        uri: '/redirect',
      ),
    );
    await tester.pump();

    expect(find.textContaining('visible=1'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsNothing);
    expect(find.byKey(const Key('unrouter-panel-entry-3')), findsNothing);

    await tester.tap(find.byKey(const Key('unrouter-panel-export-selected')));
    await tester.pump();
    expect(exported, isNotNull);
    final payload = jsonDecode(exported!) as Map<String, Object?>;
    expect(payload['sequence'], 3);
    expect(
      payload['reason'],
      UnrouterInspectorEmissionReason.redirectChanged.name,
    );

    await tester.tap(find.byKey(const Key('unrouter-panel-entry-2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('unrouter-panel-export-selected')));
    await tester.pump();
    final selectedPayload = jsonDecode(exported!) as Map<String, Object?>;
    expect(selectedPayload['sequence'], 2);
    expect(
      selectedPayload['reason'],
      UnrouterInspectorEmissionReason.stateChanged.name,
    );

    panel.dispose();
    await controller.close();
  });

  testWidgets('supports machine event-group quick filter controls', (
    tester,
  ) async {
    final controller = StreamController<UnrouterInspectorEmission>.broadcast(
      sync: true,
    );
    final panel = UnrouterInspectorPanelAdapter(stream: controller.stream);
    Set<UnrouterMachineEventGroup>? syncedGroups;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(
              panel: panel,
              onMachineEventGroupsChanged: (groups) {
                syncedGroups = groups;
              },
            ),
          ),
        ),
      ),
    );

    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/',
        uri: '/',
        machineTimelineTail: const <Map<String, Object?>>[
          {'eventGroup': 'navigation'},
        ],
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.stateChanged,
        path: '/users/:id',
        uri: '/users/42',
        machineTimelineTail: const <Map<String, Object?>>[
          {'eventGroup': 'routeResolution'},
        ],
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.redirectChanged,
        path: '/shell',
        uri: '/shell',
        machineTimelineTail: const <Map<String, Object?>>[
          {'eventGroup': 'shell'},
        ],
      ),
    );
    await tester.pump();

    expect(find.textContaining('machineGroups=all'), findsOneWidget);
    expect(find.textContaining('visible=3'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('unrouter-panel-machine-group-routeResolution')),
    );
    await tester.pump();
    expect(syncedGroups, {UnrouterMachineEventGroup.routeResolution});
    expect(
      find.textContaining('machineGroups=routeResolution'),
      findsOneWidget,
    );
    expect(find.textContaining('visible=1'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsNothing);
    expect(find.byKey(const Key('unrouter-panel-entry-3')), findsNothing);

    await tester.tap(
      find.byKey(const Key('unrouter-panel-machine-group-navigation')),
    );
    await tester.pump();
    expect(syncedGroups, {
      UnrouterMachineEventGroup.navigation,
      UnrouterMachineEventGroup.routeResolution,
    });
    expect(
      find.textContaining('machineGroups=navigation,routeResolution'),
      findsOneWidget,
    );
    expect(find.textContaining('visible=2'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-3')), findsNothing);

    await tester.tap(find.byKey(const Key('unrouter-panel-machine-group-all')));
    await tester.pump();
    expect(syncedGroups, isNull);
    expect(find.textContaining('machineGroups=all'), findsOneWidget);
    expect(find.textContaining('visible=3'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-3')), findsOneWidget);

    panel.dispose();
    await controller.close();
  });

  testWidgets('supports machine payload-kind quick filter controls', (
    tester,
  ) async {
    final controller = StreamController<UnrouterInspectorEmission>.broadcast(
      sync: true,
    );
    final panel = UnrouterInspectorPanelAdapter(stream: controller.stream);
    Set<UnrouterMachineTypedPayloadKind>? syncedKinds;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(
              panel: panel,
              onMachinePayloadKindsChanged: (kinds) {
                syncedKinds = kinds;
              },
            ),
          ),
        ),
      ),
    );

    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/',
        uri: '/',
        machineTimelineTail: const <Map<String, Object?>>[
          {
            'source': 'controller',
            'event': 'actionEnvelope',
            'payload': {'actionState': 'accepted'},
          },
        ],
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.stateChanged,
        path: '/users/:id',
        uri: '/users/42',
        machineTimelineTail: const <Map<String, Object?>>[
          {
            'source': 'route',
            'event': 'commit',
            'payload': {'hop': 0},
          },
        ],
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.redirectChanged,
        path: '/shell',
        uri: '/shell',
        machineTimelineTail: const <Map<String, Object?>>[
          {'source': 'controller', 'event': 'initialized', 'payload': {}},
        ],
      ),
    );
    await tester.pump();

    expect(find.textContaining('machineKinds=all'), findsOneWidget);
    expect(find.textContaining('visible=3'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('unrouter-panel-machine-kind-route')),
    );
    await tester.pump();
    expect(syncedKinds, {UnrouterMachineTypedPayloadKind.route});
    expect(find.textContaining('machineKinds=route'), findsOneWidget);
    expect(find.textContaining('visible=1'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsNothing);
    expect(find.byKey(const Key('unrouter-panel-entry-3')), findsNothing);

    await tester.tap(
      find.byKey(const Key('unrouter-panel-machine-kind-actionEnvelope')),
    );
    await tester.pump();
    expect(syncedKinds, {
      UnrouterMachineTypedPayloadKind.actionEnvelope,
      UnrouterMachineTypedPayloadKind.route,
    });
    expect(
      find.textContaining('machineKinds=actionEnvelope,route'),
      findsOneWidget,
    );
    expect(find.textContaining('visible=2'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-3')), findsNothing);

    await tester.tap(find.byKey(const Key('unrouter-panel-machine-kind-all')));
    await tester.pump();
    expect(syncedKinds, isNull);
    expect(find.textContaining('machineKinds=all'), findsOneWidget);
    expect(find.textContaining('visible=3'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-1')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-2')), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-entry-3')), findsOneWidget);

    panel.dispose();
    await controller.close();
  });

  testWidgets('integrates replay timeline and playback controls', (
    tester,
  ) async {
    final controller = StreamController<UnrouterInspectorEmission>.broadcast(
      sync: true,
    );
    final panel = UnrouterInspectorPanelAdapter(stream: controller.stream);
    final replayStore = UnrouterInspectorReplayStore(stream: controller.stream);
    final replayController = UnrouterInspectorReplayController(
      store: replayStore,
      config: const UnrouterInspectorReplayControllerConfig(
        step: Duration(milliseconds: 8),
      ),
    );
    final baseline = UnrouterInspectorReplayStore();
    baseline.addAll(<UnrouterInspectorEmission>[
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/a',
        uri: '/a',
      ),
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/x',
        uri: '/x',
      ),
    ]);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(
              panel: panel,
              replayController: replayController,
            ),
          ),
        ),
      ),
    );

    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/a',
        uri: '/a',
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.stateChanged,
        path: '/b',
        uri: '/b',
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.redirectChanged,
        path: '/c',
        uri: '/c',
      ),
    );
    await tester.pump();

    final replayDiff = replayStore.compareWith(baseline);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(
              panel: panel,
              replayController: replayController,
              replayDiff: replayDiff,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('unrouter-panel-timeline-1')));
    await tester.pump();
    expect(replayController.value.cursorSequence, 1);
    expect(panel.value.selectedSequence, 1);
    expect(find.textContaining('diff mode=sequence'), findsOneWidget);
    expect(find.textContaining('|diff]'), findsWidgets);
    expect(find.textContaining('session-compare rows='), findsOneWidget);
    expect(find.textContaining('risk high='), findsOneWidget);
    expect(find.text('baseline'), findsOneWidget);
    expect(find.text('current'), findsOneWidget);
    final initialRiskSummary = tester.widget<Text>(
      find.byKey(const Key('unrouter-panel-compare-risk-summary')),
    );
    expect(initialRiskSummary.data, contains('filter=all'));
    expect(find.byKey(const Key('unrouter-panel-timeline-1')), findsOneWidget);
    expect(
      find.byKey(const Key('unrouter-panel-compare-cluster-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('unrouter-panel-compare-row-0')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('unrouter-panel-compare-high-risk-next')),
    );
    await tester.pump();
    expect(panel.value.selectedSequence, 2);

    await tester.tap(
      find.byKey(const Key('unrouter-panel-compare-high-risk-toggle')),
    );
    await tester.pump();
    final highRiskSummary = tester.widget<Text>(
      find.byKey(const Key('unrouter-panel-compare-risk-summary')),
    );
    expect(highRiskSummary.data, contains('filter=high'));

    await tester.tap(
      find.byKey(const Key('unrouter-panel-compare-high-risk-toggle')),
    );
    await tester.pump();
    final resetRiskSummary = tester.widget<Text>(
      find.byKey(const Key('unrouter-panel-compare-risk-summary')),
    );
    expect(resetRiskSummary.data, contains('filter=all'));

    final compareRow = tester.widget<GestureDetector>(
      find.byKey(const Key('unrouter-panel-compare-row-0')),
    );
    compareRow.onTap!.call();
    await tester.pump();
    expect(panel.value.selectedSequence, 2);

    await tester.tap(find.byKey(const Key('unrouter-panel-compare-cluster-0')));
    await tester.pump();
    expect(find.byKey(const Key('unrouter-panel-compare-row-0')), findsNothing);

    await tester.tap(find.byKey(const Key('unrouter-panel-compare-cluster-0')));
    await tester.pump();
    expect(
      find.byKey(const Key('unrouter-panel-compare-row-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('unrouter-panel-compare-toggle')));
    await tester.pump();
    expect(find.textContaining('session-compare: collapsed'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-compare-row-0')), findsNothing);

    await tester.tap(find.byKey(const Key('unrouter-panel-compare-toggle')));
    await tester.pump();
    expect(
      find.byKey(const Key('unrouter-panel-compare-row-0')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('unrouter-panel-timeline-diff-toggle')),
    );
    await tester.pump();
    expect(find.textContaining('filter=diff'), findsOneWidget);
    expect(find.byKey(const Key('unrouter-panel-timeline-1')), findsNothing);
    expect(find.byKey(const Key('unrouter-panel-timeline-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('unrouter-panel-replay-bookmark')));
    await tester.pump();
    expect(replayController.value.bookmarks, hasLength(1));

    final beforeSpeed = replayController.value.speed;
    await tester.tap(find.byKey(const Key('unrouter-panel-replay-speed')));
    await tester.pump();
    expect(replayController.value.speed, isNot(beforeSpeed));

    expect(find.textContaining('timelineZoom=1x'), findsOneWidget);
    await tester.tap(find.byKey(const Key('unrouter-panel-timeline-zoom-in')));
    await tester.pump();
    expect(find.textContaining('timelineZoom=2x'), findsOneWidget);
    await tester.tap(find.byKey(const Key('unrouter-panel-timeline-zoom-out')));
    await tester.pump();
    expect(find.textContaining('timelineZoom=1x'), findsOneWidget);

    replayController.addBookmark(label: 'auth-start', group: 'auth');
    replayController.addBookmark(label: 'checkout-start', group: 'checkout');
    await tester.pump();
    expect(find.text('group:auth'), findsOneWidget);
    expect(find.text('group:checkout'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unrouter-panel-replay-primary')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(replayController.value.isIdle, isTrue);
    expect(panel.value.selectedSequence, 3);

    baseline.dispose();
    replayController.dispose();
    replayStore.dispose();
    panel.dispose();
    await controller.close();
  });

  testWidgets('shows replay validation summary and jumps to next issue', (
    tester,
  ) async {
    final controller = StreamController<UnrouterInspectorEmission>.broadcast(
      sync: true,
    );
    final panel = UnrouterInspectorPanelAdapter(stream: controller.stream);
    final replayStore = UnrouterInspectorReplayStore(stream: controller.stream);
    final replayController = UnrouterInspectorReplayController(
      store: replayStore,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(
              panel: panel,
              replayController: replayController,
            ),
          ),
        ),
      ),
    );

    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/broken',
        uri: '/broken',
        machineTimelineTail: <Map<String, Object?>>[
          <String, Object?>{
            'event': UnrouterMachineEvent.actionEnvelope.name,
            'payload': <String, Object?>{
              'actionEnvelopeSchemaVersion': 999,
              'actionEnvelopeEventVersion':
                  UnrouterMachineActionEnvelope.eventVersion,
              'actionState': 'rejected',
              'actionFailure': <String, Object?>{
                'code': UnrouterMachineActionRejectCode.unknown.name,
                'message': 'legacy payload',
                'category': UnrouterMachineActionFailureCategory.unknown.name,
                'retryable': false,
                'metadata': <String, Object?>{},
              },
            },
          },
        ],
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.stateChanged,
        path: '/ok',
        uri: '/ok',
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('replayValidation issues=1 errors=1 warnings=0'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('unrouter-panel-replay-validation-next')),
    );
    await tester.pump();

    expect(panel.value.selectedSequence, 1);
    expect(replayController.value.cursorSequence, 1);

    replayController.dispose();
    replayStore.dispose();
    panel.dispose();
    await controller.close();
  });

  testWidgets('supports replay validation severity/code quick filters', (
    tester,
  ) async {
    final controller = StreamController<UnrouterInspectorEmission>.broadcast(
      sync: true,
    );
    final panel = UnrouterInspectorPanelAdapter(stream: controller.stream);
    final replayStore = UnrouterInspectorReplayStore(stream: controller.stream);
    final replayController = UnrouterInspectorReplayController(
      store: replayStore,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 900,
            child: UnrouterInspectorPanelWidget(
              panel: panel,
              replayController: replayController,
            ),
          ),
        ),
      ),
    );

    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.manual,
        path: '/schema',
        uri: '/schema',
        machineTimelineTail: <Map<String, Object?>>[
          <String, Object?>{
            'event': UnrouterMachineEvent.actionEnvelope.name,
            'payload': <String, Object?>{
              'actionEnvelopeSchemaVersion': 999,
              'actionEnvelopeEventVersion':
                  UnrouterMachineActionEnvelope.eventVersion,
              'actionState': 'rejected',
              'actionFailure': <String, Object?>{
                'code': UnrouterMachineActionRejectCode.unknown.name,
                'message': 'legacy payload',
                'category': UnrouterMachineActionFailureCategory.unknown.name,
                'retryable': false,
                'metadata': <String, Object?>{},
              },
            },
          },
        ],
      ),
    );
    controller.add(
      _emission(
        reason: UnrouterInspectorEmissionReason.stateChanged,
        path: '/lifecycle',
        uri: '/lifecycle',
        machineTimelineTail: <Map<String, Object?>>[
          <String, Object?>{
            'source': UnrouterMachineSource.controller.name,
            'event': UnrouterMachineEvent.controllerShellResolversChanged.name,
            'payload': <String, Object?>{'enabled': true},
          },
        ],
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('replayValidation issues=3 errors=1 warnings=2'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'replayValidationSelected issues=3 errors=1 warnings=2',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('unrouter-panel-replay-validation-severity-error')),
    );
    await tester.pump();
    expect(
      find.textContaining(
        'replayValidationSelected issues=1 errors=1 warnings=0',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const Key(
          'unrouter-panel-replay-validation-code-controllerLifecycleCoverageMissing',
        ),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining(
        'replayValidationSelected issues=0 errors=0 warnings=0',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('unrouter-panel-replay-validation-severity-error')),
    );
    await tester.pump();
    expect(
      find.textContaining(
        'replayValidationSelected issues=2 errors=0 warnings=2',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('unrouter-panel-replay-validation-next')),
    );
    await tester.pump();
    expect(panel.value.selectedSequence, 2);
    expect(replayController.value.cursorSequence, 2);

    replayController.dispose();
    replayStore.dispose();
    panel.dispose();
    await controller.close();
  });
}

UnrouterInspectorEmission _emission({
  required UnrouterInspectorEmissionReason reason,
  required String path,
  required String uri,
  List<Map<String, Object?>> machineTimelineTail =
      const <Map<String, Object?>>[],
}) {
  return UnrouterInspectorEmission(
    reason: reason,
    recordedAt: DateTime(2026, 2, 6),
    report: <String, Object?>{
      'routePath': path,
      'uri': uri,
      'resolution': UnrouterResolutionState.matched.name,
      'machineTimelineTail': machineTimelineTail,
    },
  );
}
