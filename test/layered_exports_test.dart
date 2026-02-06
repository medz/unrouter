import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/core.dart' as core;
import 'package:unrouter/devtools.dart' as devtools;
import 'package:unrouter/machine.dart' as machine;
import 'package:unrouter/unrouter.dart' as unrouter;

void main() {
  test('layered entrypoints expose expected symbols', () {
    expect(core.RouteGuardResult.allow().isAllowed, isTrue);
    expect(core.RedirectLoopPolicy.values, isNotEmpty);
    expect(unrouter.RouteGuardResult.allow().isAllowed, isTrue);

    expect(machine.UnrouterMachineActionEnvelopeState.values, isNotEmpty);
    expect(machine.UnrouterMachineCommand.back(), isNotNull);

    const bridgeConfig = devtools.UnrouterInspectorBridgeConfig();
    expect(bridgeConfig.timelineTail, 10);
    expect(devtools.UnrouterInspectorReplayCompareMode.values, isNotEmpty);
  });
}
