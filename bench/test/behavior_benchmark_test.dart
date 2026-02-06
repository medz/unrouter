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

    testWidgets('nested navigation semantics parity', (tester) async {
      const expectedCheckpoints = <String>[
        '/',
        '/workspace/inbox',
        '/workspace/inbox',
        '/workspace/archive',
        '/workspace/archive',
      ];
      const expectedPushResults = <Object?>[11, null];

      final snapshots = <BehaviorSnapshot>[];
      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          final snapshot = await runNestedNavigationScript(harness, tester);
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
              'Nested behavior mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
        expect(
          snapshot.pushResults,
          base.pushResults,
          reason:
              'Nested push-result mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
      }
    });

    testWidgets('browser-like back-forward parity', (tester) async {
      const expectedCheckpoints = <String>[
        '/',
        '/users/1',
        '/users/1',
        '/users/1',
      ];
      const expectedPushResults = <Object?>['back', 'forward'];

      final snapshots = <BehaviorSnapshot>[];
      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          final snapshot = await runBackForwardNavigationScript(
            harness,
            tester,
          );
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
              'Back-forward mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
        expect(
          snapshot.pushResults,
          base.pushResults,
          reason:
              'Back-forward result mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
      }
    });

    testWidgets('long-lived restoration parity', (tester) async {
      const rounds = 40;
      final expectedResultChecksum = _sumIntegers(rounds);
      final expectedUserChecksum = _sumGeneratedUserIds(rounds);

      final snapshots = <LongLivedSnapshot>[];
      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          final snapshot = await runLongLivedRestorationScript(
            harness,
            tester,
            rounds: rounds,
          );
          expect(snapshot.rounds, rounds);
          expect(snapshot.finalLocation, '/');
          expect(snapshot.resultChecksum, expectedResultChecksum);
          expect(snapshot.userChecksum, expectedUserChecksum);
          snapshots.add(snapshot);
        } finally {
          await harness.detach(tester);
        }
      }

      final base = snapshots.first;
      for (final snapshot in snapshots.skip(1)) {
        expect(
          snapshot.finalLocation,
          base.finalLocation,
          reason:
              'Long-lived final location mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
        expect(
          snapshot.resultChecksum,
          base.resultChecksum,
          reason:
              'Long-lived result checksum mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
        expect(
          snapshot.userChecksum,
          base.userChecksum,
          reason:
              'Long-lived user checksum mismatch between ${base.routerName} and ${snapshot.routerName}',
        );
      }
    });
  });
}

int _sumIntegers(int value) {
  return (value * (value + 1)) ~/ 2;
}

int _sumGeneratedUserIds(int rounds) {
  var sum = 0;
  for (var i = 1; i <= rounds; i++) {
    sum += ((i * 3) % 9) + 1;
  }
  return sum;
}
