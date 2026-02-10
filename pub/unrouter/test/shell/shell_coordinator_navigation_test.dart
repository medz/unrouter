import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  late ShellCoordinator<_AppRoute> coordinator;

  setUp(() {
    coordinator = ShellCoordinator<_AppRoute>(branches: _branches());
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

List<ShellBranch<_AppRoute>> _branches() {
  return <ShellBranch<_AppRoute>>[
    branch<_AppRoute>(
      initialLocation: Uri(path: '/feed'),
      routes: <RouteRecord<_AppRoute>>[
        route<_AppRoute>(path: '/feed', parse: (_) => const _AppRoute('/feed')),
        route<_AppRoute>(
          path: '/feed/:id',
          parse: (_) => const _AppRoute('/feed/0'),
        ),
      ],
    ),
    branch<_AppRoute>(
      initialLocation: Uri(path: '/settings'),
      routes: <RouteRecord<_AppRoute>>[
        route<_AppRoute>(
          path: '/settings',
          parse: (_) => const _AppRoute('/settings'),
        ),
        route<_AppRoute>(
          path: '/settings/:tab',
          parse: (_) => const _AppRoute('/settings/profile'),
        ),
      ],
    ),
  ];
}

final class _AppRoute implements RouteData {
  const _AppRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}
