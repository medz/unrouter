import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

import 'advanced_views.dart';
import 'data_loader_demo.dart';

final Guard _authGuard = defineGuard((context) {
  if (context.to.path == '/signin') {
    return const GuardResult.allow();
  }

  if (context.query.get('auth') == '1') {
    return const GuardResult.allow();
  }

  return GuardResult.redirect(
    '/signin',
    query: URLSearchParams({'from': context.to.path}),
  );
});

final Guard _reportsGuard = defineGuard((context) {
  if (context.query.get('blocked') == '1') {
    return const GuardResult.block();
  }
  return const GuardResult.allow();
});

final Guard _adminGuard = defineGuard((context) {
  if (context.query.get('role') == 'admin') {
    return const GuardResult.allow();
  }
  return GuardResult.redirect(
    'reports',
    query: URLSearchParams('auth=1&from=admin'),
  );
});

final Unrouter advancedRouter = createRouter(
  guards: [_authGuard],
  routes: [
    Inlet(name: 'signin', path: '/signin', view: AdvancedSignInView.new),
    Inlet(
      path: '/app',
      view: AdvancedRootLayoutView.new,
      children: [
        Inlet(name: 'dashboard', path: '', view: AdvancedDashboardView.new),
        Inlet(
          name: 'reports',
          path: 'reports',
          view: AdvancedReportsView.new,
          guards: [_reportsGuard],
        ),
        Inlet(
          name: 'admin',
          path: 'admin',
          view: AdvancedAdminView.new,
          guards: [_adminGuard],
        ),
        Inlet(
          path: 'profile',
          view: AdvancedProfileLayoutView.new,
          children: [
            Inlet(
              name: 'profileDetail',
              path: ':id',
              view: AdvancedProfileDetailView.new,
            ),
          ],
        ),
        Inlet(name: 'search', path: 'search', view: AdvancedSearchView.new),
        Inlet(name: 'loader', path: 'loader', view: DataLoaderDemoView.new),
      ],
    ),
  ],
);

class AdvancedApp extends StatelessWidget {
  const AdvancedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unrouter Advanced',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: createRouterConfig(advancedRouter),
    );
  }
}
