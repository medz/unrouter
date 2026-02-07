import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/machine.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  testWidgets(
    'machine reducer is deterministic for identical command streams',
    (tester) async {
      final first = await _runScenario(tester);
      final second = await _runScenario(tester);

      expect(second.transitions, first.transitions);
      expect(second.finalState, first.finalState);
    },
  );

  testWidgets(
    'machine command streams stay deterministic for long seeded scripts',
    (tester) async {
      const seeds = <int>[7, 19];
      for (final seed in seeds) {
        final operations = _buildSeededOperations(seed: seed, length: 40);
        final firstSnapshot = await _runScenarioWithOperations(
          tester,
          operations,
        );
        final secondSnapshot = await _runScenarioWithOperations(
          tester,
          operations,
        );
        expect(
          secondSnapshot.transitions,
          firstSnapshot.transitions,
          reason: 'transition mismatch for seed=$seed',
        );
        expect(
          secondSnapshot.finalState,
          firstSnapshot.finalState,
          reason: 'state mismatch for seed=$seed',
        );
      }
    },
  );
}

Future<_MachineScenarioSnapshot> _runScenario(WidgetTester tester) async {
  UnrouterMachine<_AppRoute>? machine;
  final pendingPushResults = <Future<Object?>>[];

  final router = Unrouter<_AppRoute>(
    history: MemoryHistory(),
    routes: [
      route<_HomeRoute>(
        path: '/',
        parse: (_) => const _HomeRoute(),
        builder: (context, _) {
          machine ??= context.unrouterMachineAs<_AppRoute>();
          return const Text('home');
        },
      ),
      route<_UserRoute>(
        path: '/users/:id',
        parse: (state) => _UserRoute(id: state.pathInt('id')),
        builder: (_, route) => Text('user:${route.id}'),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  expect(machine, isNotNull);

  final steps = <void Function()>[
    () {
      pendingPushResults.add(
        machine!.dispatch<Future<Object?>>(
          UnrouterMachineCommand.pushUri(Uri(path: '/users/1')),
        ),
      );
    },
    () {
      pendingPushResults.add(
        machine!.dispatch<Future<Object?>>(
          UnrouterMachineCommand.pushUri(Uri(path: '/users/2')),
        ),
      );
    },
    () {
      machine!.dispatch<bool>(UnrouterMachineCommand.back());
    },
    () {
      machine!.dispatch<bool>(UnrouterMachineCommand.back());
    },
    () {
      machine!.dispatch<void>(UnrouterMachineCommand.forward());
    },
    () {
      machine!.dispatch<void>(UnrouterMachineCommand.goDelta(1));
    },
    () {
      machine!.dispatch<void>(
        UnrouterMachineCommand.replaceUri(Uri(path: '/users/9')),
      );
    },
    () {
      machine!.dispatch<void>(UnrouterMachineCommand.goDelta(-2));
    },
  ];

  for (final step in steps) {
    step();
    await tester.pumpAndSettle();
  }

  await Future.wait(pendingPushResults);
  await tester.pumpAndSettle();

  final transitions = machine!.timeline
      .map(
        (entry) => <String, Object?>{
          'source': entry.source.name,
          'event': entry.event.name,
          'fromUri': entry.from.uri.toString(),
          'toUri': entry.to.uri.toString(),
          'toResolution': entry.to.resolution.name,
          'toAction': entry.to.historyAction.name,
          'toHistoryIndex': entry.to.historyIndex,
          'toRoutePath': entry.to.routePath,
        },
      )
      .toList(growable: false);
  final finalState = machine!.state.toJson();

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();

  return _MachineScenarioSnapshot(
    transitions: transitions,
    finalState: finalState,
  );
}

class _MachineScenarioSnapshot {
  const _MachineScenarioSnapshot({
    required this.transitions,
    required this.finalState,
  });

  final List<Map<String, Object?>> transitions;
  final Map<String, Object?> finalState;
}

enum _MachineScriptOpKind { go, replace, push, pop, back, forward, delta }

class _MachineScriptOp {
  const _MachineScriptOp({
    required this.kind,
    this.uri,
    this.delta,
    this.result,
  });

  final _MachineScriptOpKind kind;
  final Uri? uri;
  final int? delta;
  final Object? result;
}

List<_MachineScriptOp> _buildSeededOperations({
  required int seed,
  required int length,
}) {
  assert(length > 0);
  var state = seed;

  int next() {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return state;
  }

  Uri nextUserUri() {
    final id = (next() % 24) + 1;
    return Uri(path: '/users/$id');
  }

  final operations = <_MachineScriptOp>[];
  for (var index = 0; index < length; index++) {
    final roll = next() % 7;
    switch (roll) {
      case 0:
        operations.add(
          _MachineScriptOp(kind: _MachineScriptOpKind.go, uri: nextUserUri()),
        );
        break;
      case 1:
        operations.add(
          _MachineScriptOp(
            kind: _MachineScriptOpKind.replace,
            uri: nextUserUri(),
          ),
        );
        break;
      case 2:
        operations.add(
          _MachineScriptOp(kind: _MachineScriptOpKind.push, uri: nextUserUri()),
        );
        break;
      case 3:
        operations.add(
          _MachineScriptOp(
            kind: _MachineScriptOpKind.pop,
            result: next() % 1000,
          ),
        );
        break;
      case 4:
        operations.add(const _MachineScriptOp(kind: _MachineScriptOpKind.back));
        break;
      case 5:
        operations.add(
          const _MachineScriptOp(kind: _MachineScriptOpKind.forward),
        );
        break;
      case 6:
        operations.add(
          _MachineScriptOp(
            kind: _MachineScriptOpKind.delta,
            delta: next().isEven ? -1 : 1,
          ),
        );
        break;
    }
  }
  return operations;
}

Future<_MachineScenarioSnapshot> _runScenarioWithOperations(
  WidgetTester tester,
  List<_MachineScriptOp> operations,
) async {
  UnrouterMachine<_AppRoute>? machine;
  final pendingPushResults = <Future<Object?>>[];

  final router = Unrouter<_AppRoute>(
    history: MemoryHistory(),
    routes: [
      route<_HomeRoute>(
        path: '/',
        parse: (_) => const _HomeRoute(),
        builder: (context, _) {
          machine ??= context.unrouterMachineAs<_AppRoute>();
          return const Text('home');
        },
      ),
      route<_UserRoute>(
        path: '/users/:id',
        parse: (state) => _UserRoute(id: state.pathInt('id')),
        builder: (_, route) => Text('user:${route.id}'),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  expect(machine, isNotNull);

  for (final operation in operations) {
    _dispatchScriptOp(
      machine!,
      operation,
      pendingPushResults: pendingPushResults,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }
  await tester.pumpAndSettle();

  final transitions = machine!.timeline
      .map(
        (entry) => <String, Object?>{
          'source': entry.source.name,
          'event': entry.event.name,
          'fromUri': entry.from.uri.toString(),
          'toUri': entry.to.uri.toString(),
          'toResolution': entry.to.resolution.name,
          'toAction': entry.to.historyAction.name,
          'toHistoryIndex': entry.to.historyIndex,
          'toRoutePath': entry.to.routePath,
        },
      )
      .toList(growable: false);
  final finalState = machine!.state.toJson();

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();

  await Future.wait(
    pendingPushResults.map(
      (future) =>
          future.timeout(const Duration(seconds: 1), onTimeout: () => null),
    ),
  );

  return _MachineScenarioSnapshot(
    transitions: transitions,
    finalState: finalState,
  );
}

void _dispatchScriptOp(
  UnrouterMachine<_AppRoute> machine,
  _MachineScriptOp operation, {
  required List<Future<Object?>> pendingPushResults,
}) {
  switch (operation.kind) {
    case _MachineScriptOpKind.go:
      machine.dispatch<void>(UnrouterMachineCommand.goUri(operation.uri!));
      break;
    case _MachineScriptOpKind.replace:
      machine.dispatch<void>(UnrouterMachineCommand.replaceUri(operation.uri!));
      break;
    case _MachineScriptOpKind.push:
      pendingPushResults.add(
        machine.dispatch<Future<Object?>>(
          UnrouterMachineCommand.pushUri(operation.uri!),
        ),
      );
      break;
    case _MachineScriptOpKind.pop:
      machine.dispatch<bool>(UnrouterMachineCommand.pop(operation.result));
      break;
    case _MachineScriptOpKind.back:
      machine.dispatch<bool>(UnrouterMachineCommand.back());
      break;
    case _MachineScriptOpKind.forward:
      machine.dispatch<void>(UnrouterMachineCommand.forward());
      break;
    case _MachineScriptOpKind.delta:
      machine.dispatch<void>(UnrouterMachineCommand.goDelta(operation.delta!));
      break;
  }
}

sealed class _AppRoute implements RouteData {
  const _AppRoute();
}

final class _HomeRoute extends _AppRoute {
  const _HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class _UserRoute extends _AppRoute {
  const _UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}
