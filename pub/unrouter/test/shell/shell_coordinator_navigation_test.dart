import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  late ShellCoordinator coordinator;

  setUp(() {
    coordinator = ShellCoordinator(
      branches: <ShellBranchDescriptor>[
        ShellBranchDescriptor(
          index: 0,
          name: 'feed',
          initialLocation: Uri(path: '/feed'),
          routePatterns: <String>['/feed', '/feed/:id'],
        ),
        ShellBranchDescriptor(
          index: 1,
          name: 'settings',
          initialLocation: Uri(path: '/settings'),
          routePatterns: <String>['/settings', '/settings/:tab'],
        ),
      ],
    );
  });

  test('recordNavigation tracks push/pop and branch target', () {
    coordinator.recordNavigation(
      branchIndex: 0,
      event: ShellNavigationEvent(
        uri: Uri(path: '/feed'),
        action: HistoryAction.replace,
        delta: null,
        historyIndex: 0,
      ),
    );
    coordinator.recordNavigation(
      branchIndex: 0,
      event: ShellNavigationEvent(
        uri: Uri(path: '/feed/1'),
        action: HistoryAction.push,
        delta: null,
        historyIndex: 1,
      ),
    );
    coordinator.recordNavigation(
      branchIndex: 0,
      event: ShellNavigationEvent(
        uri: Uri(path: '/feed/2'),
        action: HistoryAction.push,
        delta: null,
        historyIndex: 2,
      ),
    );

    expect(coordinator.currentBranchHistory(0).length, 3);
    expect(
      coordinator.resolveBranchTarget(0, initialLocation: false).path,
      '/feed/2',
    );

    coordinator.recordNavigation(
      branchIndex: 0,
      event: ShellNavigationEvent(
        uri: Uri(path: '/feed/1'),
        action: HistoryAction.pop,
        delta: -1,
        historyIndex: 1,
      ),
    );

    expect(
      coordinator.resolveBranchTarget(0, initialLocation: false).path,
      '/feed/1',
    );
    expect(coordinator.canPopBranch(0), isTrue);
  });

  test('recordNavigation ignores duplicate events', () {
    final event = ShellNavigationEvent(
      uri: Uri(path: '/feed/1'),
      action: HistoryAction.push,
      delta: null,
      historyIndex: 1,
    );

    coordinator.recordNavigation(branchIndex: 0, event: event);
    coordinator.recordNavigation(branchIndex: 0, event: event);

    expect(coordinator.currentBranchHistory(0), hasLength(1));
  });

  test(
    'composeHistoryState infers branch from uri and preserves user state',
    () {
      final first = coordinator.composeHistoryState(
        request: ShellHistoryStateRequest(
          uri: Uri(path: '/settings/profile'),
          action: HistoryAction.push,
          state: {'a': 1},
          currentState: null,
        ),
        activeBranchIndex: 0,
      );

      final parsedFirst = coordinator.codec.tryParse(first);
      expect(parsedFirst, isNotNull);
      expect(parsedFirst!.userState, {'a': 1});
      expect(parsedFirst.shell!.activeBranchIndex, 1);

      final second = coordinator.composeHistoryState(
        request: ShellHistoryStateRequest(
          uri: Uri(path: '/settings'),
          action: HistoryAction.replace,
          state: null,
          currentState: first,
        ),
        activeBranchIndex: 1,
      );
      final parsedSecond = coordinator.codec.tryParse(second);
      expect(parsedSecond, isNotNull);
      expect(parsedSecond!.userState, {'a': 1});
    },
  );

  test('branch operations resolve and pop expected target', () {
    coordinator.recordNavigation(
      branchIndex: 1,
      event: ShellNavigationEvent(
        uri: Uri(path: '/settings'),
        action: HistoryAction.replace,
        delta: null,
        historyIndex: 0,
      ),
    );
    coordinator.recordNavigation(
      branchIndex: 1,
      event: ShellNavigationEvent(
        uri: Uri(path: '/settings/profile'),
        action: HistoryAction.push,
        delta: null,
        historyIndex: 1,
      ),
    );

    expect(coordinator.canPopBranch(1), isTrue);
    final popped = coordinator.popBranch(1);
    expect(popped, isNotNull);
    expect(popped!.path, '/settings');
    expect(coordinator.canPopBranch(1), isFalse);
  });
}
