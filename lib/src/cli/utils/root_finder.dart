import 'dart:io';

import 'package:path/path.dart' as p;

import 'constants.dart';

String? findPubspecRoot(String startPath) {
  var current = Directory(startPath).absolute;
  while (true) {
    final candidate = File(p.join(current.path, pubspecFileName));
    if (candidate.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      return null;
    }
    current = parent;
  }
}

String? findConfigPath(Directory start) {
  var current = start.absolute;
  while (true) {
    final candidate = File(p.join(current.path, configFileName));
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
