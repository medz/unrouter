import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart' as unrouter;
import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart' as core;

void main() {
  test('shell route wrappers resolve through core router', () async {
    final routes = <unrouter.RouteRecord<AppRoute>>[
      ...unrouter.shell<AppRoute>(
        branches: <unrouter.ShellBranch<AppRoute>>[
          unrouter.branch<AppRoute>(
            initialLocation: Uri(path: '/feed'),
            routes: <unrouter.RouteRecord<AppRoute>>[
              unrouter.route<FeedRoute>(
                path: '/feed',
                name: 'feed',
                parse: (_) => const FeedRoute(),
                builder: (_, __) => const Text('feed'),
              ),
            ],
          ),
          unrouter.branch<AppRoute>(
            initialLocation: Uri(path: '/settings'),
            routes: <unrouter.RouteRecord<AppRoute>>[
              unrouter.route<SettingsRoute>(
                path: '/settings',
                name: 'settings',
                parse: (_) => const SettingsRoute(),
                builder: (_, __) => const Text('settings'),
              ),
            ],
          ),
        ],
        builder: (_, __, child) => child,
      ),
    ];
    final router = core.Unrouter<AppRoute>(routes: routes);

    final feedResult = await router.resolve(Uri(path: '/feed'));
    expect(feedResult.isMatched, isTrue);
    expect(feedResult.record, isA<unrouter.RouteRecord<AppRoute>>());
    expect(feedResult.record?.name, 'feed');

    final settingsResult = await router.resolve(Uri(path: '/settings'));
    expect(settingsResult.isMatched, isTrue);
    expect(settingsResult.record, isA<unrouter.RouteRecord<AppRoute>>());
    expect(settingsResult.record?.name, 'settings');
  });

  test('shell route wrappers keep loader execution for data routes', () async {
    final routes = <unrouter.RouteRecord<AppRoute>>[
      ...unrouter.shell<AppRoute>(
        branches: <unrouter.ShellBranch<AppRoute>>[
          unrouter.branch<AppRoute>(
            initialLocation: Uri(path: '/feed-data'),
            routes: <unrouter.RouteRecord<AppRoute>>[
              unrouter.dataRoute<FeedDataRoute, String>(
                path: '/feed-data',
                parse: (_) => const FeedDataRoute(),
                loader: (_) => 'feed:loaded',
                builder: (_, __, data) => Text(data),
              ),
            ],
          ),
        ],
        builder: (_, __, child) => child,
      ),
    ];
    final router = core.Unrouter<AppRoute>(routes: routes);

    final result = await router.resolve(Uri(path: '/feed-data'));
    expect(result.isMatched, isTrue);
    expect(result.loaderData, 'feed:loaded');
  });
}

sealed class AppRoute implements unrouter.RouteData {
  const AppRoute();
}

final class FeedRoute extends AppRoute {
  const FeedRoute();

  @override
  Uri toUri() => Uri(path: '/feed');
}

final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  Uri toUri() => Uri(path: '/settings');
}

final class FeedDataRoute extends AppRoute {
  const FeedDataRoute();

  @override
  Uri toUri() => Uri(path: '/feed-data');
}
