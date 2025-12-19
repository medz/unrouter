import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Navigation after page refresh', () {
    testWidgets(
      'back navigation works correctly after refresh (declarative routes)',
      (tester) async {
        // Simulate: / -> /products -> /products/1 -> refresh -> back
        late Unrouter router;

        router = Unrouter(
          history: MemoryHistory(),
          routes: const [
            Inlet(factory: HomePage.new),
            Inlet(path: 'products', factory: ProductsPageWithRoutes.new),
          ],
        );

        await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: router),
        );

        // Navigate: / -> /products -> /products/1
        expect(find.text('Home'), findsOneWidget);

        router.navigate(.parse('/products'));
        await tester.pumpAndSettle();
        expect(find.text('Products Container'), findsOneWidget);
        expect(find.text('Product List'), findsOneWidget);

        router.navigate(.parse('/products/1'));
        await tester.pumpAndSettle();
        expect(find.text('Product: 1'), findsOneWidget);

        // Simulate page refresh by creating a new router with full history stack
        // In a real browser, the history stack is preserved after refresh
        router = Unrouter(
          history: MemoryHistory(
            initialEntries: [
              RouteInformation(uri: Uri.parse('/')),
              RouteInformation(uri: Uri.parse('/products')),
              RouteInformation(uri: Uri.parse('/products/1')),
            ],
            initialIndex: 2, // Currently at /products/1
          ),
          routes: const [
            Inlet(factory: HomePage.new),
            Inlet(path: 'products', factory: ProductsPageWithRoutes.new),
          ],
        );

        await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: router),
        );
        await tester.pumpAndSettle();

        // Should still show product detail
        expect(find.text('Product: 1'), findsOneWidget);

        // Now back should go to /products
        router.navigate.back();
        await tester.pumpAndSettle();

        expect(find.text('Products Container'), findsOneWidget);
        expect(find.text('Product List'), findsOneWidget);
        expect(find.text('Product: 1'), findsNothing);

        // Another back should go to /
        router.navigate.back();
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Products Container'), findsNothing);
      },
    );

    testWidgets('back navigation after refresh (nested declarative routes)', (
      tester,
    ) async {
      // Simulate: / -> /login -> /register -> refresh -> back
      late Unrouter router;

      router = Unrouter(
        history: MemoryHistory(),
        routes: const [
          Inlet(factory: HomePage.new),
          Inlet(
            factory: AuthLayout.new,
            children: [
              Inlet(path: 'login', factory: LoginPage.new),
              Inlet(path: 'register', factory: RegisterPage.new),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );

      // Navigate: / -> /login -> /register
      expect(find.text('Home'), findsOneWidget);

      router.navigate(.parse('/login'));
      await tester.pumpAndSettle();
      expect(find.text('Auth Layout'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      router.navigate(.parse('/register'));
      await tester.pumpAndSettle();
      expect(find.text('Auth Layout'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // Simulate page refresh with full history stack
      router = Unrouter(
        history: MemoryHistory(
          initialEntries: [
            RouteInformation(uri: Uri.parse('/')),
            RouteInformation(uri: Uri.parse('/login')),
            RouteInformation(uri: Uri.parse('/register')),
          ],
          initialIndex: 2, // Currently at /register
        ),
        routes: const [
          Inlet(factory: HomePage.new),
          Inlet(
            factory: AuthLayout.new,
            children: [
              Inlet(path: 'login', factory: LoginPage.new),
              Inlet(path: 'register', factory: RegisterPage.new),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: router),
      );
      await tester.pumpAndSettle();

      // Should still show register page
      expect(find.text('Register'), findsOneWidget);

      // Back should go to /login
      router.navigate.back();
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsNothing);

      // Another back should go to /
      router.navigate.back();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Auth Layout'), findsNothing);
    });
  });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Home');
}

class ProductsPageWithRoutes extends StatelessWidget {
  const ProductsPageWithRoutes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Products Container'),
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
  Widget build(BuildContext context) => const Text('Product List');
}

class ProductDetail extends StatelessWidget {
  const ProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = RouterStateProvider.of(context);
    final id = state.params['id'] ?? '0';
    return Text('Product: $id');
  }
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [const Text('Auth Layout'), const Outlet()]);
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Login');
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('Register');
}
