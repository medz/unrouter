import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  group('Unrouter.resolve', () {
    test('constructor keeps blocked fallback builder', () {
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        blocked: (context, uri) => const SizedBox.shrink(),
        routes: [
          route<HomeRoute>(
            path: '/',
            parse: (_) => const HomeRoute(),
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      expect(router.blocked, isNotNull);
    });

    test('constructor keeps loading fallback builder with uri', () {
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        loading: (context, uri) => const SizedBox.shrink(),
        routes: [
          route<HomeRoute>(
            path: '/',
            parse: (_) => const HomeRoute(),
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      expect(router.loading, isNotNull);
    });

    test('matches path and decodes typed params/query', () async {
      final router = _buildBasicRouter();

      final result = await router.resolve(
        Uri(path: '/users/42', queryParameters: {'tab': 'likes'}),
      );

      expect(result.isMatched, isTrue);
      expect(result.hasError, isFalse);
      expect(result.route, isA<UserRoute>());

      final user = result.route! as UserRoute;
      expect(user.id, 42);
      expect(user.tab, UserTab.likes);
    });

    test('returns unmatched when no route matches', () async {
      final router = _buildBasicRouter();

      final result = await router.resolve(
        Uri(path: '/missing'),
        signal: const RouteNeverCancelledSignal(),
      );

      expect(result.isUnmatched, isTrue);
      expect(result.hasError, isFalse);
      expect(result.route, isNull);
    });

    test('captures parser errors', () async {
      final router = _buildBasicRouter();

      final result = await router.resolve(
        Uri(path: '/users/1', queryParameters: {'tab': 'unknown'}),
        signal: const RouteNeverCancelledSignal(),
      );

      expect(result.hasError, isTrue);
      expect(result.error, isA<FormatException>());
    });

    test('returns redirect result from route redirect callback', () async {
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        routes: [
          route<HomeRoute>(
            path: '/',
            parse: (_) => const HomeRoute(),
            builder: (_, _) => const SizedBox.shrink(),
          ),
          route<PrivateRoute>(
            path: '/private',
            parse: (_) => const PrivateRoute(),
            redirect: (_) => Uri(path: '/login'),
            builder: (_, _) => const SizedBox.shrink(),
          ),
          route<LoginRoute>(
            path: '/login',
            parse: (_) => const LoginRoute(),
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      final result = await router.resolve(
        Uri(path: '/private'),
        signal: const RouteNeverCancelledSignal(),
      );

      expect(result.isRedirect, isTrue);
      expect(result.redirectUri, Uri(path: '/login'));
    });

    test('returns blocked result when guard blocks route', () async {
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        routes: [
          route<AdminRoute>(
            path: '/admin',
            parse: (_) => const AdminRoute(),
            guards: [(_) => RouteGuardResult.block()],
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      final result = await router.resolve(
        Uri(path: '/admin'),
        signal: const RouteNeverCancelledSignal(),
      );

      expect(result.isBlocked, isTrue);
    });

    test('returns redirect result when guard redirects route', () async {
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        routes: [
          route<PrivateRoute>(
            path: '/private',
            parse: (_) => const PrivateRoute(),
            guards: [
              (_) => RouteGuardResult.redirect(uri: Uri(path: '/login')),
            ],
            builder: (_, _) => const SizedBox.shrink(),
          ),
          route<LoginRoute>(
            path: '/login',
            parse: (_) => const LoginRoute(),
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      final result = await router.resolve(
        Uri(path: '/private'),
        signal: const RouteNeverCancelledSignal(),
      );

      expect(result.isRedirect, isTrue);
      expect(result.redirectUri, Uri(path: '/login'));
    });

    test('returns loader data for loaded routes', () async {
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        routes: [
          dataRoute<ProfileRoute, String>(
            path: '/profiles/:id',
            parse: (state) => ProfileRoute(id: state.params.$int('id')),
            loader: (context) => 'profile:${context.route.id}',
            builder: (_, _, data) => Text(data),
          ),
        ],
      );

      final result = await router.resolve(
        Uri(path: '/profiles/7'),
        signal: const RouteNeverCancelledSignal(),
      );

      expect(result.isMatched, isTrue);
      expect(result.loaderData, 'profile:7');
    });

    test('returns loader data for shell-wrapped loaded routes', () async {
      final router = Unrouter<AppRoute>(
        history: MemoryHistory(),
        routes: [
          ...shell<AppRoute>(
            branches: <ShellBranch<AppRoute>>[
              branch<AppRoute>(
                initialLocation: Uri(path: '/shell-feed'),
                routes: <RouteRecord<AppRoute>>[
                  dataRoute<ShellDataRoute, String>(
                    path: '/shell-feed',
                    parse: (_) => const ShellDataRoute(),
                    loader: (_) => 'shell:feed',
                    builder: (_, _, data) => Text(data),
                  ),
                ],
              ),
            ],
            builder: (_, _, child) => child,
          ),
        ],
      );

      final result = await router.resolve(
        Uri(path: '/shell-feed'),
        signal: const RouteNeverCancelledSignal(),
      );

      expect(result.isMatched, isTrue);
      expect(result.loaderData, 'shell:feed');
    });

    test(
      'throws cancellation when signal becomes cancelled during loader',
      () async {
        final loaderGate = Completer<String>();
        final router = Unrouter<AppRoute>(
          history: MemoryHistory(),
          routes: [
            dataRoute<SlowRoute, String>(
              path: '/slow',
              parse: (_) => const SlowRoute(),
              loader: (context) async {
                final value = await loaderGate.future;
                context.signal.throwIfCancelled();
                return value;
              },
              builder: (_, _, data) => Text(data),
            ),
          ],
        );

        var cancelled = false;
        final signal = _MutableSignal(() => cancelled);

        final future = router.resolve(Uri(path: '/slow'), signal: signal);

        cancelled = true;
        loaderGate.complete('done');

        await expectLater(
          future,
          throwsA(isA<RouteExecutionCancelledException>()),
        );
      },
    );
  });
}

Unrouter<AppRoute> _buildBasicRouter() {
  return Unrouter<AppRoute>(
    history: MemoryHistory(),
    routes: [
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (_, _) => const SizedBox.shrink(),
      ),
      route<UserRoute>(
        path: '/users/:id',
        parse: (state) => UserRoute(
          id: state.params.$int('id'),
          tab: state.query.containsKey('tab')
              ? state.query.$enum('tab', UserTab.values)
              : UserTab.posts,
        ),
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );
}

class _MutableSignal implements RouteExecutionSignal {
  _MutableSignal(this._isCancelled);

  final bool Function() _isCancelled;

  @override
  bool get isCancelled => _isCancelled();

  @override
  void throwIfCancelled() {
    if (isCancelled) {
      throw const RouteExecutionCancelledException();
    }
  }
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
  const UserRoute({required this.id, required this.tab});

  final int id;
  final UserTab tab;

  @override
  Uri toUri() => Uri(path: '/users/$id', queryParameters: {'tab': tab.name});
}

final class LoginRoute extends AppRoute {
  const LoginRoute();

  @override
  Uri toUri() => Uri(path: '/login');
}

final class PrivateRoute extends AppRoute {
  const PrivateRoute();

  @override
  Uri toUri() => Uri(path: '/private');
}

final class AdminRoute extends AppRoute {
  const AdminRoute();

  @override
  Uri toUri() => Uri(path: '/admin');
}

final class ProfileRoute extends AppRoute {
  const ProfileRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/profiles/$id');
}

final class SlowRoute extends AppRoute {
  const SlowRoute();

  @override
  Uri toUri() => Uri(path: '/slow');
}

final class ShellDataRoute extends AppRoute {
  const ShellDataRoute();

  @override
  Uri toUri() => Uri(path: '/shell-feed');
}

enum UserTab { posts, likes }
