import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Hybrid routing - routes + child with complex scenarios', () {
    testWidgets('routes take precedence over child Routes widget', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [
          Inlet(factory: HomePage.new),
          Inlet(path: 'admin', factory: AdminPage.new),
        ],
        child: Routes(const [
          Inlet(path: 'admin', factory: DynamicAdminPage.new),
          Inlet(path: 'settings', factory: SettingsPage.new),
        ]),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /admin - should match static routes, not child Routes
      router.navigate(path: '/admin');
      await tester.pumpAndSettle();

      expect(find.text('Static Admin'), findsOneWidget);
      expect(find.text('Dynamic Admin'), findsNothing);

      // Navigate to /settings - not in routes, should fall back to child Routes
      router.navigate(path: '/settings');
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('child with nested widget containing Routes widget', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [
          Inlet(factory: HomePage.new),
          Inlet(path: 'static', factory: StaticPage.new),
        ],
        // Child is not directly Routes, but contains Routes internally
        child: const WrapperWidget(),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to / - should match static routes
      expect(find.text('Home'), findsOneWidget);

      // Navigate to /static
      router.navigate(path: '/static');
      await tester.pumpAndSettle();

      expect(find.text('Static Page'), findsOneWidget);

      // Navigate to /dynamic - not in static routes, should fall back to WrapperWidget
      // which internally uses Routes widget
      router.navigate(path: '/dynamic');
      await tester.pumpAndSettle();

      expect(find.text('Wrapper'), findsOneWidget);
      expect(find.text('Dynamic Page'), findsOneWidget);
    });

    testWidgets(
      'static route partial match with child Routes as fallback for different paths',
      (tester) async {
        late Unrouter router;

        router = Unrouter(
          history: MemoryHistory(),
          routes: const [
            Inlet(path: 'products', factory: ProductsPageWithRoutes.new),
          ],
          child: Routes(const [
            Inlet(path: 'users/:id', factory: UserDetailPage.new),
            Inlet(path: 'posts/:id', factory: PostDetailPage.new),
          ]),
        );

        await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: router),
        );

        // Navigate to /products/123 - partial match on static route
        router.navigate(path: '/products/123');
        await tester.pumpAndSettle();

        expect(find.text('Products Container'), findsOneWidget);
        expect(find.text('Product: 123'), findsOneWidget);

        // Navigate to /users/456 - no match in static routes, use child Routes
        router.navigate(path: '/users/456');
        await tester.pumpAndSettle();

        expect(find.text('User: 456'), findsOneWidget);

        // Navigate to /posts/789 - no match in static routes, use child Routes
        router.navigate(path: '/posts/789');
        await tester.pumpAndSettle();

        expect(find.text('Post: 789'), findsOneWidget);
      },
    );

    testWidgets('overlapping routes in static and child - static wins', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [Inlet(path: 'items/:id', factory: StaticItemPage.new)],
        child: Routes(const [
          Inlet(path: 'items/:id', factory: DynamicItemPage.new),
          Inlet(path: 'categories/:name', factory: CategoryPage.new),
        ]),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /items/123 - both routes match, static should win
      router.navigate(path: '/items/123');
      await tester.pumpAndSettle();

      expect(find.text('Static Item: 123'), findsOneWidget);
      expect(find.text('Dynamic Item'), findsNothing);

      // Navigate to /categories/electronics - only in child Routes
      router.navigate(path: '/categories/electronics');
      await tester.pumpAndSettle();

      expect(find.text('Category: electronics'), findsOneWidget);
    });

    testWidgets(
      'static partial match route with Routes + child Routes fallback',
      (tester) async {
        late Unrouter router;

        router = Unrouter(
          history: MemoryHistory(),
          routes: const [Inlet(path: 'shop', factory: ShopPageWithRoutes.new)],
          child: Routes(const [
            Inlet(path: 'account/:section', factory: AccountPage.new),
          ]),
        );

        await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: router),
        );

        // Navigate to /shop/products/123
        // Static route partially matches 'shop', ShopPageWithRoutes handles rest
        router.navigate(path: '/shop/products/123');
        await tester.pumpAndSettle();

        expect(find.text('Shop Container'), findsOneWidget);
        expect(find.text('Shop Product: 123'), findsOneWidget);

        // Navigate to /shop/categories/toys
        router.navigate(path: '/shop/categories/toys');
        await tester.pumpAndSettle();

        expect(find.text('Shop Container'), findsOneWidget);
        expect(find.text('Shop Category: toys'), findsOneWidget);

        // Navigate to /account/profile - no match in static, use child Routes
        router.navigate(path: '/account/profile');
        await tester.pumpAndSettle();

        expect(find.text('Account: profile'), findsOneWidget);
        expect(find.text('Shop Container'), findsNothing);
      },
    );

    testWidgets('deeply nested child widget with Routes - multiple levels', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [Inlet(factory: HomePage.new)],
        child: const DeepWrapper(),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to / - matches static route
      expect(find.text('Home'), findsOneWidget);

      // Navigate to /deep - should work through deeply nested Routes widget
      router.navigate(path: '/deep');
      await tester.pumpAndSettle();

      expect(find.text('Deep Wrapper Level 1'), findsOneWidget);
      expect(find.text('Deep Wrapper Level 2'), findsOneWidget);
      expect(find.text('Deep Page'), findsOneWidget);
    });

    testWidgets('static route with no match falls back to complex child widget', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [Inlet(path: 'exact', factory: ExactPage.new)],
        child: const ComplexFallback(),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /exact - matches static route
      router.navigate(path: '/exact');
      await tester.pumpAndSettle();

      expect(find.text('Exact Page'), findsOneWidget);

      // Navigate to /fallback/nested/path - no static match, uses ComplexFallback
      router.navigate(path: '/fallback/nested/path');
      await tester.pumpAndSettle();

      expect(find.text('Complex Fallback'), findsOneWidget);
      expect(find.text('Nested: nested/path'), findsOneWidget);
    });
  });
}

// Test widgets

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Static Admin');
}

class DynamicAdminPage extends StatelessWidget {
  const DynamicAdminPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Dynamic Admin');
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Settings');
}

class StaticPage extends StatelessWidget {
  const StaticPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Static Page');
}

// Wrapper widget that internally uses Routes (not directly Routes)
class WrapperWidget extends StatelessWidget {
  const WrapperWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Wrapper'),
        Routes(const [
          Inlet(path: 'dynamic', factory: DynamicPage.new),
          Inlet(path: 'other', factory: OtherPage.new),
        ]),
      ],
    );
  }
}

class DynamicPage extends StatelessWidget {
  const DynamicPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Dynamic Page');
}

class OtherPage extends StatelessWidget {
  const OtherPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Other Page');
}

class ProductsPageWithRoutes extends StatelessWidget {
  const ProductsPageWithRoutes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Products Container'),
        Routes(const [Inlet(path: ':id', factory: ProductDetailInner.new)]),
      ],
    );
  }
}

class ProductDetailInner extends StatelessWidget {
  const ProductDetailInner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final id = state.params['id'] ?? 'unknown';
    return Text('Product: $id');
  }
}

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final id = state.params['id'] ?? 'unknown';
    return Text('User: $id');
  }
}

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final id = state.params['id'] ?? 'unknown';
    return Text('Post: $id');
  }
}

class StaticItemPage extends StatelessWidget {
  const StaticItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final id = state.params['id'] ?? 'unknown';
    return Text('Static Item: $id');
  }
}

class DynamicItemPage extends StatelessWidget {
  const DynamicItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final id = state.params['id'] ?? 'unknown';
    return Text('Dynamic Item: $id');
  }
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final name = state.params['name'] ?? 'unknown';
    return Text('Category: $name');
  }
}

class ShopPageWithRoutes extends StatelessWidget {
  const ShopPageWithRoutes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Shop Container'),
        Routes(const [
          Inlet(path: 'products/:id', factory: ShopProductPage.new),
          Inlet(path: 'categories/:name', factory: ShopCategoryPage.new),
        ]),
      ],
    );
  }
}

class ShopProductPage extends StatelessWidget {
  const ShopProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final id = state.params['id'] ?? 'unknown';
    return Text('Shop Product: $id');
  }
}

class ShopCategoryPage extends StatelessWidget {
  const ShopCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final name = state.params['name'] ?? 'unknown';
    return Text('Shop Category: $name');
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final section = state.params['section'] ?? 'unknown';
    return Text('Account: $section');
  }
}

// Deeply nested wrapper
class DeepWrapper extends StatelessWidget {
  const DeepWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [const Text('Deep Wrapper Level 1'), const DeepWrapperLevel2()],
    );
  }
}

class DeepWrapperLevel2 extends StatelessWidget {
  const DeepWrapperLevel2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Deep Wrapper Level 2'),
        Routes(const [Inlet(path: 'deep', factory: DeepPage.new)]),
      ],
    );
  }
}

class DeepPage extends StatelessWidget {
  const DeepPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Deep Page');
}

class ExactPage extends StatelessWidget {
  const ExactPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Exact Page');
}

class ComplexFallback extends StatelessWidget {
  const ComplexFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Complex Fallback'),
        Routes(const [
          Inlet(path: 'fallback/*', factory: NestedFallbackPage.new),
        ]),
      ],
    );
  }
}

class NestedFallbackPage extends StatelessWidget {
  const NestedFallbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    // Get the remaining path after 'fallback/'
    final location = state.location.uri.path;
    final remaining = location.replaceFirst(RegExp(r'^/fallback/'), '');
    return Text('Nested: $remaining');
  }
}
