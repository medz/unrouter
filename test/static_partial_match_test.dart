import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Declarative routes require full matches', () {
    testWidgets('declarative route does not match extra segments', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: RouteIndex.fromRoutes(const [
          Inlet(factory: HomePage.new),
          // Declarative route that must fully match
          Inlet(path: 'products', factory: ProductsPage.new),
        ]),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /products (should match and render ProductsPage)
      router.navigate(path: '/products');
      await tester.pumpAndSettle();

      expect(find.text('Products Page'), findsOneWidget);
      expect(find.text('Product List'), findsOneWidget);

      // Navigate to /products/123 (no partial match)
      router.navigate(path: '/products/123');
      await tester.pumpAndSettle();

      expect(find.text('Products Page'), findsNothing);
      expect(find.text('Product Detail: 123'), findsNothing);
    });

    testWidgets('extra segments do not render nested Routes', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: RouteIndex.fromRoutes(const [
          // Declarative route without children - no partial match
          Inlet(path: 'shop', factory: ShopPage.new),
        ]),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /shop
      router.navigate(path: '/shop');
      await tester.pumpAndSettle();

      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Category: electronics'), findsNothing);

      // Navigate to /shop/category/electronics (no partial match)
      router.navigate(path: '/shop/category/electronics');
      await tester.pumpAndSettle();

      expect(find.text('Shop'), findsNothing);
      expect(find.text('Category: electronics'), findsNothing);
    });

    testWidgets('full match takes precedence when multiple routes match', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: RouteIndex.fromRoutes(const [
          Inlet(path: 'products', factory: ProductsPage.new),
          Inlet(path: 'products/special', factory: SpecialProductsPage.new),
        ]),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /products/special (should fully match second route)
      router.navigate(path: '/products/special');
      await tester.pumpAndSettle();

      expect(find.text('Special Products'), findsOneWidget);
      expect(find.text('Products Page'), findsNothing);
    });
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Home');
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Products Page'),
        Routes(
          RouteIndex.fromRoutes(const [
            Inlet(factory: ProductList.new),
            Inlet(path: ':id', factory: ProductDetail.new),
          ]),
        ),
      ],
    );
  }
}

class ProductList extends StatelessWidget {
  const ProductList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Product List');
  }
}

class ProductDetail extends StatelessWidget {
  const ProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final id = state.params['id'] ?? 'unknown';
    return Text('Product Detail: $id');
  }
}

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Shop'),
        Routes(RouteIndex.fromRoutes(const [
          Inlet(path: 'category/:name', factory: CategoryPage.new),
        ])),
      ],
    );
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

class SpecialProductsPage extends StatelessWidget {
  const SpecialProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Special Products');
  }
}
