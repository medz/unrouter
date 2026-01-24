import 'dart:async';
import 'dart:io';

import 'package:coal/args.dart';
import 'package:coal/utils.dart' show stripVTControlCharacters;
import 'package:path/path.dart' as p;

import '../utils/cli_output.dart';
import '../utils/constants.dart';
import '../utils/root_finder.dart';
import '../utils/routing_config.dart';
import '../utils/routing_paths.dart';
import 'generate.dart';

class _WatchState {
  _WatchState({required this.configPath, required this.paths});

  final String? configPath;
  final RoutingPaths paths;
}

Future<int> runWatch(Args parsed) async {
  if (parsed.at('json')?.safeAs<bool>() == true) {
    stderr.writeln(
      '${errorLabel('Error')}: --json is not supported for watch.',
    );
    return 2;
  }
  final quietOutput = parsed.at('quiet')?.safeAs<bool>() == true;
  final state = await _resolveState(parsed);
  if (state == null) {
    return 1;
  }

  final pagesDirectory = Directory(state.paths.resolvedPagesDir);
  if (!pagesDirectory.existsSync()) {
    stderr.writeln(
      '${errorLabel('Error')}: Pages directory not found: ${pathText(state.paths.resolvedPagesDir, stderr: true)}',
    );
    return 1;
  }

  if (!quietOutput) {
    stdout.writeln(
      '${infoLabel('Watch')}: ${pathText(_relativeToCwd(pagesDirectory.path))} ${dimText('(Ctrl+C to stop)')}\n',
    );
  }

  final completer = Completer<int>();
  StreamSubscription<FileSystemEvent>? pagesSub;
  StreamSubscription<FileSystemEvent>? configSub;
  StreamSubscription<ProcessSignal>? sigintSub;
  StreamSubscription<ProcessSignal>? sigtermSub;
  Timer? debounce;
  var current = state;
  var generating = false;
  var pending = false;
  var stopping = false;
  final pendingPaths = <String, int>{};
  final totalCounts = <String, int>{};
  var renderedLines = 0;

  final initialErrors = <String>[];
  final initialStopwatch = Stopwatch()..start();
  final initialExitCode = await runGenerate(
    parsed,
    quiet: true,
    errorLines: initialErrors,
  );
  initialStopwatch.stop();
  if (!quietOutput) {
    renderedLines = _renderChanges(
      pendingPaths,
      renderedLines: renderedLines,
      outputPath: state.paths.resolvedOutput,
      succeeded: initialExitCode == 0,
      totalCounts: totalCounts,
      duration: initialStopwatch.elapsed,
      showWhenEmpty: true,
      errorLine: _lastErrorLine(initialErrors),
    );
  }

  void schedule([String? changedPath]) {
    if (changedPath != null) {
      final normalized = _relativeToCwd(p.normalize(p.absolute(changedPath)));
      pendingPaths[normalized] = (pendingPaths[normalized] ?? 0) + 1;
      totalCounts[normalized] = (totalCounts[normalized] ?? 0) + 1;
    }
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 200), () async {
      if (generating) {
        pending = true;
        return;
      }
      generating = true;
      try {
        final updated = await _resolveState(parsed);
        if (updated == null) {
          return;
        }

        if (updated.paths.resolvedPagesDir != current.paths.resolvedPagesDir) {
          await pagesSub?.cancel();
          pagesSub = _watchPages(updated, schedule);
        }

        if (_configWatchRoot(updated) != _configWatchRoot(current)) {
          await configSub?.cancel();
          configSub = _watchConfig(updated, schedule);
        }

        current = updated;
        final errors = <String>[];
        final stopwatch = Stopwatch()..start();
        final exitCode = await runGenerate(
          parsed,
          quiet: true,
          errorLines: errors,
        );
        stopwatch.stop();
        if (!quietOutput) {
          renderedLines = _renderChanges(
            pendingPaths,
            renderedLines: renderedLines,
            outputPath: current.paths.resolvedOutput,
            succeeded: exitCode == 0,
            totalCounts: totalCounts,
            duration: stopwatch.elapsed,
            errorLine: _lastErrorLine(errors),
          );
        }
        pendingPaths.clear();
      } finally {
        generating = false;
        if (pending) {
          pending = false;
          schedule();
        }
      }
    });
  }

  pagesSub = _watchPages(current, schedule);
  configSub = _watchConfig(current, schedule);

  Future<void> shutdown() async {
    if (stopping) {
      return;
    }
    stopping = true;
    await pagesSub?.cancel();
    await configSub?.cancel();
    await sigintSub?.cancel();
    await sigtermSub?.cancel();
    debounce?.cancel();
    if (!completer.isCompleted) {
      completer.complete(0);
    }
  }

  sigintSub = ProcessSignal.sigint.watch().listen((_) async {
    await shutdown();
  });
  sigtermSub = ProcessSignal.sigterm.watch().listen((_) async {
    await shutdown();
  });

  return completer.future;
}

StreamSubscription<FileSystemEvent> _watchPages(
  _WatchState state,
  void Function([String? changedPath]) schedule,
) {
  final outputPath = p.normalize(p.absolute(state.paths.resolvedOutput));
  return Directory(state.paths.resolvedPagesDir).watch(recursive: true).listen((
    event,
  ) {
    final eventPath = p.normalize(p.absolute(event.path));
    if (eventPath == outputPath) {
      return;
    }
    schedule(event.path);
  });
}

StreamSubscription<FileSystemEvent> _watchConfig(
  _WatchState state,
  void Function([String? changedPath]) schedule,
) {
  final watchDir = _configWatchRoot(state);
  return Directory(watchDir).watch().listen((event) {
    if (p.basename(event.path) == configFileName) {
      schedule(event.path);
    }
  });
}

String _configWatchRoot(_WatchState state) {
  if (state.configPath != null) {
    return p.dirname(state.configPath!);
  }
  return state.paths.rootDir;
}

Future<_WatchState?> _resolveState(Args parsed) async {
  final cwd = Directory.current;
  final configPath = findConfigPath(cwd);
  final config = await readRoutingConfig(
    configPath,
    onError: (message) => stderr.writeln(message),
  );

  final pagesArg = parsed.at('pages')?.safeAs<String>();
  final outputArg = parsed.at('output')?.safeAs<String>();

  final resolved = resolveRoutingPaths(
    cwd: cwd,
    configPath: configPath,
    pagesArg: pagesArg,
    outputArg: outputArg,
    configPages: config?.pagesDir,
    configOutput: config?.output,
  );

  if (resolved == null) {
    stderr.writeln(
      '${errorLabel('Error')}: Unable to find $configFileName or $pubspecFileName above the current directory.',
    );
    return null;
  }

  return _WatchState(configPath: configPath, paths: resolved);
}

String _relativeToCwd(String absolutePath) {
  final cwd = Directory.current.absolute.path;
  if (p.isWithin(cwd, absolutePath) || p.equals(cwd, absolutePath)) {
    return p.relative(absolutePath, from: cwd);
  }
  return absolutePath;
}

int _renderChanges(
  Map<String, int> changes, {
  required int renderedLines,
  required String outputPath,
  required bool succeeded,
  required Map<String, int> totalCounts,
  required Duration duration,
  String? errorLine,
  bool showWhenEmpty = false,
}) {
  if (changes.isEmpty && !showWhenEmpty) return 0;
  final now = DateTime.now();
  final status = succeeded ? successLabel('OK') : failureLabel('FAIL');
  final summary =
      '${infoLabel('Watch')} ${_formatTime(now)}  $status in ${_formatDuration(duration)}'
      '  • ${changes.length} files (${_sumCounts(changes)} events, total ${_sumCounts(totalCounts)})'
      ' → ${pathText(_relativeToCwd(outputPath))}';
  final lines = <String>[fitToTerminal(summary)];
  if (changes.isEmpty) {
    lines.add(fitToTerminal(dimText('Waiting for changes...')));
  } else {
    lines.add(fitToTerminal(heading('Changed files')));
    for (final entry in changes.entries) {
      final total = totalCounts[entry.key] ?? entry.value;
      final suffix = total > 1 ? ' ${dimText('(x$total)')}' : '';
      lines.add(fitToTerminal('  - ${entry.key}$suffix'));
    }
  }
  if (!succeeded && errorLine != null && errorLine.isNotEmpty) {
    lines.add(fitToTerminal('${failureLabel('Error')}: $errorLine'));
  }
  rewriteBlock(lines, previousLineCount: renderedLines);
  return lines.length;
}

String? _lastErrorLine(List<String> errors) {
  if (errors.isEmpty) return null;
  for (var i = errors.length - 1; i >= 0; i -= 1) {
    final line = stripVTControlCharacters(errors[i]).trim();
    if (line.isNotEmpty) return line;
  }
  return null;
}

int _sumCounts(Map<String, int> counts) {
  var total = 0;
  for (final value in counts.values) {
    total += value;
  }
  return total;
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

String _formatDuration(Duration duration) {
  if (duration.inMilliseconds < 1000) {
    return '${duration.inMilliseconds}ms';
  }
  final seconds = duration.inMilliseconds / 1000;
  return '${seconds.toStringAsFixed(1)}s';
}
