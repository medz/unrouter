import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('branchIndexForUri matches static and dynamic patterns', () {
    final coordinator = ShellCoordinator(
      branches: <ShellBranchDescriptor>[
        ShellBranchDescriptor(
          index: 0,
          initialLocation: Uri(path: '/feed'),
          routePatterns: <String>['/feed', '/feed/:id'],
        ),
        ShellBranchDescriptor(
          index: 1,
          initialLocation: Uri(path: '/settings'),
          routePatterns: <String>['/settings', '/settings/:tab'],
        ),
      ],
    );

    expect(coordinator.branchIndexForUri(Uri(path: '/feed')), 0);
    expect(coordinator.branchIndexForUri(Uri(path: '/feed/42')), 0);
    expect(coordinator.branchIndexForUri(Uri(path: '/settings/profile')), 1);
    expect(coordinator.branchIndexForUri(Uri(path: '/settings/')), 1);
    expect(coordinator.branchIndexForUri(Uri(path: '/unknown')), isNull);
  });
}
