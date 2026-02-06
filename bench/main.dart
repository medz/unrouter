import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coal/args.dart';
import 'package:coal/coal.dart';

final RegExp _ansiEscapePattern = RegExp(r'\x1B\[[0-9;]*m');
final RegExp _behaviorPattern = RegExp(
  r'^\[router-benchmark\]\[behavior\]\s+script=([a-zA-Z0-9_]+)\s+parity=(true|false)\s+expected=(true|false)$',
);
final RegExp _performancePattern = RegExp(
  r'^\[router-benchmark\]\[performance\]\s+router=([a-zA-Z0-9_]+)\s+samples=(\d+)\s+rounds=(\d+)\s+meanUs=([0-9]+(?:\.[0-9]+)?)\s+p50Us=([0-9]+(?:\.[0-9]+)?)\s+p95Us=([0-9]+(?:\.[0-9]+)?)\s+checksumParity=(true|false)\s+checksum=(-?\d+)$',
);

const List<String> _behaviorScriptOrder = <String>[
  'sharedNavigation',
  'redirect',
  'guardRedirect',
  'nestedNavigation',
  'browserLikeBackForward',
  'longLivedRestoration',
];

Future<void> main(List<String> rawArgs) async {
  final defaultProfile = _deriveDefaultProfile();
  final parsed = Args.parse(
    rawArgs,
    defaults: <String, Object?>{
      'rounds': defaultProfile.rounds.toString(),
      'samples': defaultProfile.samples.toString(),
      'warmup-rounds': defaultProfile.warmupRounds.toString(),
      'warmup-samples': defaultProfile.warmupSamples.toString(),
      'performance-runs': defaultProfile.performanceRuns.toString(),
      'long-lived-rounds': defaultProfile.longLivedRounds.toString(),
      'behavior-only': false,
      'performance-only': false,
      'verbose': false,
      'help': false,
    },
    aliases: <String, String>{
      'r': 'rounds',
      's': 'samples',
      'w': 'warmup-rounds',
      'x': 'warmup-samples',
      'n': 'performance-runs',
      'l': 'long-lived-rounds',
      'b': 'behavior-only',
      'p': 'performance-only',
      'v': 'verbose',
      'h': 'help',
    },
    bool: const <String>[
      'behavior-only',
      'performance-only',
      'verbose',
      'help',
    ],
    string: const <String>[
      'rounds',
      'samples',
      'warmup-rounds',
      'warmup-samples',
      'performance-runs',
      'long-lived-rounds',
    ],
  );

  if (_readBool(parsed, 'help')) {
    stdout.writeln(_usage(defaultProfile));
    return;
  }

  final config = _parseConfig(parsed, defaultProfile);
  if (config == null) {
    stderr.writeln(_usage(defaultProfile));
    exit(64);
  }

  stdout.writeln(
    '[router-benchmark] rounds=${config.rounds}, samples=${config.samples}, '
    'warmupRounds=${config.warmupRounds}, warmupSamples=${config.warmupSamples}, '
    'performanceRuns=${config.performanceRuns}, longLivedRounds=${config.longLivedRounds}, '
    'behavior=${config.runBehavior}, performance=${config.runPerformance}, '
    'profile=${config.defaultProfile.name}, cpu=${config.defaultProfile.cpuCount}',
  );

  final stopwatch = Stopwatch()..start();
  final behavior = config.runBehavior
      ? await _runBehaviorSuite(config)
      : const _BehaviorRunResult.skipped();
  final performance = config.runPerformance
      ? await _runPerformanceSuite(config)
      : const _PerformanceRunResult.skipped();
  stopwatch.stop();

  stdout.writeln(
    _renderSummary(
      config: config,
      behavior: behavior,
      performance: performance,
      elapsed: stopwatch.elapsed,
    ),
  );

  if (!config.verbose) {
    if (!behavior.passed) {
      _printFailureTail('Behavior', behavior.lines);
    }
    if (!performance.passed) {
      _printFailureTail('Performance', performance.lines);
    }
  }

  if (!behavior.passed || !performance.passed) {
    exit(1);
  }
}

_BenchConfig? _parseConfig(Args args, _BenchDefaultProfile defaults) {
  final behaviorOnly = _readBool(args, 'behavior-only');
  final performanceOnly = _readBool(args, 'performance-only');
  final verbose = _readBool(args, 'verbose');
  if (behaviorOnly && performanceOnly) {
    stderr.writeln(
      '[router-benchmark] --behavior-only and --performance-only cannot be used together',
    );
    return null;
  }

  final rounds = _parsePositiveInt(
    _readString(args, 'rounds', defaults.rounds.toString()),
    'rounds',
  );
  final samples = _parsePositiveInt(
    _readString(args, 'samples', defaults.samples.toString()),
    'samples',
  );
  final warmupRounds = _parseNonNegativeInt(
    _readString(args, 'warmup-rounds', defaults.warmupRounds.toString()),
    'warmup-rounds',
  );
  final warmupSamples = _parseNonNegativeInt(
    _readString(args, 'warmup-samples', defaults.warmupSamples.toString()),
    'warmup-samples',
  );
  final performanceRuns = _parsePositiveInt(
    _readString(args, 'performance-runs', defaults.performanceRuns.toString()),
    'performance-runs',
  );
  final longLivedRounds = _parsePositiveInt(
    _readString(args, 'long-lived-rounds', defaults.longLivedRounds.toString()),
    'long-lived-rounds',
  );
  if (rounds == null ||
      samples == null ||
      warmupRounds == null ||
      warmupSamples == null ||
      performanceRuns == null ||
      longLivedRounds == null) {
    return null;
  }

  return _BenchConfig(
    rounds: rounds,
    samples: samples,
    warmupRounds: warmupRounds,
    warmupSamples: warmupSamples,
    performanceRuns: performanceRuns,
    longLivedRounds: longLivedRounds,
    defaultProfile: defaults,
    runBehavior: !performanceOnly,
    runPerformance: !behaviorOnly,
    verbose: verbose,
  );
}

String _readString(Args args, String key, String fallback) {
  final value = args[key]?.safeAs<String>();
  if (value == null || value.isEmpty) {
    return fallback;
  }
  return value;
}

bool _readBool(Args args, String key) {
  return args[key]?.safeAs<bool>() ?? false;
}

int? _parsePositiveInt(String raw, String option) {
  final value = int.tryParse(raw);
  if (value == null || value <= 0) {
    stderr.writeln('[router-benchmark] invalid --$option: $raw');
    return null;
  }
  return value;
}

int? _parseNonNegativeInt(String raw, String option) {
  final value = int.tryParse(raw);
  if (value == null || value < 0) {
    stderr.writeln('[router-benchmark] invalid --$option: $raw');
    return null;
  }
  return value;
}

_BenchDefaultProfile _deriveDefaultProfile() {
  final cpuCount = Platform.numberOfProcessors <= 0
      ? 1
      : Platform.numberOfProcessors;

  final rounds = _clampInt(cpuCount * 12, min: 48, max: 240);
  final samples = _clampInt(((cpuCount / 2).round()) + 4, min: 6, max: 16);
  final warmupRounds = _clampInt(rounds ~/ 2, min: 16, max: 120);
  final warmupSamples = _clampInt((cpuCount / 8).ceil(), min: 1, max: 4);
  final performanceRuns = _clampInt((cpuCount / 4).ceil(), min: 3, max: 6);
  final longLivedRounds = _clampInt(rounds, min: 48, max: 160);

  final tier = switch (cpuCount) {
    >= 16 => 'ultra',
    >= 12 => 'high',
    >= 8 => 'balanced',
    >= 4 => 'entry',
    _ => 'compact',
  };

  return _BenchDefaultProfile(
    name: '$tier-auto',
    cpuCount: cpuCount,
    rounds: rounds,
    samples: samples,
    warmupRounds: warmupRounds,
    warmupSamples: warmupSamples,
    performanceRuns: performanceRuns,
    longLivedRounds: longLivedRounds,
  );
}

int _clampInt(int value, {required int min, required int max}) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

Future<_BehaviorRunResult> _runBehaviorSuite(_BenchConfig config) async {
  final byScript = <String, _BehaviorScriptResult>{};
  final result = await _runCommand(
    executable: 'flutter',
    arguments: <String>[
      'test',
      '--reporter=expanded',
      'test/behavior_benchmark_test.dart',
      '--dart-define=UNROUTER_BENCH_LONG_LIVED_ROUNDS=${config.longLivedRounds}',
    ],
    workingDirectory: config.benchDirectory,
    verbose: config.verbose,
    onLine: (line) {
      final match = _behaviorPattern.firstMatch(_stripAnsi(line).trim());
      if (match == null) {
        return;
      }
      byScript[match.group(1)!] = _BehaviorScriptResult(
        script: match.group(1)!,
        parity: match.group(2) == 'true',
        expected: match.group(3) == 'true',
        seen: true,
      );
    },
  );

  final scripts = _behaviorScriptOrder
      .map(
        (script) =>
            byScript[script] ??
            _BehaviorScriptResult(
              script: script,
              parity: false,
              expected: false,
              seen: false,
            ),
      )
      .toList(growable: false);

  return _BehaviorRunResult(
    exitCode: result.exitCode,
    scripts: scripts,
    lines: result.lines,
  );
}

Future<_PerformanceRunResult> _runPerformanceSuite(_BenchConfig config) async {
  final runs = <_PerformanceSuiteRun>[];
  final allLines = <String>[];
  var firstNonZeroExitCode = 0;

  for (var runIndex = 1; runIndex <= config.performanceRuns; runIndex++) {
    if (config.performanceRuns > 1) {
      stdout.writeln(
        '[router-benchmark] performance run $runIndex/${config.performanceRuns}',
      );
    }

    final byRouter = <String, _PerformanceRouterResult>{};
    final result = await _runCommand(
      executable: 'flutter',
      arguments: <String>[
        'test',
        '--reporter=expanded',
        'test/performance_benchmark_test.dart',
        '--dart-define=UNROUTER_BENCH_ROUNDS=${config.rounds}',
        '--dart-define=UNROUTER_BENCH_SAMPLES=${config.samples}',
        '--dart-define=UNROUTER_BENCH_WARMUP_ROUNDS=${config.warmupRounds}',
        '--dart-define=UNROUTER_BENCH_WARMUP_SAMPLES=${config.warmupSamples}',
      ],
      workingDirectory: config.benchDirectory,
      verbose: config.verbose,
      onLine: (line) {
        final match = _performancePattern.firstMatch(_stripAnsi(line).trim());
        if (match == null) {
          return;
        }
        byRouter[match.group(1)!] = _PerformanceRouterResult(
          router: match.group(1)!,
          samples: int.parse(match.group(2)!),
          rounds: int.parse(match.group(3)!),
          meanUs: double.parse(match.group(4)!),
          p50Us: double.parse(match.group(5)!),
          p95Us: double.parse(match.group(6)!),
          checksumParity: match.group(7) == 'true',
          checksum: int.parse(match.group(8)!),
          capturedRuns: 1,
          totalRuns: 1,
          meanCvPercent: 0,
        );
      },
    );

    if (result.exitCode != 0 && firstNonZeroExitCode == 0) {
      firstNonZeroExitCode = result.exitCode;
    }
    allLines.addAll(result.lines.map((line) => '[run $runIndex] $line'));

    final routers = byRouter.values.toList(growable: false)
      ..sort((a, b) => a.router.compareTo(b.router));
    runs.add(_PerformanceSuiteRun(routers: routers));
  }

  final aggregatedRouters = _aggregatePerformanceRouters(runs);
  return _PerformanceRunResult(
    exitCode: firstNonZeroExitCode,
    routers: aggregatedRouters,
    lines: allLines,
    runCount: config.performanceRuns,
    warmupRounds: config.warmupRounds,
    warmupSamples: config.warmupSamples,
  );
}

List<_PerformanceRouterResult> _aggregatePerformanceRouters(
  List<_PerformanceSuiteRun> runs,
) {
  if (runs.isEmpty) {
    return const <_PerformanceRouterResult>[];
  }

  final totalRuns = runs.length;
  final expectedRouters = runs.first.routers
      .map((router) => router.router)
      .toSet();
  for (final run in runs.skip(1)) {
    expectedRouters.addAll(run.routers.map((router) => router.router));
  }

  final byRouter = <String, List<_PerformanceRouterResult>>{};
  for (final run in runs) {
    for (final router in run.routers) {
      byRouter.putIfAbsent(router.router, () => <_PerformanceRouterResult>[]);
      byRouter[router.router]!.add(router);
    }
  }

  final aggregated = <_PerformanceRouterResult>[];
  final sortedRouters = expectedRouters.toList()..sort();
  for (final routerName in sortedRouters) {
    final entries = byRouter[routerName] ?? const <_PerformanceRouterResult>[];
    if (entries.isEmpty) {
      aggregated.add(
        _PerformanceRouterResult(
          router: routerName,
          samples: 0,
          rounds: 0,
          meanUs: 0,
          p50Us: 0,
          p95Us: 0,
          checksumParity: false,
          checksum: -1,
          capturedRuns: 0,
          totalRuns: totalRuns,
          meanCvPercent: 0,
        ),
      );
      continue;
    }

    final means = entries.map((entry) => entry.meanUs).toList(growable: false);
    final p50s = entries.map((entry) => entry.p50Us).toList(growable: false);
    final p95s = entries.map((entry) => entry.p95Us).toList(growable: false);
    final checksums = entries.map((entry) => entry.checksum).toSet();
    final allChecksumParity = entries.every((entry) => entry.checksumParity);
    final checksumAligned = checksums.length == 1;

    aggregated.add(
      _PerformanceRouterResult(
        router: routerName,
        samples: entries.first.samples,
        rounds: entries.first.rounds,
        meanUs: _median(means),
        p50Us: _median(p50s),
        p95Us: _median(p95s),
        checksumParity: allChecksumParity && checksumAligned,
        checksum: checksumAligned ? entries.first.checksum : -1,
        capturedRuns: entries.length,
        totalRuns: totalRuns,
        meanCvPercent: _coefficientOfVariationPercent(means),
      ),
    );
  }
  return aggregated;
}

double _median(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final sorted = List<double>.from(values)..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middle];
  }
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

double _coefficientOfVariationPercent(List<double> values) {
  if (values.length < 2) {
    return 0;
  }
  final mean =
      values.fold<double>(0, (sum, value) => sum + value) / values.length;
  if (mean == 0) {
    return 0;
  }
  final variance =
      values.fold<double>(
        0,
        (sum, value) => sum + (value - mean) * (value - mean),
      ) /
      (values.length - 1);
  final standardDeviation = math.sqrt(variance);
  return (standardDeviation / mean) * 100;
}

Future<_CommandResult> _runCommand({
  required String executable,
  required List<String> arguments,
  required String workingDirectory,
  required bool verbose,
  required void Function(String line) onLine,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.normal,
  );

  final lines = <String>[];
  final stdoutFuture = _collectOutput(
    stream: process.stdout,
    sink: stdout,
    lines: lines,
    verbose: verbose,
    onLine: onLine,
  );
  final stderrFuture = _collectOutput(
    stream: process.stderr,
    sink: stderr,
    lines: lines,
    verbose: verbose,
    onLine: onLine,
  );

  final exitCode = await process.exitCode;
  await Future.wait(<Future<void>>[stdoutFuture, stderrFuture]);

  return _CommandResult(exitCode: exitCode, lines: lines);
}

Future<void> _collectOutput({
  required Stream<List<int>> stream,
  required IOSink sink,
  required List<String> lines,
  required bool verbose,
  required void Function(String line) onLine,
}) async {
  var pending = '';
  await for (final chunk in stream.transform(utf8.decoder)) {
    final normalized = chunk.replaceAll('\r', '\n');
    pending += normalized;

    final segments = pending.split('\n');
    pending = segments.removeLast();
    for (final segment in segments) {
      _consumeLine(
        line: segment,
        sink: sink,
        lines: lines,
        verbose: verbose,
        onLine: onLine,
      );
    }
  }
  _consumeLine(
    line: pending,
    sink: sink,
    lines: lines,
    verbose: verbose,
    onLine: onLine,
  );
}

void _consumeLine({
  required String line,
  required IOSink sink,
  required List<String> lines,
  required bool verbose,
  required void Function(String line) onLine,
}) {
  final trimmed = line.trimRight();
  if (trimmed.isEmpty) {
    return;
  }

  lines.add(trimmed);
  onLine(trimmed);
  if (verbose) {
    sink.writeln(trimmed);
  }
}

void _printFailureTail(String section, List<String> lines) {
  if (lines.isEmpty) {
    return;
  }
  stdout.writeln();
  stdout.writeln(
    styleText('$section logs (last 60 lines)', const <TextStyle>[
      TextStyle.bold,
      TextStyle.yellow,
    ]),
  );
  final start = math.max(0, lines.length - 60);
  for (final line in lines.skip(start)) {
    stdout.writeln(line);
  }
}

String _renderSummary({
  required _BenchConfig config,
  required _BehaviorRunResult behavior,
  required _PerformanceRunResult performance,
  required Duration elapsed,
}) {
  final buffer = StringBuffer();
  buffer.writeln(
    styleText('Unrouter Bench Summary', const <TextStyle>[
      TextStyle.bold,
      TextStyle.cyan,
    ]),
  );
  buffer.writeln('Bench: ${config.benchDirectory}');
  buffer.writeln(
    'Config: rounds=${config.rounds}, samples=${config.samples}, '
    'warmupRounds=${config.warmupRounds}, warmupSamples=${config.warmupSamples}, '
    'performanceRuns=${config.performanceRuns}, longLivedRounds=${config.longLivedRounds}',
  );
  buffer.writeln(
    'Profile: ${config.defaultProfile.name} (cpu=${config.defaultProfile.cpuCount})',
  );
  buffer.writeln('Elapsed: ${_formatDurationFriendly(elapsed)}');

  if (config.runBehavior) {
    buffer.writeln();
    buffer.writeln(
      styleText('Behavior', const <TextStyle>[
        TextStyle.bold,
        TextStyle.yellow,
      ]),
    );
    buffer.writeln('Suite exit code: ${behavior.exitCode}');
    buffer.writeln(
      _renderTable(
        headers: const <String>['Script', 'Parity', 'Expected', 'Status'],
        rows: behavior.scripts
            .map(
              (script) => <String>[
                _behaviorTitle(script.script),
                script.parity ? 'OK' : 'FAIL',
                script.expected ? 'OK' : 'FAIL',
                script.statusLabel,
              ],
            )
            .toList(growable: false),
      ),
    );
  }

  if (config.runPerformance) {
    buffer.writeln();
    buffer.writeln(
      styleText('Performance', const <TextStyle>[
        TextStyle.bold,
        TextStyle.yellow,
      ]),
    );
    buffer.writeln('Suite exit code: ${performance.exitCode}');
    buffer.writeln(
      'Aggregation: median across ${performance.runCount} run(s), '
      'warmup=${performance.warmupSamples}x${performance.warmupRounds}',
    );
    if (performance.routers.isEmpty) {
      buffer.writeln('No performance markers captured.');
    } else {
      buffer.writeln(_renderPerformanceMatrix(performance));
      buffer.writeln(
        'Cross-router checksum alignment: '
        '${performance.checksumAligned ? 'OK' : 'FAIL'}',
      );
    }
  }

  final overallPassed = behavior.passed && performance.passed;
  final overallStyle = overallPassed
      ? const <TextStyle>[TextStyle.bold, TextStyle.green]
      : const <TextStyle>[TextStyle.bold, TextStyle.red];

  buffer.writeln();
  buffer.writeln(
    '${styleText('Overall', const <TextStyle>[TextStyle.bold])}: '
    '${styleText(overallPassed ? 'PASS' : 'FAIL', overallStyle)}',
  );
  return buffer.toString().trimRight();
}

String _renderTable({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final widths = List<int>.generate(
    headers.length,
    (index) => _visibleLength(headers[index]),
  );
  for (final row in rows) {
    for (var i = 0; i < headers.length && i < row.length; i++) {
      final visible = _visibleLength(row[i]);
      if (visible > widths[i]) {
        widths[i] = visible;
      }
    }
  }

  final buffer = StringBuffer();
  buffer.writeln(_tableRow(headers, widths));
  buffer.writeln(_tableRule(widths));
  for (final row in rows) {
    buffer.writeln(_tableRow(row, widths));
  }
  return buffer.toString().trimRight();
}

String _tableRow(List<String> values, List<int> widths) {
  final cells = <String>[];
  for (var i = 0; i < widths.length; i++) {
    final value = i < values.length ? values[i] : '';
    cells.add(_padVisible(value, widths[i]));
  }
  return '| ${cells.join(' | ')} |';
}

String _tableRule(List<int> widths) {
  return '|-${widths.map((width) => ''.padRight(width, '-')).join('-|-')}-|';
}

String _renderPerformanceMatrix(_PerformanceRunResult performance) {
  final routers = performance.routers;
  final bestMean = performance.bestMeanUs;
  final bestMeanRouter = _bestRouterBy(routers, (router) => router.meanUs);
  final bestP50Router = _bestRouterBy(routers, (router) => router.p50Us);
  final bestP95Router = _bestRouterBy(routers, (router) => router.p95Us);

  final headers = <String>[
    'Metric',
    ...routers.map(
      (router) => router.router == bestMeanRouter?.router
          ? _style(router.router, const <TextStyle>[
              TextStyle.bold,
              TextStyle.green,
            ])
          : router.router,
    ),
  ];

  final rows = <List<String>>[
    <String>[
      'Runs',
      ...routers.map((router) {
        final text = '${router.capturedRuns}/${router.totalRuns}';
        if (router.hasCompleteRuns) {
          return _style(text, const <TextStyle>[TextStyle.green]);
        }
        return _style(text, const <TextStyle>[TextStyle.bold, TextStyle.red]);
      }),
    ],
    <String>[
      'Samples x rounds',
      ...routers.map((router) => '${router.samples}x${router.rounds}'),
    ],
    <String>[
      'Mean / round',
      ...routers.map((router) {
        final text = _formatMicrosFriendly(router.meanUs);
        return _styleMeanLikeMetric(
          text: text,
          value: router.meanUs,
          best: bestMean,
          isBest: router.router == bestMeanRouter?.router,
        );
      }),
    ],
    <String>[
      'P50 / round',
      ...routers.map((router) {
        final bestP50 = bestP50Router?.p50Us;
        final text = _formatMicrosFriendly(router.p50Us);
        return _styleMeanLikeMetric(
          text: text,
          value: router.p50Us,
          best: bestP50,
          isBest: router.router == bestP50Router?.router,
        );
      }),
    ],
    <String>[
      'P95 / round',
      ...routers.map((router) {
        final bestP95 = bestP95Router?.p95Us;
        final text = _formatMicrosFriendly(router.p95Us);
        return _styleMeanLikeMetric(
          text: text,
          value: router.p95Us,
          best: bestP95,
          isBest: router.router == bestP95Router?.router,
        );
      }),
    ],
    <String>[
      'Delta vs best',
      ...routers.map((router) {
        final text = _deltaPercentText(
          router.meanUs,
          bestMean,
          fallback: router.hasCompleteRuns ? '+0.0%' : '-',
        );
        if (!router.hasCompleteRuns) {
          return _style(text, const <TextStyle>[TextStyle.bold, TextStyle.red]);
        }
        final delta = _deltaPercent(router.meanUs, bestMean);
        if (delta == null || delta <= 0.0001) {
          return _style(text, const <TextStyle>[
            TextStyle.bold,
            TextStyle.green,
          ]);
        }
        if (delta >= 20) {
          return _style(text, const <TextStyle>[TextStyle.bold, TextStyle.red]);
        }
        if (delta >= 10) {
          return _style(text, const <TextStyle>[TextStyle.yellow]);
        }
        return text;
      }),
    ],
    <String>[
      'Mean CV',
      ...routers.map((router) {
        final text = '${router.meanCvPercent.toStringAsFixed(1)}%';
        if (router.meanCvPercent >= 15) {
          return _style(text, const <TextStyle>[TextStyle.bold, TextStyle.red]);
        }
        if (router.meanCvPercent >= 8) {
          return _style(text, const <TextStyle>[TextStyle.yellow]);
        }
        return _style(text, const <TextStyle>[TextStyle.green]);
      }),
    ],
    <String>[
      'Checksum',
      ...routers.map(
        (router) => router.checksumParity
            ? _style(router.checksum.toString(), const <TextStyle>[
                TextStyle.green,
              ])
            : _style('FAIL', const <TextStyle>[TextStyle.bold, TextStyle.red]),
      ),
    ],
  ];

  return '${_renderTable(headers: headers, rows: rows)}\n'
      '${_style('Legend:', const <TextStyle>[TextStyle.bold])} '
      '${_style('best', const <TextStyle>[TextStyle.bold, TextStyle.green])} '
      '| ${_style('warning', const <TextStyle>[TextStyle.yellow])} '
      '| ${_style('anomaly', const <TextStyle>[TextStyle.bold, TextStyle.red])}';
}

String _styleMeanLikeMetric({
  required String text,
  required double value,
  required double? best,
  required bool isBest,
}) {
  if (isBest) {
    return _style(text, const <TextStyle>[TextStyle.bold, TextStyle.green]);
  }
  final delta = _deltaPercent(value, best);
  if (delta == null) {
    return text;
  }
  if (delta >= 20) {
    return _style(text, const <TextStyle>[TextStyle.bold, TextStyle.red]);
  }
  if (delta >= 10) {
    return _style(text, const <TextStyle>[TextStyle.yellow]);
  }
  return text;
}

_PerformanceRouterResult? _bestRouterBy(
  List<_PerformanceRouterResult> routers,
  double Function(_PerformanceRouterResult router) selector,
) {
  _PerformanceRouterResult? best;
  for (final router in routers) {
    if (!router.hasCompleteRuns) {
      continue;
    }
    if (best == null || selector(router) < selector(best)) {
      best = router;
    }
  }
  return best;
}

String _style(String text, List<TextStyle> styles) {
  return styleText(text, styles);
}

int _visibleLength(String text) {
  return _stripAnsi(text).length;
}

String _padVisible(String value, int width) {
  final visible = _visibleLength(value);
  if (visible >= width) {
    return value;
  }
  return '$value${''.padRight(width - visible)}';
}

String _formatMicrosFriendly(double micros) {
  if (micros >= 1000000) {
    return '${(micros / 1000000).toStringAsFixed(2)}s';
  }
  if (micros >= 1000) {
    return '${(micros / 1000).toStringAsFixed(2)}ms';
  }
  return '${micros.toStringAsFixed(1)}us';
}

String _formatDurationFriendly(Duration duration) {
  final micros = duration.inMicroseconds.toDouble();
  if (micros >= 1000000) {
    return '${(micros / 1000000).toStringAsFixed(2)}s';
  }
  if (micros >= 1000) {
    return '${(micros / 1000).toStringAsFixed(1)}ms';
  }
  return '${micros.toStringAsFixed(0)}us';
}

String _deltaPercentText(
  double value,
  double? baseline, {
  String fallback = '-',
}) {
  final delta = _deltaPercent(value, baseline);
  if (delta == null) {
    return fallback;
  }
  final text = '${delta.toStringAsFixed(1)}%';
  if (delta > 0) {
    return '+$text';
  }
  return text;
}

double? _deltaPercent(double value, double? baseline) {
  if (baseline == null || baseline <= 0) {
    return null;
  }
  return ((value - baseline) / baseline) * 100;
}

String _behaviorTitle(String script) {
  switch (script) {
    case 'sharedNavigation':
      return 'Shared navigation';
    case 'redirect':
      return 'Redirect';
    case 'guardRedirect':
      return 'Guard redirect';
    case 'nestedNavigation':
      return 'Nested navigation';
    case 'browserLikeBackForward':
      return 'Back/forward-like';
    case 'longLivedRestoration':
      return 'Long-lived restoration';
    default:
      return script;
  }
}

String _stripAnsi(String text) {
  return text.replaceAll(_ansiEscapePattern, '');
}

String _usage(_BenchDefaultProfile defaults) {
  return '''
Usage: dart run main.dart [options]

Auto defaults on this machine:
  profile=${defaults.name}, cpu=${defaults.cpuCount}
  rounds=${defaults.rounds}, samples=${defaults.samples}, warmup-rounds=${defaults.warmupRounds},
  warmup-samples=${defaults.warmupSamples}, performance-runs=${defaults.performanceRuns},
  long-lived-rounds=${defaults.longLivedRounds}

Options:
  -r, --rounds=<n>             Performance rounds per sample (default: auto)
  -s, --samples=<n>            Performance sample count (default: auto)
  -w, --warmup-rounds=<n>      Warmup rounds per warmup sample (default: auto)
  -x, --warmup-samples=<n>     Warmup sample count (default: auto)
  -n, --performance-runs=<n>   Repeat performance suite N times and aggregate median (default: auto)
  -l, --long-lived-rounds=<n>  Long-lived behavior rounds (default: auto)
  -b, --behavior-only          Run only behavior suite
  -p, --performance-only       Run only performance suite
  -v, --verbose                Stream raw flutter test output
  -h, --help                   Print usage
''';
}

class _BenchConfig {
  const _BenchConfig({
    required this.rounds,
    required this.samples,
    required this.warmupRounds,
    required this.warmupSamples,
    required this.performanceRuns,
    required this.longLivedRounds,
    required this.defaultProfile,
    required this.runBehavior,
    required this.runPerformance,
    required this.verbose,
  });

  final int rounds;
  final int samples;
  final int warmupRounds;
  final int warmupSamples;
  final int performanceRuns;
  final int longLivedRounds;
  final _BenchDefaultProfile defaultProfile;
  final bool runBehavior;
  final bool runPerformance;
  final bool verbose;

  String get benchDirectory {
    final scriptFile = File.fromUri(Platform.script);
    return scriptFile.parent.path;
  }
}

class _BenchDefaultProfile {
  const _BenchDefaultProfile({
    required this.name,
    required this.cpuCount,
    required this.rounds,
    required this.samples,
    required this.warmupRounds,
    required this.warmupSamples,
    required this.performanceRuns,
    required this.longLivedRounds,
  });

  final String name;
  final int cpuCount;
  final int rounds;
  final int samples;
  final int warmupRounds;
  final int warmupSamples;
  final int performanceRuns;
  final int longLivedRounds;
}

class _CommandResult {
  const _CommandResult({required this.exitCode, required this.lines});

  final int exitCode;
  final List<String> lines;
}

class _BehaviorRunResult {
  const _BehaviorRunResult({
    required this.exitCode,
    required this.scripts,
    required this.lines,
  });

  const _BehaviorRunResult.skipped()
    : exitCode = 0,
      scripts = const <_BehaviorScriptResult>[],
      lines = const <String>[];

  final int exitCode;
  final List<_BehaviorScriptResult> scripts;
  final List<String> lines;

  bool get passed {
    if (scripts.isEmpty) {
      return true;
    }
    return exitCode == 0 && scripts.every((script) => script.passed);
  }
}

class _BehaviorScriptResult {
  const _BehaviorScriptResult({
    required this.script,
    required this.parity,
    required this.expected,
    required this.seen,
  });

  final String script;
  final bool parity;
  final bool expected;
  final bool seen;

  bool get passed => seen && parity && expected;

  String get statusLabel {
    if (!seen) {
      return 'MISSING';
    }
    return passed ? 'PASS' : 'FAIL';
  }
}

class _PerformanceRunResult {
  const _PerformanceRunResult({
    required this.exitCode,
    required this.routers,
    required this.lines,
    required this.runCount,
    required this.warmupRounds,
    required this.warmupSamples,
  });

  const _PerformanceRunResult.skipped()
    : exitCode = 0,
      routers = const <_PerformanceRouterResult>[],
      lines = const <String>[],
      runCount = 0,
      warmupRounds = 0,
      warmupSamples = 0;

  final int exitCode;
  final List<_PerformanceRouterResult> routers;
  final List<String> lines;
  final int runCount;
  final int warmupRounds;
  final int warmupSamples;

  bool get checksumAligned {
    if (routers.length < 2) {
      return true;
    }
    final checksums = routers.map((router) => router.checksum).toSet();
    return checksums.length == 1;
  }

  bool get passed {
    if (routers.isEmpty) {
      return exitCode == 0;
    }
    final allParity = routers.every(
      (router) => router.checksumParity && router.hasCompleteRuns,
    );
    return exitCode == 0 && allParity && checksumAligned;
  }

  double? get bestMeanUs {
    final completeRouters = routers
        .where((router) => router.hasCompleteRuns && router.meanUs > 0)
        .toList(growable: false);
    if (completeRouters.isEmpty) {
      return null;
    }
    return completeRouters
        .map((router) => router.meanUs)
        .reduce((left, right) => left < right ? left : right);
  }
}

class _PerformanceRouterResult {
  const _PerformanceRouterResult({
    required this.router,
    required this.samples,
    required this.rounds,
    required this.meanUs,
    required this.p50Us,
    required this.p95Us,
    required this.checksumParity,
    required this.checksum,
    required this.capturedRuns,
    required this.totalRuns,
    required this.meanCvPercent,
  });

  final String router;
  final int samples;
  final int rounds;
  final double meanUs;
  final double p50Us;
  final double p95Us;
  final bool checksumParity;
  final int checksum;
  final int capturedRuns;
  final int totalRuns;
  final double meanCvPercent;

  bool get hasCompleteRuns => capturedRuns == totalRuns;
}

class _PerformanceSuiteRun {
  const _PerformanceSuiteRun({required this.routers});

  final List<_PerformanceRouterResult> routers;
}
