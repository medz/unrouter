import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/server.dart' as jaspr_server;
import 'package:jaspr_unrouter/jaspr_unrouter.dart';
import 'package:test/test.dart';
import 'package:unstory/unstory.dart';

void main() {
  setUpAll(() {
    jaspr_server.Jaspr.initializeApp();
  });

  test('server render shows matched route output', () async {
    final router = Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home-screen'),
        ),
      ],
    );

    final body = await _renderToHtml(router, path: '/home');

    expect(body, contains('home-screen'));
  });

  test('server render uses default unknown fallback', () async {
    final router = Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home-screen'),
        ),
      ],
    );

    final body = await _renderToHtml(router, path: '/missing');

    expect(body, contains('No route matches /missing'));
  });

  test(
    'server render prefers custom unknown builder (blocked initial resolves as unmatched)',
    () async {
      final router = Unrouter<AppRoute>(
        unknown: (_, uri) => Component.text('unknown:${uri.path}'),
        blocked: (_, uri) => Component.text('blocked:${uri.path}'),
        routes: <RouteRecord<AppRoute>>[
          route<SecureRoute>(
            path: '/secure',
            parse: (_) => const SecureRoute(),
            guards: <RouteGuard<SecureRoute>>[(_) => RouteGuardResult.block()],
            builder: (_, __) => const Component.text('secure-screen'),
          ),
        ],
      );

      final blockedBody = await _renderToHtml(router, path: '/secure');
      expect(blockedBody, contains('unknown:/secure'));

      final unknownBody = await _renderToHtml(router, path: '/404');
      expect(unknownBody, contains('unknown:/404'));
    },
  );

  test('server render uses onError fallback for parser errors', () async {
    final router = Unrouter<AppRoute>(
      onError: (_, error, __) {
        return Component.text('error:${error.runtimeType}');
      },
      routes: <RouteRecord<AppRoute>>[
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) =>
              UserRoute(id: int.parse(state.params.required('id'))),
          builder: (_, __) => const Component.text('user-screen'),
        ),
      ],
    );

    final body = await _renderToHtml(router, path: '/users/not-int');

    expect(body, contains('error:FormatException'));
  });

  test('server render without onError reports 500 for parser errors', () async {
    final router = Unrouter<AppRoute>(
      routes: <RouteRecord<AppRoute>>[
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) =>
              UserRoute(id: int.parse(state.params.required('id'))),
          builder: (_, __) => const Component.text('user-screen'),
        ),
      ],
    );

    final response = await _renderResponse(router, path: '/users/not-int');

    expect(response.statusCode, 500);
  });

  test('resolveInitialRoute=false keeps pending/loading output', () async {
    final router = Unrouter<AppRoute>(
      resolveInitialRoute: false,
      loading: (_, uri) => Component.text('loading:${uri.path}'),
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/home',
          parse: (_) => const HomeRoute(),
          builder: (_, __) => const Component.text('home-screen'),
        ),
      ],
    );

    final body = await _renderToHtml(router, path: '/home');

    expect(body, contains('loading:/home'));
  });

  test('explicit history takes precedence over request path', () async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[
          HistoryLocation(Uri(path: '/history')),
        ],
        initialIndex: 0,
      ),
      routes: <RouteRecord<AppRoute>>[
        route<HistoryRoute>(
          path: '/history',
          parse: (_) => const HistoryRoute(),
          builder: (_, __) => const Component.text('history-screen'),
        ),
      ],
    );

    final body = await _renderToHtml(router, path: '/request');

    expect(body, contains('history-screen'));
  });
}

Future<String> _renderToHtml(Component app, {required String path}) async {
  final response = await _renderResponse(app, path: path);
  return utf8.decode(response.body);
}

Future<jaspr_server.ResponseLike> _renderResponse(
  Component app, {
  required String path,
}) {
  return jaspr_server.renderComponent(
    app,
    request: jaspr_server.Request('GET', Uri.parse('https://example.com$path')),
    standalone: true,
  );
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/home');
}

final class SecureRoute extends AppRoute {
  const SecureRoute();

  @override
  Uri toUri() => Uri(path: '/secure');
}

final class HistoryRoute extends AppRoute {
  const HistoryRoute();

  @override
  Uri toUri() => Uri(path: '/history');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}
