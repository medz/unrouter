import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:coal/args.dart';
import 'package:coal/coal.dart' show TextStyle;
import 'package:coal/utils.dart' show getTextWidth;
import 'package:path/path.dart' as p;

import '../utils/constants.dart';
import '../utils/cli_output.dart';
import '../utils/routing_config.dart';
import '../utils/root_finder.dart';
import '../utils/routing_pages.dart';
import '../utils/routing_paths.dart';

Future<int> runGenerate(
  Args parsed, {
  bool quiet = false,
  List<String>? errorLines,
}) async {
  final cwd = Directory.current;
  final configPath = findConfigPath(cwd);
  final verboseFlag = parsed.at('verbose')?.safeAs<bool>() == true;
  final quietFlag = parsed.at('quiet')?.safeAs<bool>() == true;
  final json = parsed.at('json')?.safeAs<bool>() == true;
  final quietOutput = quiet || quietFlag || json;
  final verbose = verboseFlag && !quietOutput;

  void reportError(String message) {
    errorLines?.add(message);
    stderr.writeln(message);
  }

  final config = await readRoutingConfig(configPath, onError: reportError);

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
    reportError(
      '${errorLabel('Error')}: Unable to find $configFileName or $pubspecFileName above the current directory.',
    );
    return 1;
  }

  if (!quietOutput) {
    stdout.writeln(heading('Generate routes'));
    stdout.writeln(
      '  root: ${pathText(resolved.rootDir)} ${dimText('(${resolved.rootSource})')}',
    );
    stdout.writeln(
      '  config: ${configPath == null ? dimText('<none>') : pathText(configPath)}',
    );
    stdout.writeln(
      '  pages: ${pathText(resolved.resolvedPagesDir)} ${dimText('(${resolved.pagesDir})')}',
    );
    stdout.writeln(
      '  output: ${pathText(resolved.resolvedOutput)} ${dimText('(${resolved.output})')}',
    );
    stdout.writeln('');
    stdout.writeln(
      '${infoLabel('Scanning')}: ${pathText(resolved.resolvedPagesDir)}',
    );
  }

  final pagesDirectory = Directory(resolved.resolvedPagesDir);
  if (!pagesDirectory.existsSync()) {
    reportError(
      '${errorLabel('Error')}: Pages directory not found: ${pathText(resolved.resolvedPagesDir, stderr: true)}',
    );
    return 1;
  }

  var scanFailed = false;
  final scannedRoutes = scanPages(
    pagesDirectory,
    rootDir: resolved.rootDir,
    onError: (message) {
      scanFailed = true;
      reportError('${errorLabel('Error')}: $message');
    },
  );
  if (scanFailed) {
    return 1;
  }
  final routeFiles = <_RouteFile>[];
  final usedAliases = <String>{};
  final seenTreeKeys = <String, String>{};

  for (final entry in scannedRoutes) {
    final normalizedPath = _normalizeRoutePath(entry.path);
    final treeKey = _treeKey(entry.treeSegments);
    if (seenTreeKeys.containsKey(treeKey)) {
      reportError(
        '${errorLabel('Error')}: Duplicate route path "${_treePathLabel(entry.treeSegments)}" from ${entry.file} and ${seenTreeKeys[treeKey]}.',
      );
      return 1;
    }
    seenTreeKeys[treeKey] = entry.file;

    final absoluteFile = _absoluteFile(entry.file, resolved.rootDir);
    final parsedRoute = _parseRouteFile(absoluteFile);
    if (parsedRoute.error != null) {
      reportError('${errorLabel('Error')}: ${parsedRoute.error}');
      return 1;
    }
    final className = parsedRoute.className;
    if (className == null) {
      reportError(
        '${errorLabel('Error')}: No page widget class found in $absoluteFile. Expected a class extending a Widget type.',
      );
      return 1;
    }
    final meta = parsedRoute.meta;

    final importPath = _relativeImportPath(
      fromFile: resolved.resolvedOutput,
      targetFile: absoluteFile,
    );
    final alias = _uniqueAlias(
      _aliasBase(absoluteFile, pagesDirectory.path),
      usedAliases,
    );

    routeFiles.add(
      _RouteFile(
        path: normalizedPath,
        filePath: absoluteFile,
        treeSegments: entry.treeSegments,
        pathSegments: entry.pathSegments,
        isIndex: entry.isIndex,
        importPath: importPath,
        importAlias: alias,
        className: className,
        hasName: meta?.hasName ?? false,
        nameLiteral: meta?.nameLiteral,
        hasGuards: meta?.hasGuards ?? false,
        guardRefs: meta?.guardRefs,
      ),
    );
  }

  routeFiles.sort(_compareRoutePaths);

  if (!quietOutput) {
    stdout.writeln(
      '${infoLabel('Found')}: ${routeFiles.length} routes ${dimText('(use --verbose for table)')}',
    );
  }

  if (_validateDuplicatePaths(routeFiles, reportError)) {
    return 1;
  }

  final routesByTree = <String, _RouteFile>{
    for (final route in routeFiles) _treeKey(route.treeSegments): route,
  };

  final nodesByTree = <String, _RouteNode>{
    for (final route in routeFiles) _treeKey(route.treeSegments): _RouteNode(route),
  };

  final roots = <_RouteNode>[];
  for (final route in routeFiles) {
    final parent = _findParentRoute(route, routesByTree);
    final node = nodesByTree[_treeKey(route.treeSegments)]!;
    if (parent == null) {
      roots.add(node);
    } else {
      nodesByTree[_treeKey(parent.treeSegments)]!.children.add(node);
    }
  }

  roots.sort((a, b) => _compareRoutePaths(a.route, b.route));
  for (final node in nodesByTree.values) {
    node.children.sort((a, b) => _compareRoutePaths(a.route, b.route));
  }
  for (final root in roots) {
    _computeConstFlags(root);
  }
  final useConstRoutes = roots.every((node) => node.canConst);

  final outputFile = File(resolved.resolvedOutput);
  final guardImports = _collectGuardImports(routeFiles, outputFile.path);
  if (guardImports.error != null) {
    reportError('${errorLabel('Error')}: ${guardImports.error}');
    return 1;
  }

  if (verbose && routeFiles.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('${heading('Routes')} (${routeFiles.length}):');
    for (final line in _buildRouteTable(routeFiles, resolved.rootDir)) {
      stdout.writeln(line);
    }
    stdout.writeln('');
  }

  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    _buildOutput(
      routeFiles,
      roots,
      guardImports: guardImports.imports,
      useConstRoutes: useConstRoutes,
    ),
  );

  if (json) {
    final payload = <String, Object?>{
      'root': resolved.rootDir,
      'rootSource': resolved.rootSource,
      'config': configPath,
      'pagesDir': resolved.pagesDir,
      'output': resolved.output,
      'resolvedPagesDir': resolved.resolvedPagesDir,
      'resolvedOutput': resolved.resolvedOutput,
      'routes': routeFiles
          .map(
            (route) => {
              'path': route.path.isEmpty ? '/' : '/${route.path}',
              'file': p.relative(route.filePath, from: resolved.rootDir),
              'name': route.nameLiteral,
              'nameExpression': route.hasName && route.nameLiteral == null,
              'guards': route.guardRefs
                  ?.map(
                    (guard) => guard.prefix == null
                        ? guard.name
                        : '${guard.prefix}.${guard.name}',
                  )
                  .toList(),
              'guardsExpression': route.hasGuards && route.guardRefs == null,
            },
          )
          .toList(),
    };
    stdout.writeln(jsonEncode(payload));
  } else if (!quietOutput) {
    stdout.writeln(
      '${successLabel('Wrote')} ${pathText(_relativeToCwd(outputFile.path))}.',
    );
  }
  return 0;
}

List<String> _buildRouteTable(List<_RouteFile> routes, String rootDir) {
  final headers = ['Path', 'File', 'Name', 'Guards'];
  final rows = routes.map((route) {
    final path = route.path.isEmpty ? '/' : '/${route.path}';
    final file = p.relative(route.filePath, from: rootDir);
    final name = _nameDisplay(route);
    final guards = _guardsDisplay(route);
    return [path, file, name, guards];
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
  lines.add(
    fitToTerminal(
      _formatRowStyled(headers, widths, (index, padded, _) => heading(padded)),
    ),
  );
  lines.add(
    fitToTerminal(
      dimText(_formatRow(widths.map((w) => '-' * w).toList(), widths)),
    ),
  );
  for (final row in rows) {
    lines.add(
      fitToTerminal(
        _formatRowStyled(
          row,
          widths,
          (index, padded, raw) => _styleRouteCell(index, padded, raw),
        ),
      ),
    );
  }
  return lines;
}

String _formatRowStyled(
  List<String> cells,
  List<int> widths,
  String Function(int index, String padded, String raw) styler,
) {
  final padded = <String>[];
  for (var i = 0; i < cells.length; i += 1) {
    final raw = cells[i];
    final value = _padCell(raw, widths[i]);
    padded.add(styler(i, value, raw));
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

String _styleRouteCell(int index, String padded, String raw) {
  switch (index) {
    case 0:
      return pathText(padded);
    case 1:
      return dimText(padded);
    case 2:
      if (raw == '-') return dimText(padded);
      if (raw == '<expr>') return warningLabel(padded);
      return accentText(padded, TextStyle.magenta, bold: true);
    case 3:
      if (raw == '-') return dimText(padded);
      if (raw == '<expr>') return warningLabel(padded);
      return accentText(padded, TextStyle.yellow, bold: true);
    default:
      return padded;
  }
}

String _nameDisplay(_RouteFile route) {
  if (!route.hasName) return '-';
  return route.nameLiteral ?? '<expr>';
}

String _guardsDisplay(_RouteFile route) {
  if (!route.hasGuards) return '-';
  final guards = route.guardRefs;
  if (guards == null) return '<expr>';
  if (guards.isEmpty) return '-';
  return guards
      .map(
        (guard) =>
            guard.prefix == null ? guard.name : '${guard.prefix}.${guard.name}',
      )
      .join(', ');
}

String _normalizeRoutePath(String path) {
  if (path == '/' || path.isEmpty) return '';
  if (path.startsWith('/')) return path.substring(1);
  return path;
}

String _treeKey(List<String> segments) {
  if (segments.isEmpty) return '';
  return segments.join('/');
}

String _treePathLabel(List<String> segments) {
  if (segments.isEmpty) return '/';
  return segments.join('/');
}

int _compareRoutePaths(_RouteFile a, _RouteFile b) {
  final pathCompare = a.path.compareTo(b.path);
  if (pathCompare != 0) return pathCompare;
  final treeA = _treeKey(a.treeSegments);
  final treeB = _treeKey(b.treeSegments);
  return treeA.compareTo(treeB);
}

bool _validateDuplicatePaths(
  List<_RouteFile> routes,
  void Function(String message) reportError,
) {
  final routesByPath = <String, List<_RouteFile>>{};
  for (final route in routes) {
    routesByPath.putIfAbsent(route.path, () => []).add(route);
  }

  var hasError = false;
  for (final entry in routesByPath.entries) {
    final list = entry.value;
    if (list.length <= 1) continue;
    list.sort(
      (a, b) => a.treeSegments.length.compareTo(b.treeSegments.length),
    );
    for (var i = 1; i < list.length; i++) {
      final shorter = list[i - 1];
      final longer = list[i];
      if (!_isTreePrefix(shorter.treeSegments, longer.treeSegments)) {
        reportError(
          '${errorLabel('Error')}: Route path "${_normalizeRoutePath(entry.key).isEmpty ? '/' : '/${_normalizeRoutePath(entry.key)}'}" maps to multiple unrelated files: ${_relativeToCwd(shorter.filePath)} and ${_relativeToCwd(longer.filePath)}.',
        );
        hasError = true;
        break;
      }
      if (shorter.isIndex) {
        reportError(
          '${errorLabel('Error')}: Index route ${_relativeToCwd(shorter.filePath)} cannot act as a parent for other routes with the same path "${_normalizeRoutePath(entry.key).isEmpty ? '/' : '/${_normalizeRoutePath(entry.key)}'}".',
        );
        hasError = true;
        break;
      }
    }
  }
  return hasError;
}

bool _isTreePrefix(List<String> a, List<String> b) {
  if (a.length >= b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _absoluteFile(String filePath, String rootDir) {
  if (p.isAbsolute(filePath)) return filePath;
  return p.normalize(p.join(rootDir, filePath));
}

String _relativeImportPath({
  required String fromFile,
  required String targetFile,
}) {
  final fromDir = p.dirname(fromFile);
  var relative = p.relative(targetFile, from: fromDir);
  relative = p.normalize(relative);
  relative = relative.replaceAll('\\', '/');
  if (!relative.startsWith('.')) {
    relative = './$relative';
  }
  return relative;
}

String _buildOutput(
  List<_RouteFile> routes,
  List<_RouteNode> roots, {
  required Map<String, String> guardImports,
  required bool useConstRoutes,
}) {
  final imports = <String, String>{};
  for (final route in routes) {
    imports[route.importPath] = route.importAlias;
  }

  final sortedImports = imports.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln("import 'package:unrouter/unrouter.dart';");

  final sortedGuardImports = guardImports.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in sortedGuardImports) {
    buffer.writeln("import '${entry.value}' as ${entry.key};");
  }

  for (final entry in sortedImports) {
    buffer.writeln("import '${entry.key}' as ${entry.value};");
  }

  buffer
    ..writeln('')
    ..writeln('${useConstRoutes ? 'const' : 'final'} routes = <Inlet>[');

  for (final node in roots) {
    _writeRouteNode(
      buffer,
      node,
      parent: null,
      indent: 1,
      constContext: useConstRoutes,
    );
  }

  buffer.writeln('];');
  return buffer.toString();
}

String _escapeString(String value) {
  final escaped = value.replaceAll('\\', '\\\\');
  return escaped.replaceAll("'", "\\'");
}

_RouteFile? _findParentRoute(
  _RouteFile route,
  Map<String, _RouteFile> routesByTree,
) {
  if (route.treeSegments.length <= 1) return null;
  for (var i = route.treeSegments.length - 1; i >= 1; i--) {
    final prefix = _treeKey(route.treeSegments.sublist(0, i));
    final candidate = routesByTree[prefix];
    if (candidate != null && !candidate.isIndex) {
      return candidate;
    }
  }
  return null;
}

void _computeConstFlags(_RouteNode node) {
  var childrenConst = true;
  for (final child in node.children) {
    _computeConstFlags(child);
    if (!child.canConst) {
      childrenConst = false;
    }
  }
  node.childrenConst = childrenConst;
  final selfConst = _isSelfConst(node.route);
  if (node.children.isNotEmpty) {
    node.canConst = selfConst && childrenConst;
  } else {
    node.canConst = selfConst;
  }
}

bool _isSelfConst(_RouteFile route) {
  if (route.hasName && route.nameLiteral == null) return false;
  if (route.hasGuards && route.guardRefs == null) return false;
  return true;
}

void _writeRouteNode(
  StringBuffer buffer,
  _RouteNode node, {
  required _RouteNode? parent,
  required int indent,
  required bool constContext,
}) {
  final indentStr = '  ' * indent;
  final relativePath = _relativePath(node.route, parent?.route);
  final pathLiteral = _escapeString(relativePath);
  final hasChildren = node.children.isNotEmpty;
  final hasMeta = node.route.hasName || node.route.hasGuards;
  final useConst = node.canConst && !constContext;
  final effectiveConstContext = constContext || useConst;

  if (!hasChildren && !hasMeta) {
    buffer.writeln(
      '$indentStr${useConst ? 'const ' : ''}Inlet(path: \'$pathLiteral\', factory: ${node.route.importAlias}.${node.route.className}.new),',
    );
    return;
  }

  buffer
    ..writeln('$indentStr${useConst ? 'const ' : ''}Inlet(')
    ..writeln('$indentStr  path: \'$pathLiteral\',');

  if (node.route.hasName) {
    if (node.route.nameLiteral != null) {
      final nameLiteral = _escapeString(node.route.nameLiteral!);
      buffer.writeln('$indentStr  name: \'$nameLiteral\',');
    } else {
      buffer.writeln('$indentStr  name: ${node.route.importAlias}.route.name,');
    }
  }
  if (node.route.hasGuards) {
    final guardRefs = node.route.guardRefs;
    if (guardRefs == null) {
      buffer.writeln(
        '$indentStr  guards: ${node.route.importAlias}.route.guards,',
      );
    } else {
      buffer.writeln(
        '$indentStr  guards: ${_buildGuardList(node.route, guardRefs)},',
      );
    }
  }

  buffer.writeln(
    '$indentStr  factory: ${node.route.importAlias}.${node.route.className}.new,',
  );

  if (hasChildren) {
    final childrenConst = node.childrenConst;
    final useConstList = childrenConst && !effectiveConstContext;
    buffer.writeln('$indentStr  children: ${useConstList ? 'const ' : ''}[');
    for (final child in node.children) {
      _writeRouteNode(
        buffer,
        child,
        parent: node,
        indent: indent + 2,
        constContext: effectiveConstContext || useConstList,
      );
    }
    buffer.writeln('$indentStr  ],');
  }

  buffer.writeln('$indentStr),');
}

String _relativePath(_RouteFile route, _RouteFile? parent) {
  if (parent == null) return route.path;
  final offset = parent.pathSegments.length;
  if (route.pathSegments.length <= offset) return '';
  return route.pathSegments.sublist(offset).join('/');
}

String _buildGuardList(_RouteFile route, List<_GuardRef> guardRefs) {
  final parts = guardRefs
      .map((guard) {
        if (guard.prefix == null) {
          return '${route.importAlias}.${guard.name}';
        }
        return '${guard.prefix}.${guard.name}';
      })
      .join(', ');
  return '[$parts]';
}

String _aliasBase(String filePath, String pagesRoot) {
  var relative = p.relative(filePath, from: pagesRoot);
  relative = relative.replaceAll('\\', '/');
  if (relative.endsWith('.dart')) {
    relative = relative.substring(0, relative.length - 5);
  }
  final sanitized = _sanitizeIdentifier(relative.replaceAll('/', '_'));
  return 'page_$sanitized';
}

String _sanitizeIdentifier(String value) {
  var sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
  sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
  if (sanitized.isEmpty) return 'root';
  return sanitized.toLowerCase();
}

String _uniqueAlias(String base, Set<String> usedAliases) {
  var alias = base;
  var counter = 1;
  while (usedAliases.contains(alias)) {
    alias = '${base}_$counter';
    counter += 1;
  }
  usedAliases.add(alias);
  return alias;
}

_RouteParseResult _parseRouteFile(String filePath) {
  String content;
  try {
    content = File(filePath).readAsStringSync();
  } on FileSystemException catch (error) {
    return _RouteParseResult(error: 'Failed to read $filePath: $error');
  } catch (error) {
    return _RouteParseResult(error: 'Failed to read $filePath: $error');
  }
  final result = parseString(
    content: content,
    throwIfDiagnostics: false,
    path: filePath,
  );

  final className = _findPageClassName(result.unit);
  final topLevelFunctions = _collectTopLevelFunctions(result.unit);
  final importPrefixes = _collectImportPrefixes(result.unit);
  final metaResult = _extractRouteMeta(
    result.unit,
    filePath,
    topLevelFunctions,
    importPrefixes,
  );
  if (metaResult.error != null) {
    return _RouteParseResult(error: metaResult.error);
  }

  return _RouteParseResult(className: className, meta: metaResult.meta);
}

String? _findPageClassName(CompilationUnit unit) {
  final preferred = <String>[];
  final candidates = <String>[];

  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final extendsClause = declaration.extendsClause;
    if (extendsClause == null) continue;

    final className = declaration.namePart.typeName.lexeme;
    final superName = extendsClause.superclass.name.lexeme;

    if (_isPreferredClassName(className)) {
      preferred.add(className);
      continue;
    }

    if (_isWidgetBase(superName)) {
      candidates.add(className);
    }
  }

  if (preferred.isNotEmpty) return preferred.first;
  if (candidates.isNotEmpty) return candidates.first;
  return null;
}

Set<String> _collectTopLevelFunctions(CompilationUnit unit) {
  final functions = <String>{};
  for (final declaration in unit.declarations) {
    if (declaration is FunctionDeclaration) {
      functions.add(declaration.name.lexeme);
    }
  }
  return functions;
}

Map<String, String> _collectImportPrefixes(CompilationUnit unit) {
  final prefixes = <String, String>{};
  for (final directive in unit.directives) {
    if (directive is! ImportDirective) continue;
    final prefix = directive.prefix?.name;
    if (prefix == null || prefix.isEmpty) continue;
    final uri = directive.uri.stringValue;
    if (uri != null) {
      prefixes[prefix] = uri;
    }
  }
  return prefixes;
}

_RouteMetaResult _extractRouteMeta(
  CompilationUnit unit,
  String filePath,
  Set<String> topLevelFunctions,
  Map<String, String> importPrefixes,
) {
  _RouteMeta? meta;

  for (final declaration in unit.declarations) {
    if (declaration is! TopLevelVariableDeclaration) continue;
    for (final variable in declaration.variables.variables) {
      if (variable.name.lexeme != 'route') continue;
      if (meta != null) {
        return _RouteMetaResult(
          error: 'Multiple route definitions found in $filePath.',
        );
      }

      final initializer = variable.initializer;
      ArgumentList? args;
      if (initializer is InstanceCreationExpression) {
        final typeName = initializer.constructorName.type.name.lexeme;
        if (typeName != 'RouteMeta') {
          return _RouteMetaResult(
            error: 'The "route" variable in $filePath must be a RouteMeta.',
          );
        }
        args = initializer.argumentList;
      } else if (initializer is MethodInvocation) {
        if (initializer.methodName.name != 'RouteMeta') {
          return _RouteMetaResult(
            error: 'The "route" variable in $filePath must be a RouteMeta.',
          );
        }
        args = initializer.argumentList;
      } else {
        return _RouteMetaResult(
          error: 'The "route" variable in $filePath must be a RouteMeta.',
        );
      }

      var hasName = false;
      String? nameLiteral;
      var hasGuards = false;
      List<_GuardRef>? guardRefs;

      for (final argument in args.arguments) {
        if (argument is! NamedExpression) {
          return _RouteMetaResult(
            error:
                'RouteMeta in $filePath must use named arguments: name, guards.',
          );
        }
        final label = argument.name.label.name;

        if (label == 'name') {
          hasName = true;
          final expression = argument.expression;
          if (expression is StringLiteral) {
            nameLiteral = expression.stringValue;
          }
          continue;
        }

        if (label == 'guards') {
          hasGuards = true;
          final expression = argument.expression;
          if (expression is! ListLiteral) {
            return _RouteMetaResult(
              error: 'RouteMeta.guards in $filePath must be a list literal.',
            );
          }
          guardRefs = _parseGuardList(
            expression,
            topLevelFunctions,
            importPrefixes,
          );
          continue;
        }
      }

      meta = _RouteMeta(
        hasName: hasName,
        nameLiteral: nameLiteral,
        hasGuards: hasGuards,
        guardRefs: guardRefs,
      );
    }
  }

  return _RouteMetaResult(meta: meta);
}

bool _isPreferredClassName(String className) {
  return className.endsWith('Page') || className.endsWith('Screen');
}

bool _isWidgetBase(String superName) {
  return superName.endsWith('Widget');
}

String _relativeToCwd(String absolutePath) {
  final cwd = Directory.current.absolute.path;
  if (p.isWithin(cwd, absolutePath) || p.equals(cwd, absolutePath)) {
    return p.relative(absolutePath, from: cwd);
  }
  return absolutePath;
}

List<_GuardRef>? _parseGuardList(
  ListLiteral list,
  Set<String> topLevelFunctions,
  Map<String, String> importPrefixes,
) {
  final refs = <_GuardRef>[];
  for (final element in list.elements) {
    if (element is! Expression) {
      return null;
    }
    if (element is SimpleIdentifier) {
      final name = element.name;
      if (name.startsWith('_')) return null;
      if (!topLevelFunctions.contains(name)) {
        return null;
      }
      refs.add(_GuardRef.local(name));
      continue;
    }
    if (element is PrefixedIdentifier) {
      final prefix = element.prefix.name;
      final name = element.identifier.name;
      if (name.startsWith('_')) return null;
      final uri = importPrefixes[prefix];
      if (uri == null) {
        return null;
      }
      refs.add(_GuardRef.imported(prefix: prefix, uri: uri, name: name));
      continue;
    }
    return null;
  }
  return refs;
}

class _RouteFile {
  const _RouteFile({
    required this.path,
    required this.filePath,
    required this.treeSegments,
    required this.pathSegments,
    required this.isIndex,
    required this.importPath,
    required this.importAlias,
    required this.className,
    required this.hasName,
    required this.nameLiteral,
    required this.hasGuards,
    required this.guardRefs,
  });

  final String path;
  final String filePath;
  final List<String> treeSegments;
  final List<String> pathSegments;
  final bool isIndex;
  final String importPath;
  final String importAlias;
  final String className;
  final bool hasName;
  final String? nameLiteral;
  final bool hasGuards;
  final List<_GuardRef>? guardRefs;
}

class _RouteNode {
  _RouteNode(this.route);

  final _RouteFile route;
  final List<_RouteNode> children = [];
  bool canConst = false;
  bool childrenConst = false;
}

class _RouteMeta {
  const _RouteMeta({
    required this.hasName,
    required this.nameLiteral,
    required this.hasGuards,
    required this.guardRefs,
  });

  final bool hasName;
  final String? nameLiteral;
  final bool hasGuards;
  final List<_GuardRef>? guardRefs;
}

class _RouteMetaResult {
  const _RouteMetaResult({this.meta, this.error});

  final _RouteMeta? meta;
  final String? error;
}

class _RouteParseResult {
  const _RouteParseResult({this.className, this.meta, this.error});

  final String? className;
  final _RouteMeta? meta;
  final String? error;
}

_GuardImportResult _collectGuardImports(
  List<_RouteFile> routes,
  String outputFile,
) {
  final imports = <String, String>{};
  final pageAliases = {for (final route in routes) route.importAlias};
  final outputDir = p.dirname(outputFile);

  for (final route in routes) {
    final guardRefs = route.guardRefs;
    if (guardRefs == null) continue;
    for (final guard in guardRefs) {
      final prefix = guard.prefix;
      final uri = guard.uri;
      if (prefix == null || uri == null) continue;
      if (pageAliases.contains(prefix)) {
        return _GuardImportResult(
          imports: imports,
          error:
              'Guard import prefix "$prefix" in ${route.filePath} conflicts with a generated alias.',
        );
      }
      final resolvedUri = _resolveImportUri(
        uri: uri,
        fromFile: route.filePath,
        outputDir: outputDir,
      );
      final existing = imports[prefix];
      if (existing != null && existing != resolvedUri) {
        return _GuardImportResult(
          imports: imports,
          error:
              'Guard import prefix "$prefix" is used for multiple URIs: $existing, $resolvedUri.',
        );
      }
      imports[prefix] = resolvedUri;
    }
  }

  return _GuardImportResult(imports: imports);
}

String _resolveImportUri({
  required String uri,
  required String fromFile,
  required String outputDir,
}) {
  if (uri.startsWith('package:') ||
      uri.startsWith('dart:') ||
      uri.startsWith('asset:')) {
    return uri;
  }
  final fromDir = p.dirname(fromFile);
  final absolute = p.normalize(p.join(fromDir, uri));
  var relative = p.relative(absolute, from: outputDir);
  relative = p.normalize(relative).replaceAll('\\', '/');
  if (!relative.startsWith('.')) {
    relative = './$relative';
  }
  return relative;
}

class _GuardRef {
  const _GuardRef.local(this.name) : prefix = null, uri = null;

  const _GuardRef.imported({
    required this.prefix,
    required this.uri,
    required this.name,
  });

  final String name;
  final String? prefix;
  final String? uri;
}

class _GuardImportResult {
  const _GuardImportResult({required this.imports, this.error});

  final Map<String, String> imports;
  final String? error;
}
