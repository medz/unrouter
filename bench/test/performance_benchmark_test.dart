@Tags(<String>['router-bench', 'performance'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/router_bench_harness.dart';

void main() {
  group('Router differential benchmark (performance)', () {
    testWidgets('shared navigation performance baseline', (tester) async {
      const rounds = int.fromEnvironment(
        'UNROUTER_BENCH_ROUNDS',
        defaultValue: 24,
      );

      final metrics = <PerformanceMetric>[];
      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          metrics.add(
            await runPerformanceScript(harness, tester, rounds: rounds),
          );
        } finally {
          await harness.detach(tester);
        }
      }

      for (final metric in metrics) {
        debugPrint(
          '[router-benchmark] ${metric.routerName}: rounds=${metric.rounds}, '
          'elapsedMs=${metric.elapsed.inMilliseconds}, '
          'avgUs=${metric.averageMicrosPerRound.toStringAsFixed(1)}, '
          'checksum=${metric.checksum}',
        );
      }

      expect(metrics, hasLength(3));
      for (final metric in metrics) {
        expect(metric.rounds, rounds);
        expect(metric.checksum, greaterThan(0));
      }
    });
  });
}
