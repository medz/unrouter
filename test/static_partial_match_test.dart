import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Declarative routes with partial matching for nested Routes widget', () {
    testWidgets('declarative route with Routes widget matches nested paths', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [
          Inlet(factory: HomePage.new),
          // Declarative route that will be partially matched
          Inlet(path: 'products', factory: ProductsPage.new),
        ],
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /products (should match and render ProductsPage)
      router.navigate(.parse('/products'));
      await tester.pumpAndSettle();

      expect(find.text('Products Page'), findsOneWidget);
      expect(find.text('Product List'), findsOneWidget);

      // Navigate to /products/123 (should partially match products route,
      // then ProductsPage's Routes widget should match :id)
      router.navigate(.parse('/products/123'));
      await tester.pumpAndSettle();

      expect(find.text('Products Page'), findsOneWidget);
      expect(find.text('Product Detail: 123'), findsOneWidget);
    });

    testWidgets('partial match allows component to handle remaining segments', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [
          // Declarative route without children - should still partially match
          Inlet(path: 'shop', factory: ShopPage.new),
        ],
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /shop/category/electronics
      router.navigate(.parse('/shop/category/electronics'));
      await tester.pumpAndSettle();

      // ShopPage should render and its internal Routes should match remaining path
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Category: electronics'), findsOneWidget);
    });

    testWidgets('full match takes precedence over partial match', (
      tester,
    ) async {
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [
          Inlet(path: 'products', factory: ProductsPage.new),
          Inlet(path: 'products/special', factory: SpecialProductsPage.new),
        ],
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate to /products/special (should fully match second route)
      router.navigate(.parse('/products/special'));
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
        Routes(const [
          Inlet(factory: ProductList.new),
          Inlet(path: ':id', factory: ProductDetail.new),
        ]),
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
    final state = context.routerState;
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
        Routes(const [
          Inlet(path: 'category/:name', factory: CategoryPage.new),
        ]),
      ],
    );
  }
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routerState;
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
