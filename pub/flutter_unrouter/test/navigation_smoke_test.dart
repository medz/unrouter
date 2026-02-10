import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  testWidgets('controller push/pop returns typed result', (tester) async {
    final resultValue = ValueNotifier<int?>(null);
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Scaffold(
              body: Column(
                children: <Widget>[
                  FilledButton(
                    key: const Key('go-user'),
                    onPressed: () async {
                      final value = await context.unrouter.push<int>(
                        const UserRoute(id: 7),
                      );
                      resultValue.value = value;
                    },
                    child: const Text('go'),
                  ),
                  ValueListenableBuilder<int?>(
                    valueListenable: resultValue,
                    builder: (_, value, _) {
                      return Text('result:${value ?? '-'}');
                    },
                  ),
                ],
              ),
            );
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.params.$int('id')),
          builder: (context, route) {
            return Scaffold(
              body: FilledButton(
                key: const Key('pop-user'),
                onPressed: () => context.unrouter.pop(route.id * 10),
                child: const Text('pop'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-user')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pop-user')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pop-user')));
    await tester.pumpAndSettle();
    expect(find.text('result:70'), findsOneWidget);
  });

  testWidgets('route guard redirect works in widget runtime', (tester) async {
    var signedIn = false;
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: <RouteRecord<AppRoute>>[
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Scaffold(
              body: FilledButton(
                key: const Key('go-secure'),
                onPressed: () => context.unrouter.goUri(Uri(path: '/secure')),
                child: const Text('secure'),
              ),
            );
          },
        ),
        route<LoginRoute>(
          path: '/login',
          parse: (_) => const LoginRoute(),
          builder: (_, _) => const Scaffold(body: Text('login-page')),
        ),
        route<SecureRoute>(
          path: '/secure',
          parse: (_) => const SecureRoute(),
          guards: <RouteGuard<SecureRoute>>[
            (_) => signedIn
                ? RouteGuardResult.allow()
                : RouteGuardResult.redirect(uri: Uri(path: '/login')),
          ],
          builder: (_, _) => const Scaffold(body: Text('secure-page')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-secure')));
    await tester.pumpAndSettle();
    expect(find.text('login-page'), findsOneWidget);

    signedIn = true;
    router.routeInformationProvider.replace(Uri(path: '/'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-secure')));
    await tester.pumpAndSettle();
    expect(find.text('secure-page'), findsOneWidget);
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

final class LoginRoute extends AppRoute {
  const LoginRoute();

  @override
  Uri toUri() => Uri(path: '/login');
}

final class SecureRoute extends AppRoute {
  const SecureRoute();

  @override
  Uri toUri() => Uri(path: '/secure');
}
