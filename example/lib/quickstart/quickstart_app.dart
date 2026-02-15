import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

import 'quickstart_views.dart';

final Unrouter quickstartRouter = createRouter(
  routes: [
    Inlet(
      path: '/',
      view: QuickstartLayoutView.new,
      children: [
        Inlet(name: 'home', path: '', view: QuickstartHomeView.new),
        Inlet(name: 'about', path: 'about', view: QuickstartAboutView.new),
        Inlet(
          name: 'profile',
          path: 'profile/:id',
          view: QuickstartProfileView.new,
        ),
      ],
    ),
  ],
);

class QuickstartApp extends StatelessWidget {
  const QuickstartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unrouter Quickstart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: createRouterConfig(quickstartRouter),
    );
  }
}
