import 'dart:io';

import 'package:coal/args.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unrouter/src/cli/commands/init.dart';

void main() {
  late Directory original;
  late Directory temp;

  setUp(() async {
    original = Directory.current;
    temp = await Directory.systemTemp.createTemp('unrouter_init_');
    Directory.current = temp;
  });

  tearDown(() {
    Directory.current = original;
    temp.deleteSync(recursive: true);
  });

  Args parseArgs({String? pages, String? output, bool force = false}) {
    final args = <String>[];
    if (pages != null) {
      args
        ..add('--pages')
        ..add(pages);
    }
    if (output != null) {
      args
        ..add('--output')
        ..add(output);
    }
    if (force) {
      args.add('--force');
    }
    return Args.parse(
      args,
      bool: const ['force'],
      string: const ['pages', 'output'],
    );
  }

  void writePubspec(String dirPath) {
    File(p.join(dirPath, 'pubspec.yaml')).writeAsStringSync('name: test');
  }

  test('init creates config, pages, and output with defaults', () async {
    writePubspec(temp.path);

    final code = await runInit(parseArgs());
    expect(code, 0);

    final configFile = File(p.join(temp.path, 'unrouter.config.dart'));
    expect(configFile.existsSync(), true);
    expect(
      configFile.readAsStringSync(),
      buildConfigContents(
        pagesDir: p.join('lib', 'pages'),
        output: p.join('lib', 'routes.dart'),
      ),
    );

    expect(Directory(p.join(temp.path, 'lib', 'pages')).existsSync(), true);
    final outputFile = File(p.join(temp.path, 'lib', 'routes.dart'));
    expect(outputFile.existsSync(), true);
    expect(outputFile.readAsStringSync(), outputTemplate);
  });

  test('init prefers output root when multiple pubspecs exist', () async {
    writePubspec(temp.path);
    final nested = Directory(p.join(temp.path, 'nested'))..createSync();
    writePubspec(nested.path);
    final child = Directory(p.join(nested.path, 'child'))..createSync();

    Directory.current = child;

    final output = p.join('..', '..', 'lib', 'routes.dart');
    final pages = p.join('pages');
    final code = await runInit(parseArgs(pages: pages, output: output));
    expect(code, 0);

    final configFile = File(p.join(temp.path, 'unrouter.config.dart'));
    expect(configFile.existsSync(), true);
    expect(
      configFile.readAsStringSync(),
      buildConfigContents(
        pagesDir: p.join('nested', 'child', 'pages'),
        output: p.join('lib', 'routes.dart'),
      ),
    );

    expect(Directory(p.join(child.path, 'pages')).existsSync(), true);
    expect(File(p.join(temp.path, 'lib', 'routes.dart')).existsSync(), true);
  });

  test('init fails when no pubspec.yaml is found', () async {
    final code = await runInit(parseArgs());
    expect(code, 1);
    expect(File(p.join(temp.path, 'unrouter.config.dart')).existsSync(), false);
  });

  test('init does not overwrite existing config without --force', () async {
    writePubspec(temp.path);
    final configFile = File(p.join(temp.path, 'unrouter.config.dart'));
    configFile.writeAsStringSync('const pagesDir = "custom";');

    final code = await runInit(parseArgs(pages: 'lib/pages'));
    expect(code, 0);
    expect(configFile.readAsStringSync(), 'const pagesDir = "custom";');
    expect(Directory(p.join(temp.path, 'lib', 'pages')).existsSync(), false);
  });

  test('init overwrites config with --force', () async {
    writePubspec(temp.path);
    final configFile = File(p.join(temp.path, 'unrouter.config.dart'));
    configFile.writeAsStringSync('const pagesDir = "custom";');

    final code = await runInit(parseArgs(force: true));
    expect(code, 0);
    expect(
      configFile.readAsStringSync(),
      buildConfigContents(
        pagesDir: p.join('lib', 'pages'),
        output: p.join('lib', 'routes.dart'),
      ),
    );
    expect(Directory(p.join(temp.path, 'lib', 'pages')).existsSync(), true);
    expect(File(p.join(temp.path, 'lib', 'routes.dart')).existsSync(), true);
  });
}
