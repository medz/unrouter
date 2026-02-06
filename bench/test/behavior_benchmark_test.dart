@Tags(<String>['router-bench', 'behavior'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'src/router_bench_harness.dart';

void main() {
  group('Router differential benchmark (behavior)', () {
    testWidgets('shared navigation semantics parity', (tester) async {
      const expectedCheckpoints = <String>[
        '/',
        '/users/1',
        '/users/1',
        '/users/2',
        '/users/2',
      ];
      const expectedPushResults = <Object?>[7, null];

      final snapshots = <BehaviorSnapshot>[];
      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          final snapshot = await runSharedNavigationScript(harness, tester);
          expect(snapshot.checkpoints, expectedCheckpoints);
          expect(snapshot.pushResults, expectedPushResults);
          snapshots.add(snapshot);
        } finally {
          await harness.detach(tester);
        }
      }

      final base = snapshots.first;
      for (final snapshot in snapshots.skip(1)) {
        expect(
          snapshot.checkpoints,
          base.checkpoints,
          reason:
              'Behavior mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
        expect(
          snapshot.pushResults,
          base.pushResults,
          reason:
              'Push-result mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
      }
    });

    testWidgets('redirect semantics parity', (tester) async {
      const expectedLocation = '/users/9';
      final snapshots = <(String routerName, String location)>[];

      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          final location = await runRedirectScript(harness, tester);
          expect(location, expectedLocation);
          snapshots.add((harness.routerName, location));
        } finally {
          await harness.detach(tester);
        }
      }

      final base = snapshots.first;
      for (final snapshot in snapshots.skip(1)) {
        expect(
          snapshot.$2,
          base.$2,
          reason: 'Redirect mismatch between ${base.$1} and ${snapshot.$1}',
        );
      }
    });

    testWidgets('guard redirect semantics parity', (tester) async {
      const expectedLocation = '/login';
      final snapshots = <(String routerName, String location)>[];

      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          final location = await runGuardRedirectScript(harness, tester);
          expect(location, expectedLocation);
          snapshots.add((harness.routerName, location));
        } finally {
          await harness.detach(tester);
        }
      }

      final base = snapshots.first;
      for (final snapshot in snapshots.skip(1)) {
        expect(
          snapshot.$2,
          base.$2,
          reason: 'Guard mismatch between ${base.$1} and ${snapshot.$1}',
        );
      }
    });
  });
}
