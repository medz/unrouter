import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _parseOptions(args);
  final output = options['output'] ?? _defaultOutputPath();
  final rounds = options['rounds'] ?? '24';
  final samples = options['samples'] ?? '5';
  final longLivedRounds = options['long-lived-rounds'] ?? '40';
  final baseline = options['baseline'] ?? '';
  final thresholdPercent = options['threshold-percent'] ?? '15';
  final failOnRegression = options['fail-on-regression'] == 'true';

  final flutterInfo = await _readFlutterVersionInfo();
  final gitInfo = await _readGitInfo();

  final testArgs = <String>[
    'test',
    '--tags',
    'report',
    '--dart-define=UNROUTER_BENCH_REPORT_PATH=$output',
    '--dart-define=UNROUTER_BENCH_ROUNDS=$rounds',
    '--dart-define=UNROUTER_BENCH_SAMPLES=$samples',
    '--dart-define=UNROUTER_BENCH_LONG_LIVED_ROUNDS=$longLivedRounds',
    '--dart-define=UNROUTER_BENCH_BASELINE_REPORT_PATH=$baseline',
    '--dart-define=UNROUTER_BENCH_REGRESSION_THRESHOLD_PERCENT=$thresholdPercent',
    '--dart-define=UNROUTER_BENCH_FLUTTER_VERSION=${flutterInfo.version}',
    '--dart-define=UNROUTER_BENCH_FLUTTER_CHANNEL=${flutterInfo.channel}',
    '--dart-define=UNROUTER_BENCH_FLUTTER_REVISION=${flutterInfo.revision}',
    '--dart-define=UNROUTER_BENCH_GIT_SHA=${gitInfo.sha}',
    '--dart-define=UNROUTER_BENCH_GIT_BRANCH=${gitInfo.branch}',
  ];

  stdout.writeln(
    '[router-benchmark] generating report: output=$output, rounds=$rounds, samples=$samples, longLivedRounds=$longLivedRounds',
  );
  final testProcess = await Process.start(
    'flutter',
    testArgs,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await testProcess.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }

  final outputFile = File(output);
  if (!outputFile.existsSync()) {
    stderr.writeln(
      '[router-benchmark] report was not generated at expected path: $output',
    );
    exit(1);
  }

  final regression = await _readRegressionSummary(outputFile);
  if (regression != null && regression.enabled) {
    stdout.writeln(
      '[router-benchmark] regression check: baseline=${regression.baselinePath}, threshold=${regression.thresholdPercent.toStringAsFixed(1)}%',
    );
    if (regression.error != null) {
      stdout.writeln(
        '[router-benchmark] regression check skipped: ${regression.error}',
      );
    } else if (regression.entries.isEmpty) {
      stdout.writeln('[router-benchmark] regression check: no regressions');
    } else {
      for (final entry in regression.entries) {
        final p50Status = entry.p50Regressed ? 'regressed' : 'ok';
        final p95Status = entry.p95Regressed ? 'regressed' : 'ok';
        stdout.writeln(
          '[router-benchmark] regression: router=${entry.router}, '
          'p50[$p50Status]=${entry.currentP50.toStringAsFixed(1)} '
          '(limit=${entry.limitP50.toStringAsFixed(1)}, baseline=${entry.baselineP50.toStringAsFixed(1)}), '
          'p95[$p95Status]=${entry.currentP95.toStringAsFixed(1)} '
          '(limit=${entry.limitP95.toStringAsFixed(1)}, baseline=${entry.baselineP95.toStringAsFixed(1)})',
        );
      }
      if (failOnRegression) {
        stderr.writeln(
          '[router-benchmark] regression threshold exceeded and --fail-on-regression was set',
        );
        exit(2);
      }
    }
  }

  stdout.writeln('[router-benchmark] report ready: $output');
}

Map<String, String> _parseOptions(List<String> args) {
  final options = <String, String>{};
  for (final arg in args) {
    if (arg.startsWith('--output=')) {
      options['output'] = arg.substring('--output='.length);
      continue;
    }
    if (arg.startsWith('--rounds=')) {
      options['rounds'] = arg.substring('--rounds='.length);
      continue;
    }
    if (arg.startsWith('--samples=')) {
      options['samples'] = arg.substring('--samples='.length);
      continue;
    }
    if (arg.startsWith('--long-lived-rounds=')) {
      options['long-lived-rounds'] = arg.substring(
        '--long-lived-rounds='.length,
      );
      continue;
    }
    if (arg.startsWith('--baseline=')) {
      options['baseline'] = arg.substring('--baseline='.length);
      continue;
    }
    if (arg.startsWith('--threshold-percent=')) {
      options['threshold-percent'] = arg.substring(
        '--threshold-percent='.length,
      );
      continue;
    }
    if (arg == '--fail-on-regression') {
      options['fail-on-regression'] = 'true';
      continue;
    }
  }
  return options;
}

String _defaultOutputPath() {
  final now = DateTime.now().toUtc();
  final stamp = now.toIso8601String().replaceAll(':', '-');
  return 'results/router_benchmark_$stamp.json';
}

Future<_FlutterVersionInfo> _readFlutterVersionInfo() async {
  final result = await Process.run('flutter', ['--version', '--machine']);
  if (result.exitCode != 0) {
    return const _FlutterVersionInfo.unknown();
  }

  final raw = result.stdout is String
      ? result.stdout as String
      : utf8.decode(result.stdout as List<int>);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const _FlutterVersionInfo.unknown();
    }
    return _FlutterVersionInfo(
      version: _stringOrUnknown(decoded['frameworkVersion']),
      channel: _stringOrUnknown(decoded['channel']),
      revision: _stringOrUnknown(decoded['frameworkRevision']),
    );
  } catch (_) {
    return const _FlutterVersionInfo.unknown();
  }
}

Future<_GitInfo> _readGitInfo() async {
  final shaResult = await Process.run('git', ['rev-parse', 'HEAD']);
  final branchResult = await Process.run('git', [
    'rev-parse',
    '--abbrev-ref',
    'HEAD',
  ]);
  return _GitInfo(
    sha: _extractProcessValue(shaResult),
    branch: _extractProcessValue(branchResult),
  );
}

String _extractProcessValue(ProcessResult result) {
  if (result.exitCode != 0) {
    return 'unknown';
  }
  final raw = result.stdout is String
      ? result.stdout as String
      : utf8.decode(result.stdout as List<int>);
  final value = raw.trim();
  if (value.isEmpty) {
    return 'unknown';
  }
  return value;
}

String _stringOrUnknown(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return 'unknown';
}

Future<_RegressionSummary?> _readRegressionSummary(File reportFile) async {
  final raw = await reportFile.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final regression = decoded['regression'];
  if (regression is! Map<String, dynamic>) {
    return null;
  }

  final enabled = regression['enabled'] == true;
  final baselinePath = regression['baselinePath'];
  final threshold = regression['thresholdPercent'];
  final error = regression['error'];
  final entriesRaw = regression['regressions'];

  final entries = <_RegressionEntry>[];
  if (entriesRaw is List) {
    for (final entry in entriesRaw) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final baseline = entry['baseline'];
      final current = entry['current'];
      final thresholdData = entry['threshold'];
      if (baseline is! Map ||
          current is! Map ||
          thresholdData is! Map ||
          entry['router'] is! String) {
        continue;
      }

      final baselineP50 = _toDouble(baseline['p50AverageMicrosPerRound']);
      final baselineP95 = _toDouble(baseline['p95AverageMicrosPerRound']);
      final currentP50 = _toDouble(current['p50AverageMicrosPerRound']);
      final currentP95 = _toDouble(current['p95AverageMicrosPerRound']);
      final limitP50 = _toDouble(thresholdData['p50Limit']);
      final limitP95 = _toDouble(thresholdData['p95Limit']);
      if (baselineP50 == null ||
          baselineP95 == null ||
          currentP50 == null ||
          currentP95 == null ||
          limitP50 == null ||
          limitP95 == null) {
        continue;
      }

      entries.add(
        _RegressionEntry(
          router: entry['router'] as String,
          baselineP50: baselineP50,
          baselineP95: baselineP95,
          currentP50: currentP50,
          currentP95: currentP95,
          limitP50: limitP50,
          limitP95: limitP95,
          p50Regressed: entry['p50Regressed'] == true,
          p95Regressed: entry['p95Regressed'] == true,
        ),
      );
    }
  }

  return _RegressionSummary(
    enabled: enabled,
    baselinePath: baselinePath is String ? baselinePath : '',
    thresholdPercent: _toDouble(threshold) ?? 0,
    error: error is String ? error : null,
    entries: entries,
  );
}

double? _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

class _FlutterVersionInfo {
  const _FlutterVersionInfo({
    required this.version,
    required this.channel,
    required this.revision,
  });

  const _FlutterVersionInfo.unknown()
    : version = 'unknown',
      channel = 'unknown',
      revision = 'unknown';

  final String version;
  final String channel;
  final String revision;
}

class _GitInfo {
  const _GitInfo({required this.sha, required this.branch});

  final String sha;
  final String branch;
}

class _RegressionSummary {
  const _RegressionSummary({
    required this.enabled,
    required this.baselinePath,
    required this.thresholdPercent,
    required this.error,
    required this.entries,
  });

  final bool enabled;
  final String baselinePath;
  final double thresholdPercent;
  final String? error;
  final List<_RegressionEntry> entries;
}

class _RegressionEntry {
  const _RegressionEntry({
    required this.router,
    required this.baselineP50,
    required this.baselineP95,
    required this.currentP50,
    required this.currentP95,
    required this.limitP50,
    required this.limitP95,
    required this.p50Regressed,
    required this.p95Regressed,
  });

  final String router;
  final double baselineP50;
  final double baselineP95;
  final double currentP50;
  final double currentP95;
  final double limitP50;
  final double limitP95;
  final bool p50Regressed;
  final bool p95Regressed;
}
