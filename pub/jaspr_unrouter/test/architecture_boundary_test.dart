import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('runtime binding does not depend on jaspr_router', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final runtime = File('lib/src/runtime/unrouter.dart').readAsStringSync();

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
  });
}
