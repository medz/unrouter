import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/devtools.dart' as devtools;
import 'package:unrouter/machine.dart' as machine;
import 'package:unrouter/unrouter.dart' as unrouter;

void main() {
  test('layered entrypoints expose expected symbols', () {
    expect(unrouter.RouteGuardResult.allow().isAllowed, isTrue);
    expect(unrouter.RedirectLoopPolicy.values, isNotEmpty);

    expect(machine.UnrouterMachineActionEnvelopeState.values, isNotEmpty);
    expect(machine.UnrouterMachineCommand.back(), isNotNull);

    const bridgeConfig = devtools.UnrouterInspectorBridgeConfig();
    expect(bridgeConfig.timelineTail, 10);
    expect(devtools.UnrouterInspectorReplayCompareMode.values, isNotEmpty);
  });
}
