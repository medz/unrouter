import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

import 'routes.dart';

void main() {
  runApp(const App());
}

final router = Unrouter(
  strategy: .browser,
  enableNavigator1: true,
  routes: routes,
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unrouter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
