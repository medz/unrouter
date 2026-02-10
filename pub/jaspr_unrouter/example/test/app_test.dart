import 'package:test/test.dart';

import '../lib/main.dart' as demo;

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

    final result = await router.resolve(Uri(path: '/products/101'));

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
      ..addItem(101, qty: 2);
    final router = demo.createRouter(session: session);

    final result = await router.resolve(Uri(path: '/checkout'));

    expect(result.isMatched, isTrue);
    expect(result.loaderData, isA<demo.CheckoutSummary>());
    final summary = result.loaderData! as demo.CheckoutSummary;
    expect(summary.itemCount, 2);
  });

  test('action route adds item then redirects to next uri', () async {
    final session = demo.StoreSession()..reset();
    final router = demo.createRouter(session: session);

    final result = await router.resolve(
      Uri(
        path: '/action/addItem',
        queryParameters: <String, String>{
          'id': '101',
          'qty': '1',
          'next': '/cart',
        },
      ),
    );

    expect(result.isRedirect, isTrue);
    expect(result.redirectUri, Uri(path: '/cart'));
    expect(session.itemCount, 1);
  });

  test('sign-in action sends empty checkout to cart', () async {
    final session = demo.StoreSession()..reset();
    final router = demo.createRouter(session: session);

    final result = await router.resolve(
      Uri(
        path: '/action/signIn',
        queryParameters: <String, String>{'next': '/checkout'},
      ),
    );

    expect(result.isRedirect, isTrue);
    expect(result.redirectUri, Uri(path: '/cart'));
    expect(session.isSignedIn, isTrue);
  });
}
