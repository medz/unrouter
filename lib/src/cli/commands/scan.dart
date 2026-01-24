import 'dart:io';

import 'package:coal/args.dart';
import 'package:coal/utils.dart' show getTextWidth;
import 'package:path/path.dart' as p;
import '../utils/cli_output.dart';
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
      '${errorLabel('Error')}: Unable to find $configFileName or $pubspecFileName above the current directory.',
    );
    return 1;
  }

  final pagesSource = _sourceLabel(pagesArg, config?.pagesDir);
  final outputSource = _sourceLabel(outputArg, config?.output);

  stdout.writeln(heading('Scan result'));
  stdout.writeln(
    '  root: ${pathText(resolved.rootDir)} ${dimText('(${resolved.rootSource})')}',
  );
  stdout.writeln(
    '  config: ${configPath == null ? dimText('<none>') : pathText(configPath)}',
  );
  stdout.writeln(
    '  pagesDir: ${pathText(resolved.pagesDir)} ${dimText('($pagesSource)')}',
  );
  stdout.writeln(
    '  output:   ${pathText(resolved.output)} ${dimText('($outputSource)')}',
  );
  stdout.writeln('  resolved pagesDir: ${pathText(resolved.resolvedPagesDir)}');
  stdout.writeln('  resolved output:  ${pathText(resolved.resolvedOutput)}');

  final pagesDirectory = Directory(resolved.resolvedPagesDir);
  if (!pagesDirectory.existsSync()) {
    stderr.writeln(
      '${errorLabel('Error')}: Pages directory not found: ${pathText(resolved.resolvedPagesDir, stderr: true)}',
    );
    return 1;
  }

  final routes = scanPages(pagesDirectory, rootDir: resolved.rootDir);
  stdout.writeln('');
  stdout.writeln('${heading('Routes')} (${routes.length}):');
  if (routes.isEmpty) {
    stdout.writeln(dimText('  <none>'));
    return 0;
  }
  for (final line in _buildRouteTable(routes, resolved.rootDir)) {
    stdout.writeln(line);
  }
  return 0;
}

List<String> _buildRouteTable(List<RouteEntry> routes, String rootDir) {
  final headers = ['Path', 'File'];
  final rows = routes.map((route) {
    final path = route.path.isEmpty ? '/' : '/${route.path}';
    final file = p.relative(route.file, from: rootDir);
    return [path, file];
  }).toList();

  final widths = List<int>.generate(headers.length, (index) {
    var width = getTextWidth(headers[index]).toInt();
    for (final row in rows) {
      width = width < getTextWidth(row[index]).toInt()
          ? getTextWidth(row[index]).toInt()
          : width;
    }
    return width;
  });

  final lines = <String>[];
  lines.add(fitToTerminal(_formatRowStyled(headers, widths)));
  lines.add(
    fitToTerminal(
      dimText(_formatRow(widths.map((w) => '-' * w).toList(), widths)),
    ),
  );
  for (final row in rows) {
    lines.add(fitToTerminal(_formatRowStyled(row, widths)));
  }
  return lines;
}

String _formatRowStyled(List<String> cells, List<int> widths) {
  final padded = <String>[];
  for (var i = 0; i < cells.length; i += 1) {
    final raw = cells[i];
    final value = _padCell(raw, widths[i]);
    if (i == 0) {
      padded.add(pathText(value));
    } else if (raw == 'File') {
      padded.add(heading(value));
    } else if (raw == 'Path') {
      padded.add(heading(value));
    } else {
      padded.add(dimText(value));
    }
  }
  return padded.join('  ');
}

String _formatRow(List<String> cells, List<int> widths) {
  final padded = <String>[];
  for (var i = 0; i < cells.length; i += 1) {
    padded.add(_padCell(cells[i], widths[i]));
  }
  return padded.join('  ');
}

String _padCell(String value, int width) {
  final length = getTextWidth(value).toInt();
  if (length >= width) return value;
  return value + ' ' * (width - length);
}

String _sourceLabel(String? cliValue, String? configValue) {
  if (cliValue != null) return 'cli';
  if (configValue != null) return 'config';
  return 'default';
}
