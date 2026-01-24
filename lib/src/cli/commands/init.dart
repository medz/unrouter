import 'dart:io';

import 'package:coal/args.dart';
import 'package:path/path.dart' as p;

const _configFileName = 'unrouter.config.dart';
const _defaultPagesDir = 'lib/pages';
const _defaultOutput = 'lib/routes.g.dart';

Future<int> runInit(Args parsed) async {
  final pagesDir = parsed.at('pages')?.safeAs<String>() ?? _defaultPagesDir;
  final output = parsed.at('output')?.safeAs<String>() ?? _defaultOutput;
  final force = parsed.at('force')?.safeAs<bool>() == true;

  final existing = _findConfigPath(Directory.current);
  final targetPath = existing ?? p.join(Directory.current.path, _configFileName);

  final targetFile = File(targetPath);
  if (targetFile.existsSync() && !force) {
    stdout.writeln(
      'Config already exists at "$targetPath". Use --force to overwrite.',
    );
    return 0;
  }

  await targetFile.writeAsString(
    _configTemplate(pagesDir: pagesDir, output: output),
  );
  stdout.writeln('Wrote "$targetPath".');
  return 0;
}

String? _findConfigPath(Directory start) {
  var current = start.absolute;
  while (true) {
    final candidate = File(p.join(current.path, _configFileName));
    if (candidate.existsSync()) {
      return candidate.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}

String _configTemplate({required String pagesDir, required String output}) {
  return '''
const pagesDir = '$pagesDir';
const output = '$output';
''';
}
