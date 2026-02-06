import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  test(
    'bridge config copyWith supports resetting nullable machine filters',
    () {
      const config = UnrouterInspectorBridgeConfig(
        machineQuery: '/users',
        machineEventGroups: {UnrouterMachineEventGroup.routeResolution},
        machinePayloadKinds: {UnrouterMachineTypedPayloadKind.route},
      );

      final reset = config.copyWith(
        machineQuery: null,
        machineEventGroups: null,
        machinePayloadKinds: null,
      );

      expect(reset.machineQuery, isNull);
      expect(reset.machineEventGroups, isNull);
      expect(reset.machinePayloadKinds, isNull);
    },
  );

  testWidgets('bridge emits stream and sink payloads for state changes', (
    tester,
  ) async {
    UnrouterInspector<AppRoute>? inspector;
    final redirectDiagnostics = UnrouterRedirectDiagnosticsStore();
    final emissions = <UnrouterInspectorEmission>[];
    final jsonPayloads = <String>[];

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      onRedirectDiagnostics: redirectDiagnostics.onDiagnostics,
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            inspector ??= context.unrouterAs<AppRoute>().inspector;
            return TextButton(
              key: const Key('bridge-to-user'),
              onPressed: () {
                context.unrouter.push(const UserRoute(id: 55));
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
      redirectDiagnostics: redirectDiagnostics,
      config: const UnrouterInspectorBridgeConfig(
        timelineTail: 2,
        machineSources: {UnrouterMachineSource.route},
        machineEventGroups: {UnrouterMachineEventGroup.routeResolution},
        machinePayloadKinds: {UnrouterMachineTypedPayloadKind.route},
      ),
      sinks: <UnrouterInspectorSink>[
        UnrouterInspectorJsonSink(jsonPayloads.add),
      ],
      emitInitial: false,
    );

    final manualEmissionFuture = bridge.stream.first;
    bridge.emit();
    final manualEmission = await manualEmissionFuture;
    emissions.add(manualEmission);

    expect(emissions, hasLength(1));
    expect(emissions.single.reason, UnrouterInspectorEmissionReason.manual);
    expect(emissions.single.report['routePath'], anyOf(isNull, '/'));
    expect(
      emissions.single.report['machineTimelineLength'],
      greaterThanOrEqualTo(1),
    );
    expect(
      emissions.single.report['machineTimelineTail'],
      isA<List<Object?>>(),
    );
    final machineTail =
        emissions.single.report['machineTimelineTail'] as List<Object?>;
    expect(machineTail, isNotEmpty);
    expect(
      machineTail.every(
        (entry) => (entry as Map<String, Object?>)['source'] == 'route',
      ),
      isTrue,
    );
    expect(
      machineTail.every(
        (entry) =>
            (entry as Map<String, Object?>)['eventGroup'] == 'routeResolution',
      ),
      isTrue,
    );
    expect(
      machineTail.every(
        (entry) => (entry as Map<String, Object?>)['payloadKind'] == 'route',
      ),
      isTrue,
    );
    expect(jsonPayloads, hasLength(1));
    final payload = jsonDecode(jsonPayloads.single) as Map<String, Object?>;
    expect(payload['reason'], UnrouterInspectorEmissionReason.manual.name);

    bridge.updateMachineEventGroups(null, emitAfterUpdate: false);
    expect(bridge.config.machineEventGroups, isNull);
    bridge.updateMachineEventGroups({
      UnrouterMachineEventGroup.routeResolution,
    }, emitAfterUpdate: false);
    expect(bridge.config.machineEventGroups, {
      UnrouterMachineEventGroup.routeResolution,
    });
    bridge.updateMachinePayloadKinds(null, emitAfterUpdate: false);
    expect(bridge.config.machinePayloadKinds, isNull);
    bridge.updateMachinePayloadKinds({
      UnrouterMachineTypedPayloadKind.route,
    }, emitAfterUpdate: false);
    expect(bridge.config.machinePayloadKinds, {
      UnrouterMachineTypedPayloadKind.route,
    });

    final stateChangedFuture = bridge.stream.firstWhere(
      (event) => event.reason == UnrouterInspectorEmissionReason.stateChanged,
    );
    await tester.tap(find.byKey(const Key('bridge-to-user')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    emissions.add(await stateChangedFuture);

    expect(
      emissions.any(
        (event) =>
            event.reason == UnrouterInspectorEmissionReason.stateChanged &&
            event.report['routePath'] == '/users/:id',
      ),
      isTrue,
    );

    bridge.dispose();
  });

  testWidgets('bridge emits redirect-change events from diagnostics store', (
    tester,
  ) async {
    UnrouterInspector<AppRoute>? inspector;
    final redirectDiagnostics = UnrouterRedirectDiagnosticsStore();
    final emissions = <UnrouterInspectorEmission>[];

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            inspector ??= context.unrouterAs<AppRoute>().inspector;
            return const Text('home');
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final bridge = UnrouterInspectorBridge<AppRoute>(
      inspector: inspector!,
      redirectDiagnostics: redirectDiagnostics,
      emitInitial: false,
      config: const UnrouterInspectorBridgeConfig(
        redirectQuery: '/loop-a',
        redirectTrailTail: 2,
      ),
    );

    final redirectChangedFuture = bridge.stream.firstWhere(
      (event) =>
          event.reason == UnrouterInspectorEmissionReason.redirectChanged,
    );

    redirectDiagnostics.add(
      RedirectDiagnostics(
        reason: RedirectDiagnosticsReason.loopDetected,
        currentUri: Uri(path: '/loop-b'),
        redirectUri: Uri(path: '/loop-a'),
        trail: <Uri>[
          Uri(path: '/loop-a'),
          Uri(path: '/loop-b'),
          Uri(path: '/loop-a'),
        ],
        hop: 2,
        maxHops: 8,
        loopPolicy: RedirectLoopPolicy.error,
      ),
    );
    await tester.pump();
    emissions.add(await redirectChangedFuture);

    expect(emissions, hasLength(1));
    expect(
      emissions.single.reason,
      UnrouterInspectorEmissionReason.redirectChanged,
    );
    expect(emissions.single.report['redirectTrailLength'], 1);
    expect(
      emissions.single.report['machineTimelineTail'],
      isA<List<Object?>>(),
    );
    final tail = emissions.single.report['redirectTrailTail'] as List<Object?>;
    expect(tail, hasLength(1));
    final tailItem = tail.single as Map<String, Object?>;
    expect(tailItem['reason'], RedirectDiagnosticsReason.loopDetected.name);

    bridge.dispose();
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
