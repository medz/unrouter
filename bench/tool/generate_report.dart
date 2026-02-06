import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _parseOptions(args);
  final output = options['output'] ?? _defaultOutputPath();
  final rounds = options['rounds'] ?? '24';
  final longLivedRounds = options['long-lived-rounds'] ?? '40';

  final flutterInfo = await _readFlutterVersionInfo();
  final gitInfo = await _readGitInfo();

  final testArgs = <String>[
    'test',
    '--tags',
    'report',
    '--dart-define=UNROUTER_BENCH_REPORT_PATH=$output',
    '--dart-define=UNROUTER_BENCH_ROUNDS=$rounds',
    '--dart-define=UNROUTER_BENCH_LONG_LIVED_ROUNDS=$longLivedRounds',
    '--dart-define=UNROUTER_BENCH_FLUTTER_VERSION=${flutterInfo.version}',
    '--dart-define=UNROUTER_BENCH_FLUTTER_CHANNEL=${flutterInfo.channel}',
    '--dart-define=UNROUTER_BENCH_FLUTTER_REVISION=${flutterInfo.revision}',
    '--dart-define=UNROUTER_BENCH_GIT_SHA=${gitInfo.sha}',
    '--dart-define=UNROUTER_BENCH_GIT_BRANCH=${gitInfo.branch}',
  ];

  stdout.writeln(
    '[router-benchmark] generating report: output=$output, rounds=$rounds, longLivedRounds=$longLivedRounds',
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
    if (arg.startsWith('--long-lived-rounds=')) {
      options['long-lived-rounds'] = arg.substring(
        '--long-lived-rounds='.length,
      );
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
