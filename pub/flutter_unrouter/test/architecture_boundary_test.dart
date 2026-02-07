import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell runtime does not carry duplicated core algorithms', () {
    final source = File(
      'lib/src/core/route_definition_shell.dart',
    ).readAsStringSync();

    expect(source.contains('_CoreShellCoordinator'), isTrue);

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
}
