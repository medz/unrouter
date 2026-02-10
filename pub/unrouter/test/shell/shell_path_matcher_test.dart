import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('branchIndexForUri matches static and dynamic patterns', () {
    final coordinator = ShellCoordinator<_AppRoute>(branches: _branches());

    expect(coordinator.branchIndexForUri(Uri(path: '/feed')), 0);
    expect(coordinator.branchIndexForUri(Uri(path: '/feed/42')), 0);
    expect(coordinator.branchIndexForUri(Uri(path: '/settings/profile')), 1);
    expect(coordinator.branchIndexForUri(Uri(path: '/settings/')), 1);
    expect(coordinator.branchIndexForUri(Uri(path: '/unknown')), isNull);
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
