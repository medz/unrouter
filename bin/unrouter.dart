import 'dart:io';

import 'package:unrouter/cli.dart';

Future<void> main(List<String> args) async {
  final cli = UnrouterCLI(args);
  final exitCode = await cli.run();
  if (exitCode != 0) {
    exit(exitCode);
  }
}
