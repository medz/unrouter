import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  testWidgets('nested routes with relative navigation', (tester) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(
          path: 'users',
          factory: () => const UsersLayout(),
          children: [
            Inlet(path: ':id', factory: () => const UserDetail()),
            Inlet(path: ':id/edit', factory: () => const EditUser()),
          ],
        ),
      ],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Start at home
    expect(find.text('Home'), findsOneWidget);

    // Absolute navigation to /users/123
    router.navigate(.parse('/users/123'));
    await tester.pumpAndSettle();

    // Should see both layout and child
    expect(find.text('Users Layout'), findsOneWidget);
    expect(find.text('User Detail: 123'), findsOneWidget);

    // Relative navigation: 'edit' should resolve to /users/123/edit
    router.navigate(.parse('edit'));
    await tester.pumpAndSettle();

    expect(find.text('Users Layout'), findsOneWidget);
    expect(find.text('Edit User: 123'), findsOneWidget);

    // Verify the final path
    expect(router.history.location.uri.path, '/users/123/edit');
  });
}

class UsersLayout extends StatelessWidget {
  const UsersLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Users Layout'),
        Expanded(child: Outlet()),
      ],
    );
  }
}

class UserDetail extends StatelessWidget {
  const UserDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final userId = state.params['id'] ?? '';
    return Text('User Detail: $userId');
  }
}

class EditUser extends StatelessWidget {
  const EditUser({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final userId = state.params['id'] ?? '';
    return Text('Edit User: $userId');
  }
}
