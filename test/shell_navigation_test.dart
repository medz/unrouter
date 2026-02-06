import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  testWidgets('shell branch switch keeps full branch stack', (tester) async {
    final router = _buildShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('a-home'), findsOneWidget);
    expect(find.text('branch:0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-a-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-a-edit')));
    await tester.pumpAndSettle();

    expect(find.text('a-edit'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/edit');

    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-b-detail')));
    await tester.pumpAndSettle();

    expect(find.text('b-detail'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/b/detail');

    await tester.tap(find.byKey(const Key('to-a')));
    await tester.pumpAndSettle();

    expect(find.text('a-edit'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/edit');

    await tester.tap(find.byKey(const Key('pop-branch')));
    await tester.pumpAndSettle();

    expect(find.text('a-detail'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/detail');

    await tester.tap(find.byKey(const Key('pop-branch')));
    await tester.pumpAndSettle();

    expect(find.text('a-home'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a');
    expect(find.text('can-pop:false'), findsOneWidget);
  });

  testWidgets('popRoute prioritizes active shell branch stack', (tester) async {
    final router = _buildShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-a-edit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-b-detail')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('to-a')));
    await tester.pumpAndSettle();

    expect(find.text('a-edit'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/edit');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('a-detail'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/detail');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('a-home'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a');
  });

  testWidgets('shell can force a branch initial location', (tester) async {
    final router = _buildShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-a-edit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('to-a-initial')));
    await tester.pumpAndSettle();

    expect(find.text('a-home'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a');
  });

  testWidgets('mixed shell/non-shell navigation preserves branch stack', (
    tester,
  ) async {
    final router = _buildShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-a-edit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('to-about')));
    await tester.pumpAndSettle();

    expect(find.text('about'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/about');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('a-edit'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/edit');

    await tester.tap(find.byKey(const Key('pop-branch')));
    await tester.pumpAndSettle();

    expect(find.text('a-detail'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/detail');
  });

  testWidgets('restores shell branch stacks from persisted history state', (
    tester,
  ) async {
    final firstRouter = _buildShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: firstRouter));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-a-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-b-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('to-a')));
    await tester.pumpAndSettle();

    expect(find.text('a-edit'), findsOneWidget);

    final restoredLocation = HistoryLocation(
      firstRouter.routeInformationProvider.value.uri,
      firstRouter.routeInformationProvider.value.state,
    );
    final restoredRouter = _buildShellRouter(
      history: MemoryHistory(initialEntries: [restoredLocation]),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: restoredRouter));
    await tester.pumpAndSettle();

    expect(find.text('a-edit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pop-branch')));
    await tester.pumpAndSettle();

    expect(find.text('a-detail'), findsOneWidget);
    expect(restoredRouter.routeInformationProvider.value.uri.path, '/a/detail');

    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();

    expect(find.text('b-detail'), findsOneWidget);
    expect(restoredRouter.routeInformationProvider.value.uri.path, '/b/detail');
  });

  testWidgets('restores branch stacks across repeated router recreation', (
    tester,
  ) async {
    final seedRouter = _buildShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: seedRouter));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-a-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-b-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('to-a')));
    await tester.pumpAndSettle();

    var location = HistoryLocation(
      seedRouter.routeInformationProvider.value.uri,
      seedRouter.routeInformationProvider.value.state,
    );

    for (var i = 0; i < 3; i++) {
      final router = _buildShellRouter(
        history: MemoryHistory(initialEntries: [location]),
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('a-edit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('to-b')));
      await tester.pumpAndSettle();
      expect(find.text('b-detail'), findsOneWidget);

      await tester.tap(find.byKey(const Key('to-a')));
      await tester.pumpAndSettle();
      expect(find.text('a-edit'), findsOneWidget);

      location = HistoryLocation(
        router.routeInformationProvider.value.uri,
        router.routeInformationProvider.value.state,
      );
    }
  });

  testWidgets('browser-style forward jumps keep shell branch stacks aligned', (
    tester,
  ) async {
    final router = _buildShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-a-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-b-detail')));
    await tester.pumpAndSettle();

    router.routeInformationProvider.back();
    await tester.pumpAndSettle();
    expect(find.text('b-home'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/b');

    router.routeInformationProvider.back();
    await tester.pumpAndSettle();
    expect(find.text('a-detail'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/a/detail');

    router.routeInformationProvider.forward();
    await tester.pumpAndSettle();
    expect(find.text('b-home'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/b');

    router.routeInformationProvider.forward();
    await tester.pumpAndSettle();
    expect(find.text('b-detail'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/b/detail');

    await tester.tap(find.byKey(const Key('to-a')));
    await tester.pumpAndSettle();
    expect(find.text('a-edit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('to-b')));
    await tester.pumpAndSettle();
    expect(find.text('b-detail'), findsOneWidget);
  });

  testWidgets(
    'restores long-lived mixed history checkpoints with branch stack parity',
    (tester) async {
      final router = _buildShellRouter();

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final checkpoints = <_ShellRestorationCheckpoint>[];

      void captureCheckpoint(String label) {
        final value = router.routeInformationProvider.value;
        final shell = _parseShellEnvelope(value.state);
        checkpoints.add(
          _ShellRestorationCheckpoint(
            label: label,
            location: HistoryLocation(value.uri, value.state),
            path: value.uri.path,
            activeBranchIndex: shell?.activeBranchIndex,
            branchTopPaths: shell?.branchTopPaths ?? const <int, String>{},
          ),
        );
      }

      await tester.tap(find.byKey(const Key('go-a-detail')));
      await tester.pumpAndSettle();
      captureCheckpoint('a-detail');

      await tester.tap(find.byKey(const Key('go-a-edit')));
      await tester.pumpAndSettle();
      captureCheckpoint('a-edit');

      await tester.tap(find.byKey(const Key('to-b')));
      await tester.pumpAndSettle();
      captureCheckpoint('switch-b-home');

      await tester.tap(find.byKey(const Key('go-b-detail')));
      await tester.pumpAndSettle();
      captureCheckpoint('b-detail');

      await tester.tap(find.byKey(const Key('to-about')));
      await tester.pumpAndSettle();
      captureCheckpoint('about-pushed');

      router.routeInformationProvider.back();
      await tester.pumpAndSettle();
      captureCheckpoint('about-back-to-b-detail');

      await tester.tap(find.byKey(const Key('to-a')));
      await tester.pumpAndSettle();
      captureCheckpoint('switch-a-edit');

      await tester.tap(find.byKey(const Key('pop-branch')));
      await tester.pumpAndSettle();
      captureCheckpoint('a-detail-after-pop-branch');

      router.routeInformationProvider.forward();
      await tester.pumpAndSettle();
      captureCheckpoint('forward-to-about');

      router.routeInformationProvider.back();
      await tester.pumpAndSettle();
      captureCheckpoint('back-to-a-detail');

      await tester.tap(find.byKey(const Key('to-b')));
      await tester.pumpAndSettle();
      captureCheckpoint('switch-b-detail');

      expect(checkpoints.length, greaterThanOrEqualTo(10));

      for (final checkpoint in checkpoints) {
        final restoredRouter = _buildShellRouter(
          history: MemoryHistory(initialEntries: [checkpoint.location]),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: restoredRouter),
        );
        await tester.pumpAndSettle();

        expect(
          restoredRouter.routeInformationProvider.value.uri.path,
          checkpoint.path,
          reason: 'checkpoint=${checkpoint.label}',
        );

        final expectedActiveBranch = checkpoint.activeBranchIndex;
        if (expectedActiveBranch != null && checkpoint.path != '/about') {
          expect(
            find.text('branch:$expectedActiveBranch'),
            findsOneWidget,
            reason: 'checkpoint=${checkpoint.label}',
          );
        }

        if (checkpoint.path == '/about') {
          expect(find.text('about'), findsOneWidget);
          continue;
        }

        final expectedA = checkpoint.branchTopPaths[0];
        if (expectedA != null) {
          await tester.tap(find.byKey(const Key('to-a')));
          await tester.pumpAndSettle();
          expect(
            restoredRouter.routeInformationProvider.value.uri.path,
            expectedA,
            reason: 'checkpoint=${checkpoint.label} branch=0',
          );
        }

        final expectedB = checkpoint.branchTopPaths[1];
        if (expectedB != null) {
          await tester.tap(find.byKey(const Key('to-b')));
          await tester.pumpAndSettle();
          expect(
            restoredRouter.routeInformationProvider.value.uri.path,
            expectedB,
            reason: 'checkpoint=${checkpoint.label} branch=1',
          );
        }
      }
    },
  );

  testWidgets('shell popBranch completes push result with provided value', (
    tester,
  ) async {
    late Future<int?> pushResult;
    final router = _buildShellResultRouter((result) {
      pushResult = result;
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail-result')));
    await tester.pumpAndSettle();

    expect(find.text('a-detail'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pop-branch-result')));
    await tester.pumpAndSettle();

    await expectLater(pushResult, completion(7));
    expect(find.text('a-home'), findsOneWidget);
  });

  testWidgets(
    'system back prioritizes shell branch pop and completes push result',
    (tester) async {
      late Future<int?> pushResult;
      final router = _buildShellResultRouter((result) {
        pushResult = result;
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('go-a-detail-result')));
      await tester.pumpAndSettle();

      expect(find.text('a-detail'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await expectLater(pushResult, completion(isNull));
      expect(find.text('a-home'), findsOneWidget);
    },
  );

  testWidgets(
    'shell goBranch can complete pending push result when requested',
    (tester) async {
      late Future<int?> pushResult;
      final router = _buildShellBranchSwitchResultRouter((result) {
        pushResult = result;
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('go-a-detail-switch-result')));
      await tester.pumpAndSettle();

      expect(find.text('a-detail'), findsOneWidget);

      await tester.tap(find.byKey(const Key('to-b-complete-result')));
      await tester.pumpAndSettle();

      expect(find.text('b-home'), findsOneWidget);
      await expectLater(pushResult, completion(11));
    },
  );

  testWidgets('shell goBranch preserves pending push result by default', (
    tester,
  ) async {
    late Future<int?> pushResult;
    var completed = false;

    final router = _buildShellBranchSwitchResultRouter((result) {
      pushResult = result;
      unawaited(
        result.then((_) {
          completed = true;
        }),
      );
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-a-detail-switch-result')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('to-b-preserve-result')));
    await tester.pumpAndSettle();

    expect(find.text('b-home'), findsOneWidget);
    expect(completed, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await expectLater(pushResult, completion(isNull));
    expect(completed, isTrue);
  });

  testWidgets('machine switchBranch preserves pending push result by default', (
    tester,
  ) async {
    UnrouterMachine<AppRoute>? machine;
    var completed = false;

    final router = _buildShellRouter(
      onMachineReady: (value) {
        machine ??= value;
      },
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(machine, isNotNull);

    final pending = machine!.dispatchTyped<Future<int?>>(
      UnrouterMachineCommand.pushUri<int>(Uri(path: '/a/detail')),
    );
    unawaited(
      pending.then((_) {
        completed = true;
      }),
    );
    await tester.pumpAndSettle();

    final switched = machine!.dispatchTyped<bool>(
      UnrouterMachineCommand.switchBranch(1),
    );
    expect(switched, isTrue);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/b');
    expect(completed, isFalse);

    machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(0));
    await tester.pumpAndSettle();
    machine!.dispatchTyped<bool>(UnrouterMachineCommand.popBranch());
    await tester.pumpAndSettle();

    await expectLater(pending, completion(isNull));
    expect(completed, isTrue);
  });

  testWidgets(
    'machine switchBranch can complete pending push result when requested',
    (tester) async {
      UnrouterMachine<AppRoute>? machine;
      final router = _buildShellRouter(
        onMachineReady: (value) {
          machine ??= value;
        },
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(machine, isNotNull);

      final pending = machine!.dispatchTyped<Future<int?>>(
        UnrouterMachineCommand.pushUri<int>(Uri(path: '/a/detail')),
      );
      await tester.pumpAndSettle();

      final switched = machine!.dispatchTyped<bool>(
        UnrouterMachineCommand.switchBranch(
          1,
          completePendingResult: true,
          result: 11,
        ),
      );
      expect(switched, isTrue);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/b');
      await expectLater(pending, completion(11));
    },
  );

  testWidgets('machine switchBranch initialLocation resets branch stack top', (
    tester,
  ) async {
    UnrouterMachine<AppRoute>? machine;
    final router = _buildShellRouter(
      onMachineReady: (value) {
        machine ??= value;
      },
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(machine, isNotNull);

    machine!.dispatchTyped<Future<Object?>>(
      UnrouterMachineCommand.pushUri(Uri(path: '/a/detail')),
    );
    await tester.pumpAndSettle();
    machine!.dispatchTyped<Future<Object?>>(
      UnrouterMachineCommand.pushUri(Uri(path: '/a/edit')),
    );
    await tester.pumpAndSettle();

    machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(1));
    await tester.pumpAndSettle();
    machine!.dispatchTyped<Future<Object?>>(
      UnrouterMachineCommand.pushUri(Uri(path: '/b/detail')),
    );
    await tester.pumpAndSettle();

    machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(0));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/a/edit');

    machine!.dispatchTyped<bool>(
      UnrouterMachineCommand.switchBranch(1, initialLocation: true),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/b');
    expect(
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.popBranch()),
      isFalse,
    );

    machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(0));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/a/edit');

    machine!.dispatchTyped<bool>(
      UnrouterMachineCommand.switchBranch(0, initialLocation: true),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/a');
  });

  testWidgets(
    'machine switchBranch supports initialLocation and result completion together',
    (tester) async {
      UnrouterMachine<AppRoute>? machine;
      final router = _buildShellRouter(
        onMachineReady: (value) {
          machine ??= value;
        },
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(machine, isNotNull);

      machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(1));
      await tester.pumpAndSettle();
      machine!.dispatchTyped<Future<Object?>>(
        UnrouterMachineCommand.pushUri(Uri(path: '/b/detail')),
      );
      await tester.pumpAndSettle();
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(0));
      await tester.pumpAndSettle();

      final pending = machine!.dispatchTyped<Future<int?>>(
        UnrouterMachineCommand.pushUri<int>(Uri(path: '/a/detail')),
      );
      await tester.pumpAndSettle();

      final switched = machine!.dispatchTyped<bool>(
        UnrouterMachineCommand.switchBranch(
          1,
          initialLocation: true,
          completePendingResult: true,
          result: 5,
        ),
      );
      expect(switched, isTrue);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/b');
      expect(
        machine!.dispatchTyped<bool>(UnrouterMachineCommand.popBranch()),
        isFalse,
      );
      await expectLater(pending, completion(5));
    },
  );

  testWidgets('machine action envelope classifies shell rejection codes', (
    tester,
  ) async {
    UnrouterMachine<AppRoute>? machine;
    final router = _buildShellRouter(
      onMachineReady: (value) {
        machine ??= value;
      },
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(machine, isNotNull);

    final unavailable = machine!.dispatchActionEnvelope<bool>(
      UnrouterMachineAction.switchBranch(99),
    );
    expect(unavailable.state, UnrouterMachineActionEnvelopeState.rejected);
    expect(
      unavailable.rejectCode,
      UnrouterMachineActionRejectCode.branchUnavailable,
    );
    expect(unavailable.rejectReason, isNotEmpty);
    expect(
      unavailable.failure?.category,
      UnrouterMachineActionFailureCategory.shell,
    );
    expect(unavailable.failure?.retryable, isFalse);

    final empty = machine!.dispatchActionEnvelope<bool>(
      UnrouterMachineAction.popBranch(),
    );
    expect(empty.state, UnrouterMachineActionEnvelopeState.rejected);
    expect(empty.rejectCode, UnrouterMachineActionRejectCode.branchEmpty);
    expect(empty.rejectReason, isNotEmpty);
    expect(empty.failure?.category, UnrouterMachineActionFailureCategory.shell);
    expect(empty.failure?.retryable, isTrue);

    final envelopeTail = machine!.timeline
        .where((entry) => entry.event == UnrouterMachineEvent.actionEnvelope)
        .toList(growable: false);
    expect(envelopeTail, hasLength(2));
    expect(
      envelopeTail.map((entry) => entry.payload['actionRejectCode']).toList(),
      <Object?>['branchUnavailable', 'branchEmpty'],
    );
    expect(
      envelopeTail
          .map((entry) => entry.payload['actionFailureCategory'])
          .toList(),
      <Object?>['shell', 'shell'],
    );
  });

  testWidgets(
    'shell machine command streams are deterministic across branch flows',
    (tester) async {
      final first = await _runShellMachineDeterminismScenario(tester);
      final second = await _runShellMachineDeterminismScenario(tester);

      expect(second.transitions, first.transitions);
      expect(second.finalMachineState, first.finalMachineState);
      expect(second.currentPath, first.currentPath);
      expect(second.activeBranchIndex, first.activeBranchIndex);
      expect(second.branchTopPaths, first.branchTopPaths);
      final events = first.transitions
          .map((entry) => entry['event'])
          .whereType<String>()
          .toSet();
      expect(events.contains('switchBranch'), isTrue);
      expect(events.contains('popBranch'), isTrue);
    },
  );
}

Unrouter<AppRoute> _buildShellRouter({
  History? history,
  ValueChanged<UnrouterMachine<AppRoute>>? onMachineReady,
}) {
  return Unrouter<AppRoute>(
    history:
        history ??
        MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/a'))]),
    routes: [
      ...shell<AppRoute>(
        branches: [
          branch<AppRoute>(
            initialLocation: Uri(path: '/a'),
            routes: [
              route<ABranchHomeRoute>(
                path: '/a',
                parse: (_) => const ABranchHomeRoute(),
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('a-home'),
                      TextButton(
                        key: const Key('go-a-detail'),
                        onPressed: () {
                          context.unrouter.push(const ADetailRoute());
                        },
                        child: const Text('to detail'),
                      ),
                    ],
                  );
                },
              ),
              route<ADetailRoute>(
                path: '/a/detail',
                parse: (_) => const ADetailRoute(),
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('a-detail'),
                      TextButton(
                        key: const Key('go-a-edit'),
                        onPressed: () {
                          context.unrouter.push(const AEditRoute());
                        },
                        child: const Text('to edit'),
                      ),
                    ],
                  );
                },
              ),
              route<AEditRoute>(
                path: '/a/edit',
                parse: (_) => const AEditRoute(),
                builder: (_, _) => const Text('a-edit'),
              ),
            ],
          ),
          branch<AppRoute>(
            initialLocation: Uri(path: '/b'),
            routes: [
              route<BHomeRoute>(
                path: '/b',
                parse: (_) => const BHomeRoute(),
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('b-home'),
                      TextButton(
                        key: const Key('go-b-detail'),
                        onPressed: () {
                          context.unrouter.push(const BDetailRoute());
                        },
                        child: const Text('to detail'),
                      ),
                    ],
                  );
                },
              ),
              route<BDetailRoute>(
                path: '/b/detail',
                parse: (_) => const BDetailRoute(),
                builder: (_, _) => const Text('b-detail'),
              ),
            ],
          ),
        ],
        builder: (context, shell, child) {
          onMachineReady?.call(context.unrouterMachineAs<AppRoute>());
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('branch:${shell.activeBranchIndex}'),
              Text('can-pop:${shell.canPopBranch}'),
              TextButton(
                key: const Key('to-a'),
                onPressed: () {
                  shell.goBranch(0);
                },
                child: const Text('A'),
              ),
              TextButton(
                key: const Key('to-a-initial'),
                onPressed: () {
                  shell.goBranch(0, initialLocation: true);
                },
                child: const Text('A initial'),
              ),
              TextButton(
                key: const Key('to-b'),
                onPressed: () {
                  shell.goBranch(1);
                },
                child: const Text('B'),
              ),
              TextButton(
                key: const Key('to-about'),
                onPressed: () {
                  context.unrouter.push(const AboutRoute());
                },
                child: const Text('About'),
              ),
              TextButton(
                key: const Key('pop-branch'),
                onPressed: () {
                  shell.popBranch();
                },
                child: const Text('Pop branch'),
              ),
              child,
            ],
          );
        },
      ),
      route<AboutRoute>(
        path: '/about',
        parse: (_) => const AboutRoute(),
        builder: (_, _) => const Text('about'),
      ),
    ],
  );
}

Unrouter<AppRoute> _buildShellResultRouter(
  void Function(Future<int?> result) onPushResult,
) {
  return Unrouter<AppRoute>(
    history: MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/a'))]),
    routes: [
      ...shell<AppRoute>(
        branches: [
          branch<AppRoute>(
            initialLocation: Uri(path: '/a'),
            routes: [
              route<ABranchHomeRoute>(
                path: '/a',
                parse: (_) => const ABranchHomeRoute(),
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('a-home'),
                      TextButton(
                        key: const Key('go-a-detail-result'),
                        onPressed: () {
                          onPushResult(
                            context.unrouter.push<int>(const ADetailRoute()),
                          );
                        },
                        child: const Text('to detail'),
                      ),
                    ],
                  );
                },
              ),
              route<ADetailRoute>(
                path: '/a/detail',
                parse: (_) => const ADetailRoute(),
                builder: (_, _) => const Text('a-detail'),
              ),
            ],
          ),
        ],
        builder: (context, shell, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                key: const Key('pop-branch-result'),
                onPressed: () {
                  shell.popBranch(7);
                },
                child: const Text('Pop branch with result'),
              ),
              child,
            ],
          );
        },
      ),
    ],
  );
}

Unrouter<AppRoute> _buildShellBranchSwitchResultRouter(
  void Function(Future<int?> result) onPushResult,
) {
  return Unrouter<AppRoute>(
    history: MemoryHistory(initialEntries: [HistoryLocation(Uri(path: '/a'))]),
    routes: [
      ...shell<AppRoute>(
        branches: [
          branch<AppRoute>(
            initialLocation: Uri(path: '/a'),
            routes: [
              route<ABranchHomeRoute>(
                path: '/a',
                parse: (_) => const ABranchHomeRoute(),
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('a-home'),
                      TextButton(
                        key: const Key('go-a-detail-switch-result'),
                        onPressed: () {
                          onPushResult(
                            context.unrouter.push<int>(const ADetailRoute()),
                          );
                        },
                        child: const Text('to detail'),
                      ),
                    ],
                  );
                },
              ),
              route<ADetailRoute>(
                path: '/a/detail',
                parse: (_) => const ADetailRoute(),
                builder: (_, _) => const Text('a-detail'),
              ),
            ],
          ),
          branch<AppRoute>(
            initialLocation: Uri(path: '/b'),
            routes: [
              route<BHomeRoute>(
                path: '/b',
                parse: (_) => const BHomeRoute(),
                builder: (_, _) => const Text('b-home'),
              ),
            ],
          ),
        ],
        builder: (_, shell, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                key: const Key('to-b-preserve-result'),
                onPressed: () {
                  shell.goBranch(1);
                },
                child: const Text('B preserve'),
              ),
              TextButton(
                key: const Key('to-b-complete-result'),
                onPressed: () {
                  shell.goBranch(1, completePendingResult: true, result: 11);
                },
                child: const Text('B complete'),
              ),
              child,
            ],
          );
        },
      ),
    ],
  );
}

Future<_ShellMachineDeterminismSnapshot> _runShellMachineDeterminismScenario(
  WidgetTester tester,
) async {
  UnrouterMachine<AppRoute>? machine;
  final router = _buildShellRouter(
    onMachineReady: (value) {
      machine ??= value;
    },
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  expect(machine, isNotNull);

  final steps = <void Function()>[
    () {
      machine!.dispatchTyped<Future<Object?>>(
        UnrouterMachineCommand.pushUri(Uri(path: '/a/detail')),
      );
    },
    () {
      machine!.dispatchTyped<Future<Object?>>(
        UnrouterMachineCommand.pushUri(Uri(path: '/a/edit')),
      );
    },
    () {
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(1));
    },
    () {
      machine!.dispatchTyped<Future<Object?>>(
        UnrouterMachineCommand.pushUri(Uri(path: '/b/detail')),
      );
    },
    () {
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.popBranch());
    },
    () {
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(0));
    },
    () {
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.popBranch());
    },
    () {
      machine!.dispatchTyped<bool>(
        UnrouterMachineCommand.switchBranch(1, initialLocation: true),
      );
    },
    () {
      machine!.dispatchTyped<Future<Object?>>(
        UnrouterMachineCommand.pushUri(Uri(path: '/about')),
      );
    },
    () {
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.back());
    },
    () {
      machine!.dispatchTyped<bool>(UnrouterMachineCommand.switchBranch(0));
    },
  ];

  for (final step in steps) {
    step();
    await tester.pumpAndSettle();
  }

  final value = router.routeInformationProvider.value;
  final shell = _parseShellEnvelope(value.state);
  final transitions = machine!.timeline
      .map(
        (entry) => <String, Object?>{
          'source': entry.source.name,
          'event': entry.event.name,
          'fromUri': entry.from.uri.toString(),
          'toUri': entry.to.uri.toString(),
          'toResolution': entry.to.resolution.name,
          'toHistoryAction': entry.to.historyAction.name,
          'toHistoryIndex': entry.to.historyIndex,
          'toRoutePath': entry.to.routePath,
        },
      )
      .toList(growable: false);

  final snapshot = _ShellMachineDeterminismSnapshot(
    transitions: transitions,
    finalMachineState: machine!.state.toJson(),
    currentPath: value.uri.path,
    activeBranchIndex: shell?.activeBranchIndex,
    branchTopPaths: shell?.branchTopPaths ?? const <int, String>{},
  );

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  return snapshot;
}

class _ShellMachineDeterminismSnapshot {
  const _ShellMachineDeterminismSnapshot({
    required this.transitions,
    required this.finalMachineState,
    required this.currentPath,
    required this.activeBranchIndex,
    required this.branchTopPaths,
  });

  final List<Map<String, Object?>> transitions;
  final Map<String, Object?> finalMachineState;
  final String currentPath;
  final int? activeBranchIndex;
  final Map<int, String> branchTopPaths;
}

class _ShellRestorationCheckpoint {
  const _ShellRestorationCheckpoint({
    required this.label,
    required this.location,
    required this.path,
    required this.activeBranchIndex,
    required this.branchTopPaths,
  });

  final String label;
  final HistoryLocation location;
  final String path;
  final int? activeBranchIndex;
  final Map<int, String> branchTopPaths;
}

class _ParsedShellEnvelope {
  const _ParsedShellEnvelope({
    required this.activeBranchIndex,
    required this.branchTopPaths,
  });

  final int activeBranchIndex;
  final Map<int, String> branchTopPaths;
}

_ParsedShellEnvelope? _parseShellEnvelope(Object? state) {
  if (state is! Map<Object?, Object?>) {
    return null;
  }

  final meta = state['__unrouter_meta__'];
  if (meta is! Map<Object?, Object?>) {
    return null;
  }
  if (meta['v'] != 1) {
    return null;
  }

  final shell = meta['shell'];
  if (shell is! Map<Object?, Object?>) {
    return null;
  }
  final activeBranchIndex = shell['activeBranchIndex'];
  if (activeBranchIndex is! int) {
    return null;
  }

  final rawStacks = shell['stacks'];
  if (rawStacks is! List<Object?>) {
    return null;
  }

  final branchTopPaths = <int, String>{};
  for (final rawStack in rawStacks) {
    if (rawStack is! Map<Object?, Object?>) {
      continue;
    }
    final branchIndex = rawStack['branchIndex'];
    final index = rawStack['index'];
    final entries = rawStack['entries'];
    if (branchIndex is! int || index is! int || entries is! List<Object?>) {
      continue;
    }
    if (entries.isEmpty) {
      continue;
    }

    final safeIndex = index.clamp(0, entries.length - 1);
    final rawUri = entries[safeIndex];
    if (rawUri is! String) {
      continue;
    }
    branchTopPaths[branchIndex] = Uri.parse(rawUri).path;
  }

  return _ParsedShellEnvelope(
    activeBranchIndex: activeBranchIndex,
    branchTopPaths: Map<int, String>.unmodifiable(branchTopPaths),
  );
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class ABranchHomeRoute extends AppRoute {
  const ABranchHomeRoute();

  @override
  Uri toUri() => Uri(path: '/a');
}

final class ADetailRoute extends AppRoute {
  const ADetailRoute();

  @override
  Uri toUri() => Uri(path: '/a/detail');
}

final class AEditRoute extends AppRoute {
  const AEditRoute();

  @override
  Uri toUri() => Uri(path: '/a/edit');
}

final class BHomeRoute extends AppRoute {
  const BHomeRoute();

  @override
  Uri toUri() => Uri(path: '/b');
}

final class BDetailRoute extends AppRoute {
  const BDetailRoute();

  @override
  Uri toUri() => Uri(path: '/b/detail');
}

final class AboutRoute extends AppRoute {
  const AboutRoute();

  @override
  Uri toUri() => Uri(path: '/about');
}
