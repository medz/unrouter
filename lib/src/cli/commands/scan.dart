import 'dart:io';

import 'package:coal/args.dart';
import '../utils/constants.dart';
import '../utils/routing_config.dart';
import '../utils/root_finder.dart';
import '../utils/routing_pages.dart';
import '../utils/routing_paths.dart';

Future<int> runScan(Args parsed) async {
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
    return 1;
  }

  final pagesSource = _sourceLabel(pagesArg, config?.pagesDir);
  final outputSource = _sourceLabel(outputArg, config?.output);

  stdout.writeln('Scan result');
  stdout.writeln('  root: ${resolved.rootDir} (${resolved.rootSource})');
  stdout.writeln(
    '  config: ${configPath ?? '<none>'}',
  );
  stdout.writeln('  pagesDir: ${resolved.pagesDir} ($pagesSource)');
  stdout.writeln('  output:   ${resolved.output} ($outputSource)');
  stdout.writeln('  resolved pagesDir: ${resolved.resolvedPagesDir}');
  stdout.writeln('  resolved output:  ${resolved.resolvedOutput}');

  final pagesDirectory = Directory(resolved.resolvedPagesDir);
  if (!pagesDirectory.existsSync()) {
    stderr.writeln(
      'Pages directory not found: ${resolved.resolvedPagesDir}',
    );
    return 1;
  }

  final routes = scanPages(pagesDirectory, rootDir: resolved.rootDir);
  stdout.writeln('');
  stdout.writeln('Routes (${routes.length}):');
  for (final route in routes) {
    stdout.writeln('  ${route.path} -> ${route.file}');
  }
  return 0;
}

String _sourceLabel(String? cliValue, String? configValue) {
  if (cliValue != null) return 'cli';
  if (configValue != null) return 'config';
  return 'default';
}
