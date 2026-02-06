import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  testWidgets('renders inspector state and timeline updates', (tester) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            final inspector = context.unrouterAs<AppRoute>().inspector;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UnrouterInspectorWidget<AppRoute>(
                  inspector: inspector,
                  timelineTail: 2,
                ),
                TextButton(
                  key: const Key('to-user-inspector-widget'),
                  onPressed: () {
                    context.unrouter.push(const UserRoute(id: 21));
                  },
                  child: const Text('to-user'),
                ),
              ],
            );
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (context, route) {
            final inspector = context.unrouterAs<AppRoute>().inspector;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('user:${route.id}'),
                UnrouterInspectorWidget<AppRoute>(
                  inspector: inspector,
                  timelineTail: 2,
                ),
              ],
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('state=matched path=/ uri=/'), findsOneWidget);
    expect(find.textContaining('timeline tail'), findsOneWidget);

    await tester.tap(find.byKey(const Key('to-user-inspector-widget')));
    await tester.pumpAndSettle();

    expect(find.text('user:21'), findsOneWidget);
    expect(
      find.textContaining('state=matched path=/users/:id uri=/users/21'),
      findsOneWidget,
    );
    expect(find.textContaining('/users/21'), findsWidgets);
  });

  testWidgets('supports inspector filtering and export callback', (
    tester,
  ) async {
    String? exported;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            final inspector = context.unrouterAs<AppRoute>().inspector;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UnrouterInspectorWidget<AppRoute>(
                  inspector: inspector,
                  timelineTail: 5,
                  timelineQuery: '/users/',
                  onExport: (payload) {
                    exported = payload;
                  },
                ),
                TextButton(
                  key: const Key('to-user-inspector-filter-export'),
                  onPressed: () {
                    context.unrouter.push(const UserRoute(id: 42));
                  },
                  child: const Text('to-user'),
                ),
              ],
            );
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (context, route) {
            final inspector = context.unrouterAs<AppRoute>().inspector;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('user:${route.id}'),
                UnrouterInspectorWidget<AppRoute>(
                  inspector: inspector,
                  timelineTail: 5,
                  timelineQuery: '/users/',
                  onExport: (payload) {
                    exported = payload;
                  },
                ),
              ],
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('to-user-inspector-filter-export')));
    await tester.pumpAndSettle();

    expect(find.text('user:42'), findsOneWidget);
    expect(find.textContaining('/users/42'), findsWidgets);

    await tester.tap(find.byKey(const Key('unrouter-inspector-export')));
    await tester.pumpAndSettle();

    expect(exported, isNotNull);
    final decoded = jsonDecode(exported!) as Map<String, Object?>;
    final timelineTail = decoded['timelineTail'] as List<Object?>;
    expect(timelineTail, isNotEmpty);
    final first = timelineTail.first as Map<String, Object?>;
    expect((first['uri'] as String).contains('/users/'), isTrue);
  });

  testWidgets('renders redirect diagnostics trail when provided', (
    tester,
  ) async {
    final diagnosticsStore = UnrouterRedirectDiagnosticsStore();

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/redirect-a'))],
      ),
      onRedirectDiagnostics: diagnosticsStore.onDiagnostics,
      routes: [
        route<RedirectARoute>(
          path: '/redirect-a',
          parse: (_) => const RedirectARoute(),
          redirect: (_) => Uri(path: '/redirect-b'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
        route<RedirectBRoute>(
          path: '/redirect-b',
          parse: (_) => const RedirectBRoute(),
          redirect: (_) => Uri(path: '/redirect-a'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
      onError: (context, error, stackTrace) {
        final inspector = context.unrouterAs<AppRoute>().inspector;
        return UnrouterInspectorWidget<AppRoute>(
          inspector: inspector,
          redirectDiagnostics: diagnosticsStore,
          redirectTrailTail: 3,
        );
      },
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(diagnosticsStore.value, isNotEmpty);
    expect(
      find.textContaining('/redirect-a -> /redirect-b -> /redirect-a'),
      findsOneWidget,
    );
    final event = diagnosticsStore.value.single;
    expect(event.currentUri, Uri(path: '/redirect-b'));
    expect(event.redirectUri, Uri(path: '/redirect-a'));
    expect(event.trail, <Uri>[
      Uri(path: '/redirect-a'),
      Uri(path: '/redirect-b'),
      Uri(path: '/redirect-a'),
    ]);
  });
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

final class RedirectARoute extends AppRoute {
  const RedirectARoute();

  @override
  Uri toUri() => Uri(path: '/redirect-a');
}

final class RedirectBRoute extends AppRoute {
  const RedirectBRoute();

  @override
  Uri toUri() => Uri(path: '/redirect-b');
}
