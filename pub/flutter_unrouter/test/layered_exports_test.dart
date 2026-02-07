import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/machine.dart' as machine;
import 'package:flutter_unrouter/flutter_unrouter.dart' as unrouter;

void main() {
  test('layered entrypoints expose expected symbols', () {
    expect(unrouter.RouteGuardResult.allow().isAllowed, isTrue);
    expect(unrouter.RedirectLoopPolicy.values, isNotEmpty);

    expect(machine.UnrouterMachineCommand.back(), isNotNull);
    expect(machine.UnrouterMachineTypedPayloadKind.values, isNotEmpty);
  });
}
