import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('core package does not import flutter libraries', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList(growable: false);

    expect(dartFiles, isNotEmpty);

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        source.contains("import 'package:flutter"),
        isFalse,
        reason: 'Forbidden flutter import in ${file.path}',
      );
      expect(
        source.contains("import 'dart:ui'"),
        isFalse,
        reason: 'Forbidden dart:ui import in ${file.path}',
      );
    }
  });
}
