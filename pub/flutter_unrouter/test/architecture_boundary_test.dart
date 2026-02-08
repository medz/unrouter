import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell runtime does not carry duplicated core algorithms', () {
    final source = File(
      'lib/src/core/route_definition_shell.dart',
    ).readAsStringSync();

    expect(source.contains('unrouter_core.ShellRuntimeBinding'), isTrue);

    const forbiddenTokens = <String>[
      '_UnrouterStateEnvelope',
      '_ShellRestorationSnapshot',
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
  });

  test('controller binding reuses core controller type', () {
    final source = File('lib/src/runtime/navigation.dart').readAsStringSync();

    expect(source.contains('typedef UnrouterController<'), isTrue);
    expect(source.contains('class UnrouterController<'), isFalse);
  });

  test('runtime API inherits core router runtime directly', () {
    final runtime = File('lib/src/runtime/unrouter.dart').readAsStringSync();

    expect(runtime.contains('typedef CoreUnrouter<'), isTrue);
    expect(
      runtime.contains(
        'class Unrouter<R extends RouteData> extends core.Unrouter<R>',
      ),
      isTrue,
    );
    expect(runtime.contains('final CoreUnrouter<R> _core;'), isFalse);
  });
}
