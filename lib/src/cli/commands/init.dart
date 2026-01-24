import 'dart:io';

import 'package:coal/args.dart';
import 'package:path/path.dart' as p;

const _configFileName = 'unrouter.config.dart';
const _defaultPagesDir = 'lib/pages';
const _defaultOutput = 'lib/routes.g.dart';
const _pubspecFileName = 'pubspec.yaml';

Future<int> runInit(Args parsed) async {
  final pagesDir = parsed.at('pages')?.safeAs<String>() ?? _defaultPagesDir;
  final output = parsed.at('output')?.safeAs<String>() ?? _defaultOutput;
  final force = parsed.at('force')?.safeAs<bool>() == true;

  final cwd = Directory.current.path;
  final pagesAbsolute = _resolvePath(cwd, pagesDir);
  final outputAbsolute = _resolvePath(cwd, output);

  final outputRoot = _findPubspecRoot(p.dirname(outputAbsolute));
  final pagesRoot = outputRoot ?? _findPubspecRoot(p.dirname(pagesAbsolute));
  if (pagesRoot == null) {
    stderr.writeln(
      'Unable to find pubspec.yaml above "$output" or "$pagesDir".',
    );
    stderr.writeln('Run this command from within a Dart/Flutter project.');
    return 1;
  }

  final targetPath = p.join(pagesRoot, _configFileName);

  final targetFile = File(targetPath);
  if (targetFile.existsSync() && !force) {
    stdout.writeln(
      'Config already exists at "$targetPath". Use --force to overwrite.',
    );
    return 0;
  }

  final configPages = _formatConfigPath(pagesAbsolute, pagesRoot);
  final configOutput = _formatConfigPath(outputAbsolute, pagesRoot);

  await targetFile.writeAsString(
    _configTemplate(pagesDir: configPages, output: configOutput),
  );
  stdout.writeln('Wrote "$targetPath".');
  return 0;
}

String? _findPubspecRoot(String startPath) {
  var current = Directory(startPath).absolute;
  while (true) {
    final candidate = File(p.join(current.path, _pubspecFileName));
    if (candidate.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}

String _resolvePath(String baseDir, String value) {
  if (p.isAbsolute(value)) return value;
  return p.normalize(p.join(baseDir, value));
}

String _formatConfigPath(String absolute, String rootDir) {
  if (p.isWithin(rootDir, absolute) || p.equals(rootDir, absolute)) {
    return p.relative(absolute, from: rootDir);
  }
  return absolute;
}

String _configTemplate({required String pagesDir, required String output}) {
  return '''
const pagesDir = '$pagesDir';
const output = '$output';
''';
}
