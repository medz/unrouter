import 'dart:io';

import 'package:path/path.dart' as p;

import 'constants.dart';
import 'root_finder.dart';

enum ConfigSource { cli, config, defaultValue }

class RoutingPaths {
  RoutingPaths({
    required this.rootDir,
    required this.rootSource,
    required this.pagesDir,
    required this.output,
    required this.pagesSource,
    required this.outputSource,
    required this.resolvedPagesDir,
    required this.resolvedOutput,
  });

  final String rootDir;
  final String rootSource;
  final String pagesDir;
  final String output;
  final ConfigSource pagesSource;
  final ConfigSource outputSource;
  final String resolvedPagesDir;
  final String resolvedOutput;
}

RoutingPaths? resolveRoutingPaths({
  required Directory cwd,
  required String? configPath,
  required String? pagesArg,
  required String? outputArg,
  required String? configPages,
  required String? configOutput,
}) {
  final configRoot = configPath == null
      ? null
      : File(configPath).absolute.parent.path;
  final pagesDir = pagesArg ?? configPages ?? defaultPagesDir;
  final output = outputArg ?? configOutput ?? defaultOutput;

  final pagesSource = pagesArg != null
      ? ConfigSource.cli
      : (configPages != null ? ConfigSource.config : ConfigSource.defaultValue);
  final outputSource = outputArg != null
      ? ConfigSource.cli
      : (configOutput != null
            ? ConfigSource.config
            : ConfigSource.defaultValue);

  final rootDir = configRoot ?? _resolveRootFromCli(cwd.path, pagesDir, output);
  if (rootDir == null) {
    return null;
  }

  final resolvedPagesDir = _resolveValue(
    value: pagesDir,
    source: pagesSource,
    cwd: cwd.path,
    configRoot: configRoot,
    rootDir: rootDir,
  );
  final resolvedOutput = _resolveValue(
    value: output,
    source: outputSource,
    cwd: cwd.path,
    configRoot: configRoot,
    rootDir: rootDir,
  );

  return RoutingPaths(
    rootDir: rootDir,
    rootSource: configRoot != null ? 'config' : 'pubspec',
    pagesDir: pagesDir,
    output: output,
    pagesSource: pagesSource,
    outputSource: outputSource,
    resolvedPagesDir: resolvedPagesDir,
    resolvedOutput: resolvedOutput,
  );
}

String? _resolveRootFromCli(String cwd, String pagesDir, String output) {
  final outputAbsolute = _resolvePath(cwd, output);
  final pagesAbsolute = _resolvePath(cwd, pagesDir);
  return findPubspecRoot(p.dirname(outputAbsolute)) ??
      findPubspecRoot(p.dirname(pagesAbsolute));
}

String _resolveValue({
  required String value,
  required ConfigSource source,
  required String cwd,
  required String? configRoot,
  required String rootDir,
}) {
  String base;
  switch (source) {
    case ConfigSource.cli:
      base = cwd;
      break;
    case ConfigSource.config:
      base = configRoot ?? rootDir;
      break;
    case ConfigSource.defaultValue:
      base = configRoot ?? rootDir;
      break;
  }
  return _resolvePath(base, value);
}

String _resolvePath(String baseDir, String value) {
  if (p.isAbsolute(value)) return value;
  return p.normalize(p.join(baseDir, value));
}
