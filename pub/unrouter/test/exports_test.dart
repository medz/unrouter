import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart' as unrouter;

void main() {
  test('layered entrypoints expose expected symbols', () {
    expect(unrouter.RouteGuardResult.allow().isAllowed, isTrue);
    expect(unrouter.RedirectLoopPolicy.values, isNotEmpty);
    expect(unrouter.UnrouterResolutionState.values, isNotEmpty);
    expect(unrouter.UnrouterController, isNotNull);
    expect(unrouter.ShellCoordinator, isNotNull);
    expect(unrouter.ShellRuntimeBinding, isNotNull);
    expect(unrouter.buildShellRouteRecords, isNotNull);
    expect(unrouter.ShellRouteRecordBinding, isNotNull);
    expect(unrouter.ShellState, isNotNull);
    expect(unrouter.ShellRouteRecordHost, isNotNull);
  });
}
