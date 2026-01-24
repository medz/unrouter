import 'dart:io';

import 'package:coal/args.dart';
import 'package:coal/coal.dart' show TextStyle;

import 'commands/init.dart';
import 'commands/generate.dart';
import 'commands/scan.dart';
import 'commands/watch.dart';
import 'utils/cli_output.dart';

class UnrouterCLI {
  UnrouterCLI(this.args);

  final List<String> args;

  Future<int> run() async {
    final parsed = Args.parse(
      args,
      bool: const ['help', 'force', 'verbose', 'quiet', 'json', 'no-color'],
      string: const ['pages', 'output'],
      aliases: const {
        'h': 'help',
        'v': 'verbose',
        'q': 'quiet',
        'p': 'pages',
        'o': 'output',
        'f': 'force',
      },
    );
    configureOutput(noColor: parsed.at('no-color')?.safeAs<bool>() == true);

    final showHelp = parsed.at('help')?.safeAs<bool>() == true;
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
        return runWatch(parsed);
      default:
        stderr.writeln('Unknown command: $command');
        _printUsage();
        return 64;
    }
  }

  void _printUsage() {
    _printBanner();
    stdout.writeln(dimText('File-based routing toolkit for Flutter'));
    stdout.writeln('');
    stdout.writeln('${badge('Usage')} unrouter <command> [options]');
    stdout.writeln('');
    stdout.writeln(badge('Commands', background: TextStyle.bgCyan));
    stdout.writeln(
      '  scan     ${dimText('Inspect config and list detected routes')}',
    );
    stdout.writeln(
      '  generate ${dimText('Build routes file from pages directory')}',
    );
    stdout.writeln(
      '  watch    ${dimText('Rebuild routes on file/config changes')}',
    );
    stdout.writeln(
      '  init     ${dimText('Create unrouter.config.dart template')}',
    );
    stdout.writeln('');
    stdout.writeln(badge('Global Options', background: TextStyle.bgMagenta));
    _printGlobalOptions();
    stdout.writeln('');
    stdout.writeln(
      dimText('Use `unrouter <command> --help` to see command options.'),
    );
  }

  void _printCommandUsage(String command) {
    switch (command) {
      case 'scan':
        _printBanner();
        stdout.writeln(heading('unrouter scan'));
        stdout.writeln(dimText('Inspect config and list detected routes.'));
        stdout.writeln('');
        stdout.writeln(
          badge('Global Options', background: TextStyle.bgMagenta),
        );
        _printGlobalOptions();
        stdout.writeln('');
        stdout.writeln(
          badge('Command Options', background: TextStyle.bgYellow),
        );
        stdout.writeln('  -q, --quiet ${dimText('Suppress non-error output')}');
        stdout.writeln(
          '  --json      ${dimText('Emit machine-readable JSON')}',
        );
        return;
      case 'init':
        _printBanner();
        stdout.writeln(heading('unrouter init'));
        stdout.writeln(dimText('Create unrouter.config.dart in project root.'));
        stdout.writeln('');
        stdout.writeln(
          badge('Global Options', background: TextStyle.bgMagenta),
        );
        _printGlobalOptions();
        stdout.writeln('');
        stdout.writeln(
          badge('Command Options', background: TextStyle.bgYellow),
        );
        stdout.writeln(
          '  -f, --force ${dimText('Overwrite existing config file')}',
        );
        stdout.writeln('  -q, --quiet ${dimText('Suppress non-error output')}');
        return;
      case 'generate':
      case 'watch':
        _printBanner();
        stdout.writeln(heading('unrouter $command'));
        if (command == 'watch') {
          stdout.writeln(
            dimText('Regenerates routes when pages or config change.'),
          );
        } else {
          stdout.writeln(dimText('Generate routes file from pages directory.'));
        }
        stdout.writeln('');
        stdout.writeln(
          badge('Global Options', background: TextStyle.bgMagenta),
        );
        _printGlobalOptions();
        stdout.writeln('');
        stdout.writeln(
          badge('Command Options', background: TextStyle.bgYellow),
        );
        if (command == 'generate') {
          stdout.writeln('  -v, --verbose ${dimText('Show detailed output')}');
          stdout.writeln(
            '  -q, --quiet ${dimText('Suppress non-error output')}',
          );
          stdout.writeln(
            '  --json      ${dimText('Emit machine-readable JSON')}',
          );
        } else {
          stdout.writeln(
            '  -q, --quiet ${dimText('Suppress non-error output')}',
          );
        }
        return;
      default:
        stdout.writeln('Unknown command: $command');
        _printUsage();
        return;
    }
  }

  void _printBanner() {
    renderBlock(
      _bannerLines
          .map((line) => accentText(line, TextStyle.cyan, bold: true))
          .toList(),
    );
  }

  void _printGlobalOptions() {
    stdout.writeln(
      '  -p, --pages ${dimText('Pages directory (default: lib/pages)')}',
    );
    stdout.writeln(
      '  -o, --output ${dimText('Generated file path (default: lib/routes.dart)')}',
    );
    stdout.writeln('  --no-color  ${dimText('Disable ANSI colors')}');
    stdout.writeln('  -h, --help  ${dimText('Show usage')}');
  }
}

const List<String> _bannerLines = [
  r" _   _                            _             ",
  r"| | | |                          | |            ",
  r"| | | | _ __   _ __   ___   _   _| |_ ___  _ __ ",
  r"| | | || '_ \ | '__| / _ \ | | | | __/ _ \| '__|",
  r"| |_| || | | || |   | (_) || |_| | ||  __/| |   ",
  r" \___/ |_| |_||_|    \___/  \__,_|\__\___||_|   ",
];
