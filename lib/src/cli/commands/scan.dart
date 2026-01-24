import 'dart:io';

import 'package:coal/args.dart';
import 'package:path/path.dart' as p;

import '../utils/constants.dart';
import '../utils/routing_config.dart';
import '../utils/root_finder.dart';
import '../utils/routing_paths.dart';

class _RouteEntry {
  const _RouteEntry({required this.path, required this.file});

  final String path;
  final String file;
}

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

  final routes = _scanPages(pagesDirectory, resolved.rootDir);
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

List<_RouteEntry> _scanPages(Directory pagesDirectory, String rootDir) {
  final entries = <_RouteEntry>[];
  for (final entity in pagesDirectory.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final relative = p.relative(entity.path, from: pagesDirectory.path);
    final withoutExt = relative.substring(0, relative.length - 5);
    final segments = p.split(withoutExt);
    if (segments.isEmpty) continue;

    final pathSegments = <String>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment == 'index' && i == segments.length - 1) {
        continue;
      }
      final dynamic = _parseDynamicSegment(segment);
      if (dynamic != null) {
        pathSegments.add(dynamic);
        continue;
      }
      pathSegments.add(segment);
    }

    final path =
        pathSegments.isEmpty ? '/' : '/${pathSegments.join('/')}';
    final filePath = _relativeOrAbsolute(entity.path, rootDir);
    entries.add(_RouteEntry(path: path, file: filePath));
  }

  entries.sort((a, b) => a.path.compareTo(b.path));
  return entries;
}

String _relativeOrAbsolute(String filePath, String rootDir) {
  if (p.isWithin(rootDir, filePath) || p.equals(rootDir, filePath)) {
    return p.relative(filePath, from: rootDir);
  }
  return p.normalize(filePath);
}

String? _parseDynamicSegment(String segment) {
  if (segment.startsWith('[') && segment.endsWith(']')) {
    final inner = segment.substring(1, segment.length - 1);
    if (inner.startsWith('...') && inner.length > 3) {
      return '*';
    }
    if (inner.isNotEmpty) {
      return ':$inner';
    }
  }
  return null;
}
