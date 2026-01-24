import 'dart:async';
import 'dart:io';

import 'package:coal/args.dart';
import 'package:path/path.dart' as p;

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
  final state = await _resolveState(parsed);
  if (state == null) {
    return 1;
  }

  final pagesDirectory = Directory(state.paths.resolvedPagesDir);
  if (!pagesDirectory.existsSync()) {
    stderr.writeln(
      'Pages directory not found: ${state.paths.resolvedPagesDir}',
    );
    return 1;
  }

  await runGenerate(parsed);

  stdout.writeln(
    'Watching "${_relativeToCwd(pagesDirectory.path)}" for changes... (Ctrl+C to stop)\n',
  );

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
  final pendingPaths = <String>{};

  void schedule([String? changedPath]) {
    if (changedPath != null) {
      pendingPaths.add(_relativeToCwd(p.normalize(p.absolute(changedPath))));
    }
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 200), () async {
      if (generating) {
        pending = true;
        return;
      }
      generating = true;
      try {
        if (pendingPaths.isNotEmpty) {
          final paths = pendingPaths.toList()..sort();
          pendingPaths.clear();
          stdout.writeln('Detected changes:');
          for (final path in paths) {
            stdout.writeln('  - $path');
          }
          stdout.writeln('');
        }
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
        await runGenerate(parsed);
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
      'Unable to find $configFileName or $pubspecFileName above the current directory.',
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
