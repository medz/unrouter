import 'dart:io';

import 'package:test/test.dart';

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

  test('runtime binding does not depend on jaspr_router', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final runtime = File('lib/src/runtime/unrouter.dart').readAsStringSync();
    final routeDefs = File(
      'lib/src/core/route_definition.dart',
    ).readAsStringSync();

    expect(
      pubspec.contains('jaspr_router:'),
      isFalse,
      reason: 'jaspr_unrouter should not depend on jaspr_router.',
    );
    expect(
      runtime.contains('jaspr_router'),
      isFalse,
      reason: 'runtime binding should be driven by core controller.',
    );
    expect(
      runtime.contains('core.UnrouterController<'),
      isTrue,
      reason: 'runtime binding should directly use core controller runtime.',
    );
    expect(
      runtime.contains('setShellBranchResolvers('),
      isTrue,
      reason: 'runtime binding should wire shell branch resolvers from core.',
    );
    expect(
      runtime.contains('class Unrouter<'),
      isTrue,
      reason: 'adapter runtime should expose a direct Unrouter component.',
    );
    expect(
      runtime.contains('class UnrouterRouter<'),
      isFalse,
      reason: 'legacy UnrouterRouter wrapper should be removed.',
    );
    expect(
      runtime.contains('core.Unrouter<R> get coreRouter'),
      isFalse,
      reason: 'adapter should not expose trivial core passthrough getters.',
    );
    expect(
      runtime.contains('RouteRecord<R>? routeRecordOf('),
      isFalse,
      reason: 'adapter should avoid redundant record-cast shim APIs.',
    );
    expect(routeDefs.contains('class ShellState<'), isFalse);
    expect(
      routeDefs.contains('abstract interface class ShellRouteRecordHost<'),
      isFalse,
    );
  });
}
