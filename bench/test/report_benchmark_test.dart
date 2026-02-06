@Tags(<String>['router-bench', 'report'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/router_bench_harness.dart';

const int _performanceRounds = int.fromEnvironment(
  'UNROUTER_BENCH_ROUNDS',
  defaultValue: 24,
);
const int _longLivedRounds = int.fromEnvironment(
  'UNROUTER_BENCH_LONG_LIVED_ROUNDS',
  defaultValue: 40,
);
const String _reportPath = String.fromEnvironment(
  'UNROUTER_BENCH_REPORT_PATH',
  defaultValue: 'results/router_benchmark_latest.json',
);
const String _flutterVersion = String.fromEnvironment(
  'UNROUTER_BENCH_FLUTTER_VERSION',
  defaultValue: 'unknown',
);
const String _flutterChannel = String.fromEnvironment(
  'UNROUTER_BENCH_FLUTTER_CHANNEL',
  defaultValue: 'unknown',
);
const String _flutterRevision = String.fromEnvironment(
  'UNROUTER_BENCH_FLUTTER_REVISION',
  defaultValue: 'unknown',
);
const String _gitSha = String.fromEnvironment(
  'UNROUTER_BENCH_GIT_SHA',
  defaultValue: 'unknown',
);
const String _gitBranch = String.fromEnvironment(
  'UNROUTER_BENCH_GIT_BRANCH',
  defaultValue: 'unknown',
);

List<BehaviorSnapshot>? _sharedSnapshots;
List<(String routerName, String location)>? _redirectLocations;
List<(String routerName, String location)>? _guardLocations;
List<BehaviorSnapshot>? _nestedSnapshots;
List<BehaviorSnapshot>? _backForwardSnapshots;
List<LongLivedSnapshot>? _longLivedSnapshots;
List<PerformanceMetric>? _performanceMetrics;

void main() {
  group('Structured benchmark report', () {
    testWidgets('collect shared navigation behavior', (tester) async {
      _sharedSnapshots = await _runBehaviorSnapshots(
        tester,
        runSharedNavigationScript,
      );
    });

    testWidgets('collect redirect behavior', (tester) async {
      _redirectLocations = await _runLocationSnapshots(
        tester,
        runRedirectScript,
      );
    });

    testWidgets('collect guard redirect behavior', (tester) async {
      _guardLocations = await _runLocationSnapshots(
        tester,
        runGuardRedirectScript,
      );
    });

    testWidgets('collect nested behavior', (tester) async {
      _nestedSnapshots = await _runBehaviorSnapshots(
        tester,
        runNestedNavigationScript,
      );
    });

    testWidgets('collect browser-like back-forward behavior', (tester) async {
      _backForwardSnapshots = await _runBehaviorSnapshots(
        tester,
        runBackForwardNavigationScript,
      );
    });

    testWidgets('collect long-lived behavior', (tester) async {
      _longLivedSnapshots = await _runLongLivedSnapshots(
        tester,
        rounds: _longLivedRounds,
      );
    });

    testWidgets('collect performance metrics', (tester) async {
      _performanceMetrics = await _runPerformanceMetrics(
        tester,
        rounds: _performanceRounds,
      );
    });

    test('write report file', () async {
      final sharedSnapshots = _sharedSnapshots;
      final redirectLocations = _redirectLocations;
      final guardLocations = _guardLocations;
      final nestedSnapshots = _nestedSnapshots;
      final backForwardSnapshots = _backForwardSnapshots;
      final longLivedSnapshots = _longLivedSnapshots;
      final performanceMetrics = _performanceMetrics;

      expect(sharedSnapshots, isNotNull);
      expect(redirectLocations, isNotNull);
      expect(guardLocations, isNotNull);
      expect(nestedSnapshots, isNotNull);
      expect(backForwardSnapshots, isNotNull);
      expect(longLivedSnapshots, isNotNull);
      expect(performanceMetrics, isNotNull);

      final report = <String, Object?>{
        'schemaVersion': 1,
        'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'environment': <String, Object?>{
          'os': Platform.operatingSystem,
          'osVersion': Platform.operatingSystemVersion,
          'hostname': Platform.localHostname,
          'locale': Platform.localeName,
          'numberOfProcessors': Platform.numberOfProcessors,
          'isCi': Platform.environment.containsKey('CI'),
          'dartVersion': _extractDartVersion(Platform.version),
          'dartVersionRaw': Platform.version,
          'flutter': <String, Object?>{
            'version': _flutterVersion,
            'channel': _flutterChannel,
            'revision': _flutterRevision,
          },
        },
        'repository': <String, Object?>{
          'gitSha': _gitSha,
          'gitBranch': _gitBranch,
        },
        'config': <String, Object?>{
          'performanceRounds': _performanceRounds,
          'longLivedRounds': _longLivedRounds,
        },
        'behavior': <String, Object?>{
          'sharedNavigation': _buildBehaviorScriptReport(
            snapshots: sharedSnapshots!,
            expectedCheckpoints: const <String>[
              '/',
              '/users/1',
              '/users/1',
              '/users/2',
              '/users/2',
            ],
            expectedPushResults: const <Object?>[7, null],
          ),
          'redirect': _buildLocationScriptReport(
            locations: redirectLocations!,
            expectedLocation: '/users/9',
          ),
          'guardRedirect': _buildLocationScriptReport(
            locations: guardLocations!,
            expectedLocation: '/login',
          ),
          'nestedNavigation': _buildBehaviorScriptReport(
            snapshots: nestedSnapshots!,
            expectedCheckpoints: const <String>[
              '/',
              '/workspace/inbox',
              '/workspace/inbox',
              '/workspace/archive',
              '/workspace/archive',
            ],
            expectedPushResults: const <Object?>[11, null],
          ),
          'browserLikeBackForward': _buildBehaviorScriptReport(
            snapshots: backForwardSnapshots!,
            expectedCheckpoints: const <String>[
              '/',
              '/users/1',
              '/users/1',
              '/users/1',
            ],
            expectedPushResults: const <Object?>['back', 'forward'],
          ),
          'longLivedRestoration': _buildLongLivedReport(
            snapshots: longLivedSnapshots!,
            expectedRounds: _longLivedRounds,
            expectedResultChecksum: _sumIntegers(_longLivedRounds),
            expectedUserChecksum: _sumGeneratedUserIds(_longLivedRounds),
          ),
        },
        'performance': <String, Object?>{
          'rounds': _performanceRounds,
          'checksumMeaning':
              'Semantic checksum from stable go/pop/result/final-location checkpoints.',
          'metrics': performanceMetrics!
              .map(
                (metric) => <String, Object?>{
                  'router': metric.routerName,
                  'elapsedMs': metric.elapsed.inMilliseconds,
                  'averageMicrosPerRound': metric.averageMicrosPerRound,
                  'checksum': metric.checksum,
                },
              )
              .toList(growable: false),
          'parity': _hasPerformanceParity(performanceMetrics),
        },
      };

      final file = File(_reportPath);
      await file.parent.create(recursive: true);
      final content = const JsonEncoder.withIndent('  ').convert(report);
      await file.writeAsString('$content\n');

      debugPrint('[router-benchmark] report=${file.path}');
      expect(file.existsSync(), isTrue);
    });
  });
}

String _extractDartVersion(String raw) {
  final firstSpace = raw.indexOf(' ');
  if (firstSpace <= 0) {
    return raw;
  }
  return raw.substring(0, firstSpace);
}

Map<String, Object?> _buildBehaviorScriptReport({
  required List<BehaviorSnapshot> snapshots,
  required List<String> expectedCheckpoints,
  required List<Object?> expectedPushResults,
}) {
  final checkpointsParity = _hasSharedListParity(
    snapshots.map((snapshot) => snapshot.checkpoints).toList(growable: false),
  );
  final pushResultParity = _hasSharedListParity(
    snapshots.map((snapshot) => snapshot.pushResults).toList(growable: false),
  );

  final expectedMatch = snapshots.every((snapshot) {
    return _areListsEqual(snapshot.checkpoints, expectedCheckpoints) &&
        _areListsEqual(snapshot.pushResults, expectedPushResults);
  });

  return <String, Object?>{
    'parity': checkpointsParity && pushResultParity,
    'matchesExpected': expectedMatch,
    'expectedCheckpoints': expectedCheckpoints,
    'expectedPushResults': expectedPushResults,
    'routers': snapshots
        .map(
          (snapshot) => <String, Object?>{
            'router': snapshot.routerName,
            'checkpoints': snapshot.checkpoints,
            'pushResults': snapshot.pushResults,
          },
        )
        .toList(growable: false),
  };
}

Map<String, Object?> _buildLocationScriptReport({
  required List<(String routerName, String location)> locations,
  required String expectedLocation,
}) {
  final parity = _hasSharedValueParity(
    locations.map((location) => location.$2).toList(growable: false),
  );
  final matchesExpected = locations.every(
    (location) => location.$2 == expectedLocation,
  );

  return <String, Object?>{
    'parity': parity,
    'matchesExpected': matchesExpected,
    'expectedLocation': expectedLocation,
    'routers': locations
        .map(
          (location) => <String, Object?>{
            'router': location.$1,
            'location': location.$2,
          },
        )
        .toList(growable: false),
  };
}

Map<String, Object?> _buildLongLivedReport({
  required List<LongLivedSnapshot> snapshots,
  required int expectedRounds,
  required int expectedResultChecksum,
  required int expectedUserChecksum,
}) {
  final roundsParity = _hasSharedValueParity(
    snapshots.map((snapshot) => snapshot.rounds).toList(growable: false),
  );
  final locationParity = _hasSharedValueParity(
    snapshots.map((snapshot) => snapshot.finalLocation).toList(growable: false),
  );
  final resultParity = _hasSharedValueParity(
    snapshots
        .map((snapshot) => snapshot.resultChecksum)
        .toList(growable: false),
  );
  final userParity = _hasSharedValueParity(
    snapshots.map((snapshot) => snapshot.userChecksum).toList(growable: false),
  );

  final matchesExpected = snapshots.every((snapshot) {
    return snapshot.rounds == expectedRounds &&
        snapshot.finalLocation == '/' &&
        snapshot.resultChecksum == expectedResultChecksum &&
        snapshot.userChecksum == expectedUserChecksum;
  });

  return <String, Object?>{
    'parity': roundsParity && locationParity && resultParity && userParity,
    'matchesExpected': matchesExpected,
    'expected': <String, Object?>{
      'rounds': expectedRounds,
      'finalLocation': '/',
      'resultChecksum': expectedResultChecksum,
      'userChecksum': expectedUserChecksum,
    },
    'routers': snapshots
        .map(
          (snapshot) => <String, Object?>{
            'router': snapshot.routerName,
            'rounds': snapshot.rounds,
            'finalLocation': snapshot.finalLocation,
            'resultChecksum': snapshot.resultChecksum,
            'userChecksum': snapshot.userChecksum,
          },
        )
        .toList(growable: false),
  };
}

bool _hasPerformanceParity(List<PerformanceMetric> metrics) {
  return _hasSharedValueParity(
    metrics.map((metric) => metric.checksum).toList(growable: false),
  );
}

bool _hasSharedListParity<T>(List<List<T>> values) {
  if (values.length < 2) {
    return true;
  }
  final first = values.first;
  for (final value in values.skip(1)) {
    if (!_areListsEqual(first, value)) {
      return false;
    }
  }
  return true;
}

bool _hasSharedValueParity(List<Object?> values) {
  if (values.length < 2) {
    return true;
  }
  final first = values.first;
  for (final value in values.skip(1)) {
    if (value != first) {
      return false;
    }
  }
  return true;
}

bool _areListsEqual<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

Future<List<BehaviorSnapshot>> _runBehaviorSnapshots(
  WidgetTester tester,
  Future<BehaviorSnapshot> Function(
    RouterBenchHarness harness,
    WidgetTester tester,
  )
  runner,
) async {
  final snapshots = <BehaviorSnapshot>[];
  for (final harness in createHarnesses()) {
    await harness.attach(tester);
    try {
      snapshots.add(await runner(harness, tester));
    } finally {
      await harness.detach(tester);
    }
  }
  return snapshots;
}

Future<List<(String routerName, String location)>> _runLocationSnapshots(
  WidgetTester tester,
  Future<String> Function(RouterBenchHarness harness, WidgetTester tester)
  runner,
) async {
  final locations = <(String routerName, String location)>[];
  for (final harness in createHarnesses()) {
    await harness.attach(tester);
    try {
      locations.add((harness.routerName, await runner(harness, tester)));
    } finally {
      await harness.detach(tester);
    }
  }
  return locations;
}

Future<List<LongLivedSnapshot>> _runLongLivedSnapshots(
  WidgetTester tester, {
  required int rounds,
}) async {
  final snapshots = <LongLivedSnapshot>[];
  for (final harness in createHarnesses()) {
    await harness.attach(tester);
    try {
      snapshots.add(
        await runLongLivedRestorationScript(harness, tester, rounds: rounds),
      );
    } finally {
      await harness.detach(tester);
    }
  }
  return snapshots;
}

Future<List<PerformanceMetric>> _runPerformanceMetrics(
  WidgetTester tester, {
  required int rounds,
}) async {
  final metrics = <PerformanceMetric>[];
  for (final harness in createHarnesses()) {
    await harness.attach(tester);
    try {
      metrics.add(await runPerformanceScript(harness, tester, rounds: rounds));
    } finally {
      await harness.detach(tester);
    }
  }
  return metrics;
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
