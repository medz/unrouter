Unrouter is a tiny wrapper on **zenrouter**:

- Describe routes with path + builder + children
- `RouterView` renders nested routes
- Navigate by path or name: `router.push(.path('/path'))` / `router.push(.name('foo'))`
- Utils: `useRouter`, `useRoute`, `useRouterParams`, `useQueryParams`

## Install

```yaml
dependencies:
  unrouter: any
```

## Usage

```dart
import 'package:flutter/material.dart' hide Route;
import 'package:unrouter/unrouter.dart';

final router = createRouter(routes: [
  .new(
    path: '/',
    builder: (_) => const RootLayout(),
    children: [
      .new(path: '', builder: (_) => const Home(), name: 'home'),
      .new(path: 'about', builder: (_) => const About(), name: 'about'),
      .new(
        path: 'users/:id',
        builder: (_) => const Profile(),
        name: 'profile',
      ),
    ],
  ),
  .new(path: '**', builder: (_) => const NotFound()),
]);

void main() {
  runApp(
    MaterialApp.router(
      routerDelegate: router.delegate,
      routeInformationParser: router.informationParser,
    ),
  );
}

class RootLayout extends StatelessWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unrouter demo')),
      body: const RouterView(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    return Column(
      children: [
        const Text('Home'),
        ElevatedButton(
          onPressed: () =>
              router.push(const .name('about', query: {'tab': 'info'})),
          child: const Text('Go About'),
        ),
        ElevatedButton(
          onPressed: () =>
              router.push(const .name('profile', params: {'id': '42'})),
          child: const Text('Go Profile 42'),
        ),
      ],
    );
  }
}

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useQueryParams(context);
    return Text('About page, tab=${query['tab']}');
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final params = useRouterParams(context);
    return Text('Profile id=${params['id']}');
  }
}

class NotFound extends StatelessWidget {
  const NotFound({super.key});

  @override
  Widget build(BuildContext context) => const Text('404');
}
```

See `example/` for a runnable app:

```sh
flutter run -d chrome example/lib/main.dart
```
