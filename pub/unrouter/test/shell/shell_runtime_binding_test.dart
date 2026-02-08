import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('tracks branch stack and supports pop within active branch', () {
    final runtime = ShellRuntimeBinding<AppRoute>(branches: _branches());

    runtime.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed'),
      action: HistoryAction.replace,
      delta: null,
      historyIndex: 0,
    );
    runtime.recordNavigation(
      branchIndex: 0,
      uri: Uri(path: '/feed/details/1'),
      action: HistoryAction.push,
      delta: null,
      historyIndex: 1,
    );

    expect(runtime.canPopBranch(0), isTrue);
    expect(runtime.currentBranchHistory(0), <Uri>[
      Uri(path: '/feed'),
      Uri(path: '/feed/details/1'),
    ]);
    expect(runtime.popBranch(0), Uri(path: '/feed'));
    expect(runtime.currentBranchHistory(0), <Uri>[
      Uri(path: '/feed'),
      Uri(path: '/feed/details/1'),
    ]);
  });

  test('composes/restores shell history state envelope', () {
    final runtime = ShellRuntimeBinding<AppRoute>(branches: _branches());

    final composedState = runtime.composeHistoryState(
      uri: Uri(path: '/settings'),
      action: HistoryAction.replace,
      state: const <String, Object?>{'from': 'test'},
      currentState: null,
      activeBranchIndex: 1,
    );
    final parsed = const ShellStateEnvelopeCodec().tryParse(composedState);
    expect(parsed, isNotNull);
    expect(parsed!.shell, isNotNull);
    expect(parsed.shell!.activeBranchIndex, 1);
    expect(parsed.userState, const <String, Object?>{'from': 'test'});

    final restored = ShellRuntimeBinding<AppRoute>(branches: _branches());
    restored.restoreFromState(composedState);
    expect(
      restored.resolveTargetUri(1, initialLocation: false),
      Uri(path: '/settings'),
    );
  });
}

List<ShellBranch<AppRoute>> _branches() {
  return <ShellBranch<AppRoute>>[
    branch<AppRoute>(
      initialLocation: Uri(path: '/feed'),
      routes: <RouteRecord<AppRoute>>[
        route<FeedRoute>(path: '/feed', parse: (_) => const FeedRoute()),
        route<FeedDetailRoute>(
          path: '/feed/details/:id',
          parse: (_) => const FeedDetailRoute(),
        ),
      ],
    ),
    branch<AppRoute>(
      initialLocation: Uri(path: '/settings'),
      routes: <RouteRecord<AppRoute>>[
        route<SettingsRoute>(
          path: '/settings',
          parse: (_) => const SettingsRoute(),
        ),
      ],
    ),
  ];
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class FeedRoute extends AppRoute {
  const FeedRoute();

  @override
  Uri toUri() => Uri(path: '/feed');
}

final class FeedDetailRoute extends AppRoute {
  const FeedDetailRoute();

  @override
  Uri toUri() => Uri(path: '/feed/details/1');
}

final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  Uri toUri() => Uri(path: '/settings');
}
