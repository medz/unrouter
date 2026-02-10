import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('ShellState delegates branch operations', () {
    int? goIndex;
    bool? goInitialLocation;
    bool? goCompletePendingResult;
    Object? goResult;
    Object? popResult;

    final state = ShellState<AppRoute>(
      activeBranchIndex: 1,
      branches: <ShellBranch<AppRoute>>[
        branch<AppRoute>(
          initialLocation: Uri(path: '/feed'),
          routes: <RouteRecord<AppRoute>>[
            route<AppRoute>(
              path: '/feed',
              parse: (_) => const AppRoute('/feed'),
            ),
          ],
        ),
        branch<AppRoute>(
          initialLocation: Uri(path: '/settings'),
          routes: <RouteRecord<AppRoute>>[
            route<AppRoute>(
              path: '/settings',
              parse: (_) => const AppRoute('/settings'),
            ),
          ],
        ),
      ],
      currentUri: Uri(path: '/settings'),
      currentBranchHistory: <Uri>[Uri(path: '/settings')],
      onGoBranch:
          (
            index, {
            required initialLocation,
            required completePendingResult,
            result,
          }) {
            goIndex = index;
            goInitialLocation = initialLocation;
            goCompletePendingResult = completePendingResult;
            goResult = result;
          },
      onPopBranch: ([result]) {
        popResult = result;
        return true;
      },
      onCanPopBranch: () => true,
    );

    expect(state.activeBranchIndex, 1);
    expect(state.branchCount, 2);
    expect(state.currentUri.path, '/settings');
    expect(state.currentBranchHistory, <Uri>[Uri(path: '/settings')]);

    state.goBranch(
      0,
      initialLocation: true,
      completePendingResult: true,
      result: 42,
    );
    expect(goIndex, 0);
    expect(goInitialLocation, isTrue);
    expect(goCompletePendingResult, isTrue);
    expect(goResult, 42);

    expect(state.popBranch('done'), isTrue);
    expect(popResult, 'done');
    expect(state.canPopBranch(), isTrue);
  });

  test('shell flattens branch routes in order', () {
    final branchA = branch<AppRoute>(
      initialLocation: Uri(path: '/a'),
      routes: <RouteRecord<AppRoute>>[
        route<AppRoute>(path: '/a', parse: (_) => const AppRoute('/a')),
      ],
    );
    final branchB = branch<AppRoute>(
      initialLocation: Uri(path: '/b'),
      routes: <RouteRecord<AppRoute>>[
        route<AppRoute>(path: '/b', parse: (_) => const AppRoute('/b')),
      ],
    );

    final flattened = shell<AppRoute>(
      branches: <ShellBranch<AppRoute>>[branchA, branchB],
    ).toList();

    expect(flattened, hasLength(2));
    expect(flattened[0].path, '/a');
    expect(flattened[1].path, '/b');
  });

  test('shell asserts when branches are empty', () {
    expect(
      () => shell<AppRoute>(branches: const <ShellBranch<AppRoute>>[]),
      throwsA(isA<AssertionError>()),
    );
  });
}

final class AppRoute implements RouteData {
  const AppRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}
