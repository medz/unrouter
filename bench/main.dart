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
  final parsed = Args.parse(
    rawArgs,
    defaults: <String, Object?>{
      'rounds': '24',
      'samples': '5',
      'long-lived-rounds': '40',
      'behavior-only': false,
      'performance-only': false,
      'verbose': false,
      'help': false,
    },
    aliases: <String, String>{
      'r': 'rounds',
      's': 'samples',
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
    string: const <String>['rounds', 'samples', 'long-lived-rounds'],
  );

  if (_readBool(parsed, 'help')) {
    stdout.writeln(_usage());
    return;
  }

  final config = _parseConfig(parsed);
  if (config == null) {
    stderr.writeln(_usage());
    exit(64);
  }

  stdout.writeln(
    '[router-benchmark] rounds=${config.rounds}, samples=${config.samples}, '
    'longLivedRounds=${config.longLivedRounds}, behavior=${config.runBehavior}, '
    'performance=${config.runPerformance}',
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

_BenchConfig? _parseConfig(Args args) {
  final behaviorOnly = _readBool(args, 'behavior-only');
  final performanceOnly = _readBool(args, 'performance-only');
  final verbose = _readBool(args, 'verbose');
  if (behaviorOnly && performanceOnly) {
    stderr.writeln(
      '[router-benchmark] --behavior-only and --performance-only cannot be used together',
    );
    return null;
  }

  final rounds = _parsePositiveInt(_readString(args, 'rounds', '24'), 'rounds');
  final samples = _parsePositiveInt(
    _readString(args, 'samples', '5'),
    'samples',
  );
  final longLivedRounds = _parsePositiveInt(
    _readString(args, 'long-lived-rounds', '40'),
    'long-lived-rounds',
  );
  if (rounds == null || samples == null || longLivedRounds == null) {
    return null;
  }

  return _BenchConfig(
    rounds: rounds,
    samples: samples,
    longLivedRounds: longLivedRounds,
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
  final byRouter = <String, _PerformanceRouterResult>{};
  final result = await _runCommand(
    executable: 'flutter',
    arguments: <String>[
      'test',
      '--reporter=expanded',
      'test/performance_benchmark_test.dart',
      '--dart-define=UNROUTER_BENCH_ROUNDS=${config.rounds}',
      '--dart-define=UNROUTER_BENCH_SAMPLES=${config.samples}',
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
      );
    },
  );

  final routers = byRouter.values.toList(growable: false)
    ..sort((a, b) => a.router.compareTo(b.router));
  return _PerformanceRunResult(
    exitCode: result.exitCode,
    routers: routers,
    lines: result.lines,
  );
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
    'longLivedRounds=${config.longLivedRounds}',
  );
  buffer.writeln('Elapsed: ${elapsed.inMilliseconds} ms');

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
    if (performance.routers.isEmpty) {
      buffer.writeln('No performance markers captured.');
    } else {
      buffer.writeln(
        _renderTable(
          headers: const <String>[
            'Router',
            'Samples',
            'Rounds',
            'Mean(us)',
            'P50(us)',
            'P95(us)',
            'ChecksumParity',
            'Checksum',
          ],
          rows: performance.routers
              .map(
                (router) => <String>[
                  router.router,
                  router.samples.toString(),
                  router.rounds.toString(),
                  router.meanUs.toStringAsFixed(1),
                  router.p50Us.toStringAsFixed(1),
                  router.p95Us.toStringAsFixed(1),
                  router.checksumParity ? 'OK' : 'FAIL',
                  router.checksum.toString(),
                ],
              )
              .toList(growable: false),
        ),
      );
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
    (index) => headers[index].length,
  );
  for (final row in rows) {
    for (var i = 0; i < headers.length && i < row.length; i++) {
      if (row[i].length > widths[i]) {
        widths[i] = row[i].length;
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
    cells.add(value.padRight(widths[i]));
  }
  return '| ${cells.join(' | ')} |';
}

String _tableRule(List<int> widths) {
  return '|-${widths.map((width) => ''.padRight(width, '-')).join('-|-')}-|';
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

String _usage() {
  return '''
Usage: dart run main.dart [options]

Options:
  -r, --rounds=<n>             Performance rounds per sample (default: 24)
  -s, --samples=<n>            Performance sample count (default: 5)
  -l, --long-lived-rounds=<n>  Long-lived behavior rounds (default: 40)
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
    required this.longLivedRounds,
    required this.runBehavior,
    required this.runPerformance,
    required this.verbose,
  });

  final int rounds;
  final int samples;
  final int longLivedRounds;
  final bool runBehavior;
  final bool runPerformance;
  final bool verbose;

  String get benchDirectory {
    final scriptFile = File.fromUri(Platform.script);
    return scriptFile.parent.path;
  }
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
  });

  const _PerformanceRunResult.skipped()
    : exitCode = 0,
      routers = const <_PerformanceRouterResult>[],
      lines = const <String>[];

  final int exitCode;
  final List<_PerformanceRouterResult> routers;
  final List<String> lines;

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
    final allParity = routers.every((router) => router.checksumParity);
    return exitCode == 0 && allParity && checksumAligned;
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
  });

  final String router;
  final int samples;
  final int rounds;
  final double meanUs;
  final double p50Us;
  final double p95Us;
  final bool checksumParity;
  final int checksum;
}
