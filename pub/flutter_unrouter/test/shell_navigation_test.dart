import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  testWidgets('switchBranch restores branch stack top', (tester) async {
    final router = _createShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-root')), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-push')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feed-detail')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell-to-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-root')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell-to-feed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feed-detail')), findsOneWidget);
  });

  testWidgets(
    'switchBranch(initialLocation: true) resets target branch stack',
    (tester) async {
      final router = _createShellRouter();

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shell-to-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-root')), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-push')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-detail')), findsOneWidget);

      await tester.tap(find.byKey(const Key('shell-to-feed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feed-root')), findsOneWidget);

      await tester.tap(find.byKey(const Key('shell-to-settings-reset')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-root')), findsOneWidget);
      expect(find.byKey(const Key('settings-detail')), findsNothing);
    },
  );

  testWidgets('popBranch completes pending push result', (tester) async {
    final router = _createShellRouter();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('feed-result:-'), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-push')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feed-detail')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell-pop-branch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feed-root')), findsOneWidget);
    expect(find.text('feed-result:55'), findsOneWidget);
  });
}

Unrouter<AppRoute> _createShellRouter() {
  final feedResult = ValueNotifier<int?>(null);

  return Unrouter<AppRoute>(
    history: MemoryHistory(
      initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/feed'))],
      initialIndex: 0,
    ),
    routes: <RouteRecord<AppRoute>>[
      ...shell<AppRoute>(
        branches: <ShellBranch<AppRoute>>[
          branch<AppRoute>(
            initialLocation: Uri(path: '/feed'),
            routes: <RouteRecord<AppRoute>>[
              route<FeedRoute>(
                path: '/feed',
                parse: (_) => const FeedRoute(),
                builder: (context, _) {
                  return Scaffold(
                    body: Column(
                      children: <Widget>[
                        const Text('feed-root', key: Key('feed-root')),
                        FilledButton(
                          key: const Key('feed-push'),
                          onPressed: () async {
                            feedResult.value = await context.unrouter.push<int>(
                              const FeedDetailRoute(id: 1),
                            );
                          },
                          child: const Text('feed push'),
                        ),
                        ValueListenableBuilder<int?>(
                          valueListenable: feedResult,
                          builder: (context, value, child) {
                            return Text('feed-result:${value ?? '-'}');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              route<FeedDetailRoute>(
                path: '/feed/details/:id',
                parse: (state) => FeedDetailRoute(id: state.pathInt('id')),
                builder: (_, route) {
                  return Text(
                    'feed-detail-${route.id}',
                    key: const Key('feed-detail'),
                  );
                },
              ),
            ],
          ),
          branch<AppRoute>(
            initialLocation: Uri(path: '/settings'),
            routes: <RouteRecord<AppRoute>>[
              route<SettingsRoute>(
                path: '/settings',
                parse: (_) => const SettingsRoute(),
                builder: (context, route) {
                  return const Text('settings-root', key: Key('settings-root'));
                },
              ),
              route<SettingsDetailRoute>(
                path: '/settings/details/:tab',
                parse: (state) => SettingsDetailRoute(tab: state.path('tab')),
                builder: (_, route) {
                  return Column(
                    children: <Widget>[
                      Text(
                        'settings-detail-${route.tab}',
                        key: const Key('settings-detail'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
        builder: (context, shell, child) {
          return Scaffold(
            body: Column(
              children: <Widget>[
                Text(
                  'active:${shell.activeBranchIndex}',
                  key: const Key('shell-active'),
                ),
                FilledButton(
                  key: const Key('shell-to-feed'),
                  onPressed: () => shell.goBranch(0),
                  child: const Text('to feed'),
                ),
                FilledButton(
                  key: const Key('shell-to-settings'),
                  onPressed: () => shell.goBranch(1),
                  child: const Text('to settings'),
                ),
                FilledButton(
                  key: const Key('shell-to-settings-reset'),
                  onPressed: () => shell.goBranch(1, initialLocation: true),
                  child: const Text('to settings reset'),
                ),
                FilledButton(
                  key: const Key('shell-pop-branch'),
                  onPressed: () => shell.popBranch(55),
                  child: const Text('pop branch'),
                ),
                if (shell.activeBranchIndex == 1)
                  FilledButton(
                    key: const Key('settings-push'),
                    onPressed: () {
                      context.unrouter.push(
                        const SettingsDetailRoute(tab: 'profile'),
                      );
                    },
                    child: const Text('settings push'),
                  ),
                Expanded(child: child),
              ],
            ),
          );
        },
      ),
    ],
  );
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
  const FeedDetailRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/feed/details/$id');
}

final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  Uri toUri() => Uri(path: '/settings');
}

final class SettingsDetailRoute extends AppRoute {
  const SettingsDetailRoute({required this.tab});

  final String tab;

  @override
  Uri toUri() => Uri(path: '/settings/details/$tab');
}
