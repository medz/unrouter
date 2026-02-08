import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adapter source does not reintroduce dotted typedef aliases', () {
    final aliasPattern = RegExp(r'typedef\s+\w+\s*=\s*[A-Za-z_]\w*\.');
    final violations = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final source = entity.readAsStringSync();
      if (aliasPattern.hasMatch(source)) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Found dotted typedef aliases that look like core passthroughs: '
          '${violations.join(', ')}',
    );
  });

  test('shell runtime does not carry duplicated core algorithms', () {
    final source = File('lib/src/core/route_shell.dart').readAsStringSync();

    expect(source.contains('ShellCoordinator<'), isTrue);

    const forbiddenTokens = <String>[
      '_UnrouterStateEnvelope',
      '_BranchStackSnapshot',
      '_BranchStack',
      '_pathMatchesRoutePattern',
      '_normalizeShellPathForMatch',
    ];

    for (final token in forbiddenTokens) {
      expect(
        source.contains(token),
        isFalse,
        reason: 'Found forbidden duplicated shell runtime token: $token',
      );
    }

    expect(source.contains('class ShellState<'), isFalse);
    expect(
      source.contains('abstract interface class ShellRouteRecordHost<'),
      isFalse,
    );
    expect(source.contains('ShellRouteRecordBinding<'), isFalse);
    expect(source.contains('ShellRouteRecordHost'), isTrue);
    expect(source.contains('buildShellRouteRecords<'), isTrue);
    expect(source.contains('_asAdapterRouteRecord'), isFalse);
  });

  test('controller binding reuses core controller type', () {
    final source = File('lib/src/runtime/navigation.dart').readAsStringSync();

    expect(source.contains('typedef UnrouterController<'), isFalse);
    expect(source.contains('class UnrouterController<'), isFalse);
    expect(source.contains("import 'package:unrouter/unrouter.dart';"), isTrue);
  });

  test('runtime API inherits core router runtime directly', () {
    final runtime = File('lib/src/runtime/unrouter.dart').readAsStringSync();
    final delegate = File(
      'lib/src/runtime/router_delegate.dart',
    ).readAsStringSync();

    expect(runtime.contains('typedef CoreUnrouter<'), isFalse);
    expect(
      runtime.contains(
        'class Unrouter<R extends RouteData> extends core.Unrouter<R>',
      ),
      isTrue,
    );
    expect(runtime.contains('core.Unrouter<R> get coreRouter'), isFalse);
    expect(runtime.contains('RouteRecord<R>? routeRecordOf('), isFalse);
    expect(runtime.contains('typedef RouteLoadingBuilder ='), isTrue);
    expect(runtime.contains('final RouteLoadingBuilder? loading;'), isTrue);
    expect(
      delegate.contains("import 'package:unrouter/unrouter.dart' hide"),
      isFalse,
    );
    expect(delegate.contains('resolveRouteResolution<'), isFalse);
    expect(delegate.contains('syncControllerResolution('), isFalse);
    expect(delegate.contains('final unknown = config.unknown;'), isTrue);
  });
}
