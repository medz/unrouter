import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

import 'advanced/advanced_app.dart';
import 'quickstart/quickstart_app.dart';

import 'home/example_home_view.dart';

final Unrouter exampleRouter = createRouter(
  routes: [
    Inlet(path: '/', view: ExampleHomeView.new),
    ...quickstartRoutes,
    ...advancedRoutes,
  ],
);

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unrouter Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: createRouterConfig(exampleRouter),
    );
  }
}
