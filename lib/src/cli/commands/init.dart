import 'dart:io';

import 'package:coal/args.dart';
import 'package:path/path.dart' as p;

import '../utils/constants.dart';
import '../utils/root_finder.dart';

Future<int> runInit(Args parsed) async {
  final pagesDir = parsed.at('pages')?.safeAs<String>() ?? defaultPagesDir;
  final output = parsed.at('output')?.safeAs<String>() ?? defaultOutput;
  final force = parsed.at('force')?.safeAs<bool>() == true;

  final cwd = Directory.current.path;
  final pagesAbsolute = _resolvePath(cwd, pagesDir);
  final outputAbsolute = _resolvePath(cwd, output);

  final outputRoot = findPubspecRoot(p.dirname(outputAbsolute));
  final pagesRoot = outputRoot ?? findPubspecRoot(p.dirname(pagesAbsolute));
  if (pagesRoot == null) {
    stderr.writeln(
      'Unable to find pubspec.yaml above "$output" or "$pagesDir".',
    );
    stderr.writeln('Run this command from within a Dart/Flutter project.');
    return 1;
  }

  final targetPath = p.join(pagesRoot, configFileName);

  final targetFile = File(targetPath);
  if (targetFile.existsSync() && !force) {
    stdout.writeln(
      'Config already exists at "$targetPath". Use --force to overwrite.',
    );
    return 0;
  }

  final pagesDirectory = Directory(pagesAbsolute);
  if (!pagesDirectory.existsSync()) {
    await pagesDirectory.create(recursive: true);
    stdout.writeln(
      'Created pages directory at "${_relativeToCwd(pagesAbsolute)}".',
    );
  }

  final outputFile = File(outputAbsolute);
  final outputDir = outputFile.parent;
  if (!outputDir.existsSync()) {
    await outputDir.create(recursive: true);
  }
  if (!outputFile.existsSync()) {
    await outputFile.writeAsString(outputTemplate);
    stdout.writeln('Created output file at "${_relativeToCwd(outputAbsolute)}".');
  }

  final configPages = _formatConfigPath(pagesAbsolute, pagesRoot);
  final configOutput = _formatConfigPath(outputAbsolute, pagesRoot);

  await targetFile.writeAsString(
    buildConfigContents(pagesDir: configPages, output: configOutput),
  );
  stdout.writeln('Wrote "${_relativeToCwd(targetPath)}".');
  return 0;
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

String _relativeToCwd(String absolutePath) {
  final cwd = Directory.current.absolute.path;
  if (p.isWithin(cwd, absolutePath) || p.equals(cwd, absolutePath)) {
    return p.relative(absolutePath, from: cwd);
  }
  return absolutePath;
}

String buildConfigContents({required String pagesDir, required String output}) {
  return '''
const pagesDir = '$pagesDir';
const output = '$output';
''';
}

const String outputTemplate = '''
// GENERATED CODE - DO NOT MODIFY BY HAND.
import 'package:unrouter/unrouter.dart';

const routes = <Inlet>[];
''';
