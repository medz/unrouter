import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  testWidgets('loading builder renders while pending and swaps on completion', (
    tester,
  ) async {
    final loader = Completer<String>();
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/slow'))],
        initialIndex: 0,
      ),
      resolveInitialRoute: true,
      publishPendingState: true,
      loading: (_, _) => const Text('loading', key: Key('loading')),
      routes: <RouteRecord<AppRoute>>[
        dataRoute<SlowRoute, String>(
          path: '/slow',
          parse: (_) => const SlowRoute(),
          loader: (_) => loader.future,
          builder: (_, _, data) =>
              Text('loaded:$data', key: const Key('done')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.byKey(const Key('loading')), findsOneWidget);
    expect(find.byKey(const Key('done')), findsNothing);

    loader.complete('ok');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loading')), findsNothing);
    expect(find.text('loaded:ok'), findsOneWidget);
  });

  testWidgets('onError fallback handles parser failures', (tester) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[
          HistoryLocation(Uri(path: '/users/not-int')),
        ],
        initialIndex: 0,
      ),
      resolveInitialRoute: true,
      onError: (_, error, _) {
        return Text('error:${error.runtimeType}', key: const Key('error'));
      },
      routes: <RouteRecord<AppRoute>>[
        route<AppRoute>(
          path: '/users/:id',
          parse: (state) {
            final id = int.parse(state.params.required('id'));
            return UserRoute(id: id);
          },
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error')), findsOneWidget);
    expect(find.textContaining('FormatException'), findsOneWidget);
  });

  testWidgets('default unknown page renders unmatched path', (tester) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/404'))],
        initialIndex: 0,
      ),
      resolveInitialRoute: true,
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('No route matches /404'), findsOneWidget);
  });
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/home');
}

final class SlowRoute extends AppRoute {
  const SlowRoute();

  @override
  Uri toUri() => Uri(path: '/slow');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}
