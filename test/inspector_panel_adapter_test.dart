import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/devtools.dart';
import 'package:unstory/unstory.dart';

void main() {
  group('UnrouterInspectorPanelAdapter', () {
    testWidgets('adapts bridge stream emissions', (tester) async {
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
                key: const Key('panel-adapter-to-user'),
                onPressed: () {
                  context.unrouter.push(const UserRoute(id: 7));
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
      final panel = UnrouterInspectorPanelAdapter.fromBridge(
        bridge: bridge,
        config: const UnrouterInspectorPanelAdapterConfig(maxEntries: 3),
      );

      bridge.emit();
      await tester.pump();

      await tester.tap(find.byKey(const Key('panel-adapter-to-user')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final state = panel.value;
      expect(state.entries, isNotEmpty);
      expect(
        state.reasonCounts[UnrouterInspectorEmissionReason.manual],
        greaterThanOrEqualTo(1),
      );
      expect(
        state.reasonCounts[UnrouterInspectorEmissionReason.stateChanged],
        greaterThanOrEqualTo(1),
      );
      expect(state.latestEntry?.routePath, '/users/:id');

      panel.dispose();
      bridge.dispose();
    });

    test('collects emissions and auto-selects latest entry', () async {
      final controller = StreamController<UnrouterInspectorEmission>.broadcast(
        sync: true,
      );
      final adapter = UnrouterInspectorPanelAdapter(stream: controller.stream);

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

      final state = adapter.value;
      expect(state.entries, hasLength(2));
      expect(state.selectedEntry?.sequence, 2);
      expect(state.selectedEntry?.routePath, '/users/:id');
      expect(state.selectedEntry?.uri, '/users/42');
      expect(state.reasonCounts, <UnrouterInspectorEmissionReason, int>{
        UnrouterInspectorEmissionReason.manual: 1,
        UnrouterInspectorEmissionReason.stateChanged: 1,
      });

      adapter.dispose();
      await controller.close();
    });

    test('drops oldest entries when maxEntries is exceeded', () async {
      final controller = StreamController<UnrouterInspectorEmission>.broadcast(
        sync: true,
      );
      final adapter = UnrouterInspectorPanelAdapter(
        stream: controller.stream,
        config: const UnrouterInspectorPanelAdapterConfig(
          maxEntries: 2,
          autoSelectLatest: false,
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
          path: '/a',
          uri: '/a',
        ),
      );
      controller.add(
        _emission(
          reason: UnrouterInspectorEmissionReason.redirectChanged,
          path: '/b',
          uri: '/b',
        ),
      );

      final state = adapter.value;
      expect(state.emittedCount, 3);
      expect(state.droppedCount, 1);
      expect(state.entries, hasLength(2));
      expect(state.entries.first.sequence, 2);
      expect(state.entries.last.sequence, 3);
      expect(state.selectedEntry?.sequence, 2);
      expect(state.reasonCounts, <UnrouterInspectorEmissionReason, int>{
        UnrouterInspectorEmissionReason.stateChanged: 1,
        UnrouterInspectorEmissionReason.redirectChanged: 1,
      });

      adapter.dispose();
      await controller.close();
    });

    test('supports selection navigation and clear', () async {
      final controller = StreamController<UnrouterInspectorEmission>.broadcast(
        sync: true,
      );
      final adapter = UnrouterInspectorPanelAdapter(stream: controller.stream);

      controller.add(
        _emission(
          reason: UnrouterInspectorEmissionReason.initial,
          path: '/',
          uri: '/',
        ),
      );
      controller.add(
        _emission(
          reason: UnrouterInspectorEmissionReason.stateChanged,
          path: '/a',
          uri: '/a',
        ),
      );
      controller.add(
        _emission(
          reason: UnrouterInspectorEmissionReason.redirectChanged,
          path: '/b',
          uri: '/b',
        ),
      );

      expect(adapter.value.selectedEntry?.sequence, 3);
      expect(adapter.selectPrevious(), isTrue);
      expect(adapter.value.selectedEntry?.sequence, 2);
      expect(adapter.selectPrevious(), isTrue);
      expect(adapter.value.selectedEntry?.sequence, 1);
      expect(adapter.selectPrevious(), isFalse);
      expect(adapter.selectNext(), isTrue);
      expect(adapter.value.selectedEntry?.sequence, 2);
      expect(adapter.selectLatest(), isTrue);
      expect(adapter.value.selectedEntry?.sequence, 3);
      expect(adapter.select(1), isTrue);
      expect(adapter.value.selectedEntry?.sequence, 1);
      expect(adapter.select(999), isFalse);

      adapter.clear(resetCounters: true);
      expect(adapter.value.entries, isEmpty);
      expect(adapter.value.selectedEntry, isNull);
      expect(adapter.value.emittedCount, 0);
      expect(adapter.value.droppedCount, 0);
      expect(adapter.selectNext(), isFalse);

      adapter.dispose();
      await controller.close();
    });
  });
}

UnrouterInspectorEmission _emission({
  required UnrouterInspectorEmissionReason reason,
  required String path,
  required String uri,
}) {
  return UnrouterInspectorEmission(
    reason: reason,
    recordedAt: DateTime(2026, 2, 6),
    report: <String, Object?>{
      'routePath': path,
      'uri': uri,
      'resolution': UnrouterResolutionState.matched.name,
    },
  );
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
