import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

class RoutingConfig {
  const RoutingConfig({this.pagesDir, this.output});

  final String? pagesDir;
  final String? output;
}

Future<RoutingConfig?> readRoutingConfig(
  String? configPath, {
  void Function(String message)? onError,
}) async {
  if (configPath == null) return null;
  String content;
  try {
    content = await File(configPath).readAsString();
  } on FileSystemException catch (error) {
    onError?.call('Failed to read $configPath: $error');
    return null;
  } catch (error) {
    onError?.call('Failed to read $configPath: $error');
    return null;
  }
  final result = parseString(
    content: content,
    throwIfDiagnostics: false,
    path: configPath,
  );
  if (result.errors.isNotEmpty && onError != null) {
    onError('Failed to parse $configPath:');
    for (final error in result.errors) {
      onError('  ${error.toString()}');
    }
  }
  return _extractConfig(result.unit);
}

RoutingConfig _extractConfig(CompilationUnit unit) {
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

  return RoutingConfig(pagesDir: pagesDir, output: output);
}
