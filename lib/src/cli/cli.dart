import 'dart:io';

import 'package:coal/args.dart';

class UnrouterCLI {
  UnrouterCLI(this.args);

  final List<String> args;

  Future<int> run() async {
    final parsed = Args.parse(
      args,
      bool: const ['help', 'h'],
      string: const ['pages', 'output'],
    );

    final showHelp =
        parsed.at('help')?.safeAs<bool>() == true ||
        parsed.at('h')?.safeAs<bool>() == true;
    final positionals = parsed.rest.toList();

    if (positionals.isEmpty || showHelp) {
      _printUsage();
      return 0;
    }

    final command = positionals.first;
    switch (command) {
      case 'scan':
      case 'generate':
      case 'watch':
      case 'init':
        stderr.writeln('Command "$command" is not implemented yet.');
        return 2;
      default:
        stderr.writeln('Unknown command: $command');
        _printUsage();
        return 64;
    }
  }

  void _printUsage() {
    stdout.writeln('unrouter <command> [options]');
    stdout.writeln('');
    stdout.writeln('Commands:');
    stdout.writeln('  scan        Scan pages directory and print routes');
    stdout.writeln('  generate    Generate routes file from pages');
    stdout.writeln('  watch       Watch pages directory and regenerate');
    stdout.writeln('  init        Create a starter pages directory');
    stdout.writeln('');
    stdout.writeln('Options:');
    stdout.writeln('  --pages     Pages directory (default: lib/pages)');
    stdout.writeln('  --output    Generated file path (default: lib/routes.g.dart)');
    stdout.writeln('  -h, --help  Show usage');
  }
}
