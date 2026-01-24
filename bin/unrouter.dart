import 'dart:io';

import 'package:unrouter/cli.dart';

Future<void> main(List<String> args) async {
  final exitCode = await UnrouterCli().run(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
