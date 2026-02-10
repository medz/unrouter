import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter_example/main.dart';

void main() {
  testWidgets('dashboard product push returns typed quantity to shell cart', (
    tester,
  ) async {
    await tester.pumpWidget(AtelierExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-push-highlight')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-add-return')), findsOneWidget);

    await tester.tap(find.byKey(const Key('product-add-return')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('shell-cart-count')),
        matching: find.text('Cart 1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('guard redirects to login and continues to checkout', (
    tester,
  ) async {
    await tester.pumpWidget(AtelierExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-push-highlight')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-add-return')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shell-go-cart')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cart-go-checkout')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-sign-in-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-sign-in-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkout-title')), findsOneWidget);
  });

  testWidgets('login continue from checkout target routes to cart when empty', (
    tester,
  ) async {
    await tester.pumpWidget(AtelierExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shell-go-cart')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cart-go-checkout')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-sign-in-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-sign-in-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('No items yet. Add one from the catalog.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('checkout-title')), findsNothing);
  });

  testWidgets(
    'empty signed-in cart keeps user on cart after blocked checkout',
    (tester) async {
      await tester.pumpWidget(AtelierExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shell-auth-toggle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shell-go-cart')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cart-go-checkout')));
      await tester.pumpAndSettle();

      expect(
        find.text('No items yet. Add one from the catalog.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('checkout-title')), findsNothing);
    },
  );
}
