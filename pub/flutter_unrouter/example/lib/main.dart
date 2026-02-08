import 'package:flutter/material.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';

void main() {
  runApp(UnrouterExampleApp());
}

final DemoSession _session = DemoSession();
final ValueNotifier<int?> _lastUserResult = ValueNotifier<int?>(null);

Unrouter<AppRoute> _createRouter() {
  return Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<HomeRoute>(
        path: '/',
        parse: (_) => const HomeRoute(),
        builder: (_, _) => const HomeScreen(),
      ),
      route<UserRoute>(
        path: '/users/:id',
        parse: (state) => UserRoute(id: state.params.$int('id')),
        builder: (_, route) => UserScreen(route: route),
      ),
      route<SettingsRoute>(
        path: '/settings',
        parse: (_) => const SettingsRoute(),
        builder: (_, _) => const SettingsScreen(),
      ),
      route<LoginRoute>(
        path: '/login',
        parse: (state) => LoginRoute(from: state.query['from']),
        builder: (_, route) => LoginScreen(route: route),
      ),
      route<SecureRoute>(
        path: '/secure',
        parse: (_) => const SecureRoute(),
        guards: <RouteGuard<SecureRoute>>[
          (context) {
            if (_session.isSignedIn) {
              return RouteGuardResult.allow();
            }
            return RouteGuardResult.redirect(
              LoginRoute(from: context.uri.toString()).toUri(),
            );
          },
        ],
        builder: (_, _) => const SecureScreen(),
      ),
    ],
    unknown: (_, uri) => UnknownRouteScreen(uri: uri),
  );
}

class UnrouterExampleApp extends StatelessWidget {
  UnrouterExampleApp({super.key}) : _router = _createRouter() {
    _session.signOut();
    _lastUserResult.value = null;
  }

  final Unrouter<AppRoute> _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'unrouter example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1363DF)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
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
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  @override
  Uri toUri() => Uri(path: '/settings');
}

final class LoginRoute extends AppRoute {
  const LoginRoute({this.from});

  final String? from;

  @override
  Uri toUri() {
    return Uri(
      path: '/login',
      queryParameters: from == null ? null : <String, String>{'from': from!},
    );
  }
}

final class SecureRoute extends AppRoute {
  const SecureRoute();

  @override
  Uri toUri() => Uri(path: '/secure');
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    final state = controller.state;

    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('unrouter example'),
            actions: <Widget>[
              TextButton(
                key: const Key('app-auth-toggle'),
                onPressed: _session.toggle,
                child: Text(_session.isSignedIn ? 'Sign out' : 'Sign in'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'state: ${state.resolution.name} ${state.routePath ?? '-'}',
                  key: const Key('home-state-line'),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<int?>(
                  valueListenable: _lastUserResult,
                  builder: (context, value, _) {
                    return Text('lastUserResult: ${value ?? '-'}');
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('home-go-user'),
                  onPressed: () async {
                    final value = await controller.push<int>(
                      const UserRoute(id: 42),
                    );
                    _lastUserResult.value = value;
                  },
                  child: const Text('Push /users/42'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  key: const Key('home-go-settings'),
                  onPressed: () {
                    controller.go(const SettingsRoute());
                  },
                  child: const Text('Go /settings'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  key: const Key('home-go-secure'),
                  onPressed: () {
                    controller.go(const SecureRoute());
                  },
                  child: const Text('Go /secure (guarded)'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('home-back'),
                  onPressed: () {
                    controller.back();
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UserScreen extends StatelessWidget {
  const UserScreen({super.key, required this.route});

  final UserRoute route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('User ${route.id}'),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('user-pop-result'),
              onPressed: () {
                context.unrouter.pop(route.id * 10);
              },
              child: const Text('Pop with typed result'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: FilledButton(
          key: const Key('settings-back'),
          onPressed: () {
            context.unrouter.back();
          },
          child: const Text('Back'),
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.route});

  final LoginRoute route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Sign in required'),
            const SizedBox(height: 8),
            Text('from: ${route.from ?? '/'}'),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('login-sign-in-continue'),
              onPressed: () {
                _session.signIn();
                final target = Uri.tryParse(route.from ?? '');
                if (target == null) {
                  context.unrouter.go(const HomeRoute());
                  return;
                }
                context.unrouter.goUri(target);
              },
              child: const Text('Sign in and continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecureScreen extends StatelessWidget {
  const SecureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure')),
      body: const Center(child: Text('Secure area', key: Key('secure-title'))),
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Unknown route: ${uri.path}')));
  }
}

class DemoSession extends ChangeNotifier {
  bool _isSignedIn = false;

  bool get isSignedIn => _isSignedIn;

  void signIn() {
    _isSignedIn = true;
    notifyListeners();
  }

  void signOut() {
    _isSignedIn = false;
    notifyListeners();
  }

  void toggle() {
    if (_isSignedIn) {
      signOut();
      return;
    }
    signIn();
  }
}
