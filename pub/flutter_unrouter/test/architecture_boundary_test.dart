import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell runtime does not carry duplicated core algorithms', () {
    final source = File(
      'lib/src/core/route_definition_shell.dart',
    ).readAsStringSync();

    expect(source.contains('core.ShellRuntimeBinding'), isTrue);

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

    expect(source.contains('typedef UnrouterController<'), isFalse);
    expect(source.contains('class UnrouterController<'), isFalse);
    expect(source.contains("import 'package:unrouter/unrouter.dart';"), isTrue);
  });

  test('runtime API inherits core router runtime directly', () {
    final runtime = File('lib/src/runtime/unrouter.dart').readAsStringSync();

    expect(runtime.contains('typedef CoreUnrouter<'), isFalse);
    expect(
      runtime.contains(
        'class Unrouter<R extends RouteData> extends core.Unrouter<R>',
      ),
      isTrue,
    );
    expect(runtime.contains('core.Unrouter<R> get coreRouter'), isFalse);
    expect(runtime.contains('RouteRecord<R>? routeRecordOf('), isFalse);
  });
}
