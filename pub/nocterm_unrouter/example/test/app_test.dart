import 'package:test/test.dart';

import '../bin/main.dart' as demo;

void main() {
  test('root route redirects to discover', () async {
    final session = demo.StoreSession()..reset();
    final router = demo.createRouter(session: session);

    final result = await router.resolve(Uri(path: '/'));

    expect(result.isRedirect, isTrue);
    expect(result.redirectUri, Uri(path: '/discover'));
  });

  test('catalog query decodes typed tab', () async {
    final session = demo.StoreSession()..reset();
    final router = demo.createRouter(session: session);

    final result = await router.resolve(
      Uri(path: '/catalog', queryParameters: <String, String>{'tab': 'studio'}),
    );

    expect(result.isMatched, isTrue);
    expect(result.route, isA<demo.CatalogRoute>());
    final route = result.route! as demo.CatalogRoute;
    expect(route.tab, demo.CatalogTab.studio);
  });

  test('product data route resolves loader data', () async {
    final session = demo.StoreSession()..reset();
    final router = demo.createRouter(session: session);

    final result = await router.resolve(Uri(path: '/products/201'));

    expect(result.isMatched, isTrue);
    expect(result.route, isA<demo.ProductRoute>());
    expect(result.loaderData, isA<demo.ProductDetails>());
  });

  test('checkout redirects to login when signed out', () async {
    final session = demo.StoreSession()..reset();
    final router = demo.createRouter(session: session);

    final result = await router.resolve(Uri(path: '/checkout'));

    expect(result.isRedirect, isTrue);
    expect(result.redirectUri?.path, '/login');
  });

  test('checkout blocks when signed in but cart is empty', () async {
    final session = demo.StoreSession()
      ..reset()
      ..signIn();
    final router = demo.createRouter(session: session);

    final result = await router.resolve(Uri(path: '/checkout'));

    expect(result.isBlocked, isTrue);
  });

  test('checkout matches when signed in with cart items', () async {
    final session = demo.StoreSession()
      ..reset()
      ..signIn()
      ..addItem(201, qty: 2);
    final router = demo.createRouter(session: session);

    final result = await router.resolve(Uri(path: '/checkout'));

    expect(result.isMatched, isTrue);
    expect(result.loaderData, isA<demo.CheckoutSummary>());
    final summary = result.loaderData! as demo.CheckoutSummary;
    expect(summary.itemCount, 2);
  });
}
