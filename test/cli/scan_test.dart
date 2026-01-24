import 'dart:io';

import 'package:coal/args.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unrouter/src/cli/commands/scan.dart';

void main() {
  late Directory original;
  late Directory temp;

  setUp(() async {
    original = Directory.current;
    temp = await Directory.systemTemp.createTemp('unrouter_scan_');
    Directory.current = temp;
  });

  tearDown(() {
    Directory.current = original;
    temp.deleteSync(recursive: true);
  });

  Args parseArgs({String? pages, String? output}) {
    final args = <String>[];
    if (pages != null) {
      args..add('--pages')..add(pages);
    }
    if (output != null) {
      args..add('--output')..add(output);
    }
    return Args.parse(
      args,
      string: const ['pages', 'output'],
    );
  }

  void writePubspec(String dirPath) {
    File(p.join(dirPath, 'pubspec.yaml')).writeAsStringSync('name: test');
  }

  void writeConfig(String dirPath, String contents) {
    File(p.join(dirPath, 'unrouter.config.dart')).writeAsStringSync(contents);
  }

  test('scan fails without config or pubspec', () async {
    final code = await runScan(parseArgs());
    expect(code, 1);
  });

  test('scan uses pubspec root when no config file', () async {
    writePubspec(temp.path);

    final pagesDir = Directory(p.join(temp.path, 'lib', 'pages'))
      ..createSync(recursive: true);
    File(p.join(pagesDir.path, 'index.dart')).writeAsStringSync('class A {}');

    final code = await runScan(parseArgs());
    expect(code, 0);
  });

  test('scan uses config values when provided', () async {
    writePubspec(temp.path);
    writeConfig(
      temp.path,
      "const pagesDir = 'pages';\nconst output = 'lib/out.dart';\n",
    );

    final pagesDir = Directory(p.join(temp.path, 'pages'))
      ..createSync(recursive: true);
    File(p.join(pagesDir.path, 'index.dart')).writeAsStringSync('class A {}');

    final code = await runScan(parseArgs());
    expect(code, 0);
  });

  test('scan uses cli pages/output relative to cwd', () async {
    writePubspec(temp.path);
    writeConfig(
      temp.path,
      "const pagesDir = 'pages';\nconst output = 'lib/out.dart';\n",
    );

    final customPages = Directory(p.join(temp.path, 'custom'))
      ..createSync(recursive: true);
    File(p.join(customPages.path, 'home.dart')).writeAsStringSync('class A {}');

    final code = await runScan(parseArgs(pages: 'custom', output: 'lib/routes.dart'));
    expect(code, 0);
  });
}
