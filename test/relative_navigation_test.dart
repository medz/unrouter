import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  testWidgets('relative navigation appends to current path (flat routes)', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'users/:id', factory: () => const Text('User Detail')),
        Inlet(path: 'users/:id/edit', factory: () => const Text('Edit User')),
      ],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Start at home
    expect(find.text('Home'), findsOneWidget);

    // Absolute navigation to /users/123
    router.push('/users/123');
    await tester.pumpAndSettle();
    expect(find.text('User Detail'), findsOneWidget);

    // Relative navigation: 'edit' should resolve to /users/123/edit
    router.push('edit');
    await tester.pumpAndSettle();
    expect(find.text('Edit User'), findsOneWidget);

    // Verify the final path
    expect(router.history.location.uri.path, '/users/123/edit');
  });

  testWidgets('absolute navigation overrides current path', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'about', factory: () => const Text('About')),
        Inlet(path: 'users', factory: () => const Text('Users')),
      ],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Navigate to users
    router.push('/users');
    await tester.pumpAndSettle();
    expect(find.text('Users'), findsOneWidget);

    // Absolute navigation to /about
    router.push('/about');
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
    expect(router.history.location.uri.path, '/about');
  });

  testWidgets('relative navigation with query and fragment', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(path: 'users', factory: () => const Text('Users')),
        Inlet(path: 'users/:id', factory: () => const Text('User Detail')),
      ],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Navigate to /users
    router.push('/users');
    await tester.pumpAndSettle();

    // Relative navigation with query: '123?tab=profile#top'
    router.push('123?tab=profile#top');
    await tester.pumpAndSettle();

    final location = router.history.location;
    expect(location.uri.path, '/users/123');
    expect(location.uri.query, 'tab=profile');
    expect(location.uri.fragment, 'top');
  });
}
