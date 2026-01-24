import 'dart:io';

import 'package:coal/args.dart';

import 'commands/init.dart';
import 'commands/generate.dart';
import 'commands/scan.dart';

class UnrouterCLI {
  UnrouterCLI(this.args);

  final List<String> args;

  Future<int> run() async {
    final parsed = Args.parse(
      args,
      bool: const ['help', 'h', 'force'],
      string: const ['pages', 'output'],
    );

    final showHelp =
        parsed.at('help')?.safeAs<bool>() == true ||
        parsed.at('h')?.safeAs<bool>() == true;
    final positionals = parsed.rest.toList();

    if (positionals.isEmpty || showHelp) {
      if (positionals.isEmpty) {
        _printUsage();
        return 0;
      }
    }

    final command = positionals.first;
    if (showHelp) {
      _printCommandUsage(command);
      return 0;
    }
    switch (command) {
      case 'scan':
        return runScan(parsed);
      case 'init':
        return runInit(parsed);
      case 'generate':
        return runGenerate(parsed);
      case 'watch':
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
    stdout.writeln('  init        Create unrouter.config.dart');
    stdout.writeln('');
    stdout.writeln('Options:');
    stdout.writeln('  --pages     Pages directory (default: lib/pages)');
    stdout.writeln('  --output    Generated file path (default: lib/routes.dart)');
    stdout.writeln('  --force     Overwrite existing config file');
    stdout.writeln('  -h, --help  Show usage');
  }

  void _printCommandUsage(String command) {
    switch (command) {
      case 'scan':
        stdout.writeln('unrouter scan [options]');
        stdout.writeln('');
        stdout.writeln('Reads unrouter.config.dart and reports routing config.');
        stdout.writeln('');
        stdout.writeln('Options:');
        stdout.writeln('  --pages     Pages directory (default: lib/pages)');
        stdout.writeln('  --output    Generated file path (default: lib/routes.dart)');
        return;
      case 'init':
        stdout.writeln('unrouter init [options]');
        stdout.writeln('');
        stdout.writeln('Creates unrouter.config.dart in the project root.');
        stdout.writeln('');
        stdout.writeln('Options:');
        stdout.writeln('  --pages     Pages directory (default: lib/pages)');
        stdout.writeln('  --output    Generated file path (default: lib/routes.dart)');
        stdout.writeln('  --force     Overwrite existing config file');
        return;
      case 'generate':
      case 'watch':
        stdout.writeln('unrouter $command [options]');
        stdout.writeln('');
        stdout.writeln('Options:');
        stdout.writeln('  --pages     Pages directory (default: lib/pages)');
        stdout.writeln('  --output    Generated file path (default: lib/routes.dart)');
        return;
      default:
        stdout.writeln('Unknown command: $command');
        _printUsage();
        return;
    }
  }
}
