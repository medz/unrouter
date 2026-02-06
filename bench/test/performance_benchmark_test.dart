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
      const samples = int.fromEnvironment(
        'UNROUTER_BENCH_SAMPLES',
        defaultValue: 5,
      );

      final series = <PerformanceSeries>[];
      for (final harness in createHarnesses()) {
        await harness.attach(tester);
        try {
          series.add(
            await runPerformanceSeries(
              harness,
              tester,
              rounds: rounds,
              samples: samples,
            ),
          );
        } finally {
          await harness.detach(tester);
        }
      }

      for (final item in series) {
        debugPrint(
          '[router-benchmark] ${item.routerName}: samples=${item.sampleCount}, '
          'rounds=${item.rounds}, '
          'meanUs=${item.meanAverageMicrosPerRound.toStringAsFixed(1)}, '
          'p50Us=${item.p50AverageMicrosPerRound.toStringAsFixed(1)}, '
          'p95Us=${item.p95AverageMicrosPerRound.toStringAsFixed(1)}, '
          'checksumParity=${item.checksumParity}, '
          'checksum=${item.checksum ?? -1}',
        );
      }

      expect(series, hasLength(3));
      for (final item in series) {
        expect(item.rounds, rounds);
        expect(item.sampleCount, samples);
        expect(item.checksumParity, isTrue);
        expect(item.checksum, isNotNull);
        expect(item.meanAverageMicrosPerRound, greaterThan(0));
      }
      final firstChecksum = series.first.checksum;
      for (final item in series.skip(1)) {
        expect(item.checksum, firstChecksum);
      }
    });
  });
}
