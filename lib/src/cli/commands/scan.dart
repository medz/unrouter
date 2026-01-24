import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:coal/args.dart';
import 'package:path/path.dart' as p;

const _defaultPagesDir = 'lib/pages';
const _defaultOutput = 'lib/routes.dart';
const _configFileName = 'unrouter.config.dart';

class _FileRoutingConfig {
  const _FileRoutingConfig({this.pagesDir, this.output});

  final String? pagesDir;
  final String? output;
}

Future<int> runScan(Args parsed) async {
  final configPath = _findConfigPath(Directory.current);
  final rootDir =
      configPath == null
          ? Directory.current.absolute.path
          : File(configPath).absolute.parent.path;

  _FileRoutingConfig? config;
  if (configPath != null) {
    final result = parseString(
      content: await File(configPath).readAsString(),
      throwIfDiagnostics: false,
      path: configPath,
    );
    if (result.errors.isNotEmpty) {
      stderr.writeln('Failed to parse $configPath:');
      for (final error in result.errors) {
        stderr.writeln('  ${error.toString()}');
      }
    }
    config = _extractConfig(result.unit);
  }

  final pagesArg = parsed.at('pages')?.safeAs<String>();
  final outputArg = parsed.at('output')?.safeAs<String>();

  final pagesDir = pagesArg ?? config?.pagesDir ?? _defaultPagesDir;
  final output = outputArg ?? config?.output ?? _defaultOutput;
  final pagesSource = _sourceLabel(pagesArg, config?.pagesDir);
  final outputSource = _sourceLabel(outputArg, config?.output);

  stdout.writeln('Scan result');
  stdout.writeln('  root: $rootDir');
  stdout.writeln(
    '  config: ${configPath ?? '<none>'}',
  );
  stdout.writeln('  pagesDir: $pagesDir ($pagesSource)');
  stdout.writeln('  output:   $output ($outputSource)');
  stdout.writeln('  resolved pagesDir: ${_resolvePath(rootDir, pagesDir)}');
  stdout.writeln('  resolved output:  ${_resolvePath(rootDir, output)}');
  return 0;
}

String _sourceLabel(String? cliValue, String? configValue) {
  if (cliValue != null) return 'cli';
  if (configValue != null) return 'config';
  return 'default';
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

String _resolvePath(String baseDir, String value) {
  if (p.isAbsolute(value)) return value;
  return p.normalize(p.join(baseDir, value));
}

_FileRoutingConfig _extractConfig(CompilationUnit unit) {
  String? pagesDir;
  String? output;

  for (final declaration in unit.declarations) {
    if (declaration is! TopLevelVariableDeclaration) continue;
    for (final variable in declaration.variables.variables) {
      final name = variable.name.lexeme;
      if (name != 'pagesDir' && name != 'output') continue;
      final initializer = variable.initializer;
      if (initializer is StringLiteral) {
        final value = initializer.stringValue;
        if (value == null) continue;
        if (name == 'pagesDir') {
          pagesDir = value;
        } else {
          output = value;
        }
      }
    }
  }

  return _FileRoutingConfig(pagesDir: pagesDir, output: output);
}
