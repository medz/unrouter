import 'package:flutter/material.dart' hide Route;
import 'package:unrouter/unrouter.dart';

final routes = <Route>[
  .new(
    path: '/',
    builder: (context) => const RootLayout(),
    children: [
      .new(path: '', builder: (_) => const Home(), name: 'home'),
      .new(path: 'about', builder: (_) => const About(), name: 'about'),
      .new(path: 'users/:id', builder: (_) => const Profile(), name: 'profile'),
    ],
  ),
  .new(path: '**', builder: (_) => const NotFound()),
];

final router = createRouter(routes: routes);

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unrouter Example',
      routerDelegate: router.delegate,
      routeInformationParser: router.informationParser,
      theme: ThemeData.light(),
    );
  }
}

class RootLayout extends StatelessWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unrouter Example')),
      body: const Padding(padding: EdgeInsets.all(16), child: RouterView()),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Home', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () =>
              router.push(const .name('about', query: {'tab': 'info'})),
          child: const Text('Go about'),
        ),
        ElevatedButton(
          onPressed: () =>
              router.push(const .name('profile', params: {'id': '42'})),
          child: const Text('Go profile 42'),
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
    final tab = query['tab'] ?? 'none';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text('query tab=$tab'),
      ],
    );
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final params = useRouterParams(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text('userId=${params['id']}'),
      ],
    );
  }
}

class NotFound extends StatelessWidget {
  const NotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('404 - Page not found'));
  }
}
