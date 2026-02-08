import 'package:test/test.dart';
import 'package:unrouter/src/shell/shell_branch_descriptor.dart';
import 'package:unrouter/src/shell/shell_coordinator.dart';
import 'package:unstory/unstory.dart';

void main() {
  late ShellCoordinator coordinator;

  setUp(() {
    coordinator = ShellCoordinator(
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
  });

  test('recordNavigation tracks push/pop and branch target', () {
    coordinator.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed'),
      action: HistoryAction.replace,
      delta: null,
      historyIndex: 0,
    );
    coordinator.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed/1'),
      action: HistoryAction.push,
      delta: null,
      historyIndex: 1,
    );
    coordinator.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed/2'),
      action: HistoryAction.push,
      delta: null,
      historyIndex: 2,
    );

    expect(coordinator.currentBranchHistory(0).length, 3);
    expect(
      coordinator.resolveBranchTarget(0, initialLocation: false).path,
      '/feed/2',
    );

    coordinator.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed/1'),
      action: HistoryAction.pop,
      delta: -1,
      historyIndex: 1,
    );

    expect(
      coordinator.resolveBranchTarget(0, initialLocation: false).path,
      '/feed/1',
    );
    expect(coordinator.canPopBranch(0), isTrue);
  });

  test('recordNavigation ignores duplicate events', () {
    coordinator.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed/1'),
      action: HistoryAction.push,
      delta: null,
      historyIndex: 1,
    );
    coordinator.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed/1'),
      action: HistoryAction.push,
      delta: null,
      historyIndex: 1,
    );

    expect(coordinator.currentBranchHistory(0), hasLength(1));
  });

  test('branch operations resolve and pop expected target', () {
    coordinator.recordNavigation(
      branchIndex: 1,
      uri: Uri(path: '/settings'),
      action: HistoryAction.replace,
      delta: null,
      historyIndex: 0,
    );
    coordinator.recordNavigation(
      branchIndex: 1,
      uri: Uri(path: '/settings/profile'),
      action: HistoryAction.push,
      delta: null,
      historyIndex: 1,
    );

    expect(coordinator.canPopBranch(1), isTrue);
    final popped = coordinator.popBranch(1);
    expect(popped, isNotNull);
    expect(popped!.path, '/settings');
    expect(coordinator.canPopBranch(1), isFalse);
  });
}
