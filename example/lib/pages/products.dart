import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(name: 'products');

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigate.back(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This page uses Routes widget for widget-scoped routing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Routes(
              RouteIndex.fromRoutes(const [
                Inlet(factory: ProductsList.new),
                Inlet(path: ':id', factory: ProductDetail.new),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductsList extends StatelessWidget {
  const ProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'All Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildProductCard(context, '1', 'Laptop', '\$999', Icons.laptop),
        _buildProductCard(context, '2', 'Phone', '\$699', Icons.phone_android),
        _buildProductCard(context, '3', 'Tablet', '\$499', Icons.tablet),
        _buildProductCard(
          context,
          '4',
          'Headphones',
          '\$199',
          Icons.headphones,
        ),
        _buildProductCard(context, '5', 'Watch', '\$299', Icons.watch),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String id,
    String name,
    String price,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(price),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.navigate(path: '/products/$id'),
      ),
    );
  }
}

class ProductDetail extends StatelessWidget {
  const ProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final productId = state.params['id'] ?? 'unknown';

    final products = {
      '1': ('Laptop', '\$999', Icons.laptop),
      '2': ('Phone', '\$699', Icons.phone_android),
      '3': ('Tablet', '\$499', Icons.tablet),
      '4': ('Headphones', '\$199', Icons.headphones),
      '5': ('Watch', '\$299', Icons.watch),
    };

    final product = products[productId];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.purple,
              child: Icon(
                product?.$3 ?? Icons.shopping_cart,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product?.$1 ?? 'Unknown Product',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product?.$2 ?? '\$0',
              style: TextStyle(
                fontSize: 24,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text('Product ID: $productId'),
              backgroundColor: Colors.purple.shade50,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.navigate.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
