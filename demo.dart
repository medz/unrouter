import 'package:flutter/material.dart' hide Route;
import 'package:unrouter/unrouter.dart';

final router = Unrouter([
  Route.index(PlaceholderPage.new),
  Route.path('about', PlaceholderPage.new),
  Route.layout(Auth.new, [
    Route.path('login', PlaceholderPage.new),
    Route.path('register', PlaceholderPage.new),
  ]),
  Route.nested('concerts', Concerts.new, [
    Route.index(PlaceholderPage.new),
    Route.path(':city', PlaceholderPage.new),
    Route.path('trending', PlaceholderPage.new),
  ]),
], mode: HistoryMode.memory);

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Placeholder'));
  }
}

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth')),
      body: const RouterView(),
    );
  }
}

class Concerts extends StatelessWidget {
  const Concerts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Concerts')),
      body: const RouterView(),
    );
  }
}
