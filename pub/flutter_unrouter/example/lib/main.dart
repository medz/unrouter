import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(AtelierExampleApp());
}

final StoreSession _session = StoreSession();
final ValueNotifier<String> _eventFeed = ValueNotifier<String>('Ready');

Unrouter<AppRoute> _createRouter() {
  return Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      ...shell<AppRoute>(
        branches: <ShellBranch<AppRoute>>[
          branch<AppRoute>(
            initialLocation: Uri(path: '/'),
            routes: <RouteRecord<AppRoute>>[
              route<DashboardRoute>(
                path: '/',
                parse: (_) => const DashboardRoute(),
                builder: (_, _) => const DashboardScreen(),
              ),
              route<CatalogRoute>(
                path: '/catalog',
                parse: (state) {
                  final tab = state.query.containsKey('tab')
                      ? state.query.$enum('tab', CatalogTab.values)
                      : CatalogTab.featured;
                  return CatalogRoute(tab: tab);
                },
                builder: (_, route) => CatalogScreen(route: route),
              ),
              dataRoute<ProductRoute, ProductDetails>(
                path: '/products/:id',
                parse: (state) {
                  final panel = state.query.containsKey('panel')
                      ? state.query.$enum('panel', ProductPanel.values)
                      : ProductPanel.overview;
                  return ProductRoute(
                    id: state.params.$int('id'),
                    panel: panel,
                  );
                },
                loader: (context) => _loadProduct(context.route),
                builder: (_, route, data) =>
                    ProductScreen(route: route, data: data),
              ),
            ],
          ),
          branch<AppRoute>(
            initialLocation: Uri(path: '/cart'),
            routes: <RouteRecord<AppRoute>>[
              dataRoute<CartRoute, CartSummary>(
                path: '/cart',
                parse: (_) => const CartRoute(),
                loader: (_) => _loadCartSummary(),
                builder: (_, route, summary) =>
                    CartScreen(route: route, summary: summary),
              ),
              route<ProfileRoute>(
                path: '/profile',
                parse: (_) => const ProfileRoute(),
                builder: (_, _) => const ProfileScreen(),
              ),
              dataRoute<CheckoutRoute, CheckoutSummary>(
                path: '/checkout',
                parse: (_) => const CheckoutRoute(),
                guards: <RouteGuard<CheckoutRoute>>[
                  (context) {
                    if (!_session.isSignedIn) {
                      return RouteGuardResult.redirect(
                        route: LoginRoute(from: context.uri.toString()),
                      );
                    }
                    if (_session.itemCount == 0) {
                      return const RouteGuardResult.block();
                    }
                    return const RouteGuardResult.allow();
                  },
                ],
                loader: (_) => _loadCheckoutSummary(),
                builder: (_, _, summary) => CheckoutScreen(summary: summary),
              ),
            ],
          ),
        ],
        builder: (_, shellState, child) {
          return StudioShell(shellState: shellState, child: child);
        },
      ),
      route<LoginRoute>(
        path: '/login',
        parse: (state) => LoginRoute(from: state.query['from']),
        builder: (_, route) => LoginScreen(route: route),
      ),
    ],
    unknown: (_, uri) => UnknownRouteScreen(uri: uri),
    blocked: (_, uri) => BlockedRouteScreen(uri: uri),
    loading: (_, uri) => LoadingRouteScreen(uri: uri),
    onError: (_, error, stackTrace) {
      return ErrorRouteScreen(error: error, stackTrace: stackTrace);
    },
  );
}

class AtelierExampleApp extends StatelessWidget {
  AtelierExampleApp({super.key}) : _router = _createRouter() {
    _session.reset();
    _eventFeed.value = 'Ready';
  }

  final Unrouter<AppRoute> _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Atelier Storefront',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1157D8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F1E8),
      ),
      routerConfig: _router,
    );
  }
}

class StudioShell extends StatelessWidget {
  const StudioShell({super.key, required this.shellState, required this.child});

  final ShellState<AppRoute> shellState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 76,
            elevation: 0,
            flexibleSpace: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF0C1F3D), Color(0xFF1446A0)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(
                            0xFF89A6FF,
                          ).withValues(alpha: 0.22),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Atelier Storefront',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              controller.state.uri.toString(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFFBFD5FF),
                                    letterSpacing: 0.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        key: const Key('shell-go-cart'),
                        onPressed: () {
                          shellState.goBranch(1);
                        },
                        child: const Text('Wallet'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        key: const Key('shell-auth-toggle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF8EB1FF)),
                        ),
                        onPressed: () {
                          _session.toggleAuth();
                          _eventFeed.value = _session.isSignedIn
                              ? 'Session opened'
                              : 'Session closed';
                        },
                        child: Text(
                          _session.isSignedIn ? 'Sign out' : 'Sign in',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFFF7F2E9), Color(0xFFECE7DD)],
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: <Widget>[
                      Container(
                        key: const Key('shell-cart-count'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6DBCA),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Cart ${_session.itemCount}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _session.isSignedIn
                              ? const Color(0xFFD4F4E6)
                              : const Color(0xFFFFE2D6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _session.isSignedIn ? 'Signed in' : 'Guest mode',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _eventFeed,
                          builder: (context, value, _) {
                            return Text(
                              value,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<String>(controller.state.uri.toString()),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: shellState.activeBranchIndex,
            onDestinationSelected: (index) {
              shellState.goBranch(index);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: _HeroBanner(controller: controller),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Quick routes',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonal(
                key: const Key('dashboard-go-catalog'),
                onPressed: () {
                  controller.go(const CatalogRoute(tab: CatalogTab.featured));
                  _eventFeed.value = 'Opened featured catalog';
                },
                child: const Text('Open catalog'),
              ),
              FilledButton(
                key: const Key('dashboard-push-highlight'),
                onPressed: () async {
                  final qty = await controller.push<int>(
                    const ProductRoute(id: 42, panel: ProductPanel.overview),
                  );
                  if (qty != null && qty > 0) {
                    _session.addToCart(42, qty);
                    _eventFeed.value = 'Added Nebula 75 x$qty';
                  }
                },
                child: const Text('Inspect Nebula 75'),
              ),
              OutlinedButton(
                onPressed: () {
                  controller.go(const CheckoutRoute());
                },
                child: const Text('Jump to checkout'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'State monitor',
          child: Text(
            'resolution: ${controller.state.resolution.name}\n'
            'route: ${controller.state.routePath ?? '-'}\n'
            'action: ${controller.state.lastAction.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.controller});

  final UnrouterController<AppRoute> controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0A2448),
            Color(0xFF1360E2),
            Color(0xFF4AB0FF),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Designed for calm, built for speed.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use typed routes, branch navigation, and guard-driven flows '
            'without losing visual polish.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFEAF3FF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'href preview: ${controller.href(const ProductRoute(id: 11, panel: ProductPanel.specs))}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFFD5E6FF)),
          ),
        ],
      ),
    );
  }
}

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, required this.route});

  final CatalogRoute route;

  @override
  Widget build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    final products = _productsForTab(route.tab);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: <Widget>[
        _SectionCard(
          title: 'Catalog lanes',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CatalogTab.values.map((tab) {
              final selected = tab == route.tab;
              return ChoiceChip(
                label: Text(_catalogLabel(tab)),
                selected: selected,
                onSelected: (_) {
                  controller.go(CatalogRoute(tab: tab));
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        for (final product in products)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProductTile(
              product: product,
              onOpen: () async {
                final qty = await controller.push<int>(
                  ProductRoute(id: product.id, panel: ProductPanel.overview),
                );
                if (qty != null && qty > 0) {
                  _session.addToCart(product.id, qty);
                  _eventFeed.value = 'Added ${product.name} x$qty';
                }
              },
            ),
          ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onOpen});

  final ProductSeed product;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: <Color>[
                  product.tint.withValues(alpha: 0.86),
                  product.tint.withValues(alpha: 0.46),
                ],
              ),
            ),
            child: const Icon(Icons.keyboard_alt_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  product.tagline,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _usd(product.priceCents),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              FilledButton.tonal(
                key: Key('catalog-open-${product.id}'),
                onPressed: () {
                  onOpen();
                },
                child: const Text('Open'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.route, required this.data});

  final ProductRoute route;
  final ProductDetails data;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: <Widget>[
        _SectionCard(
          title: widget.data.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.data.story),
              const SizedBox(height: 10),
              Text(
                '${_usd(widget.data.priceCents)}  •  ${widget.data.rating.toStringAsFixed(1)}★',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              SegmentedButton<ProductPanel>(
                segments: ProductPanel.values
                    .map(
                      (panel) => ButtonSegment<ProductPanel>(
                        value: panel,
                        label: Text(panel.name),
                      ),
                    )
                    .toList(),
                selected: <ProductPanel>{widget.route.panel},
                onSelectionChanged: (selection) {
                  controller.go(
                    ProductRoute(id: widget.route.id, panel: selection.first),
                  );
                },
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Text(
                  _panelCopy(widget.route.panel, widget.data),
                  key: ValueKey<ProductPanel>(widget.route.panel),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Quantity',
          child: Row(
            children: <Widget>[
              IconButton(
                key: const Key('product-qty-minus'),
                onPressed: () {
                  setState(() {
                    _qty = math.max(1, _qty - 1);
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_qty', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                key: const Key('product-qty-plus'),
                onPressed: () {
                  setState(() {
                    _qty += 1;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.unrouter.back(),
                child: const Text('Back'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                key: const Key('product-add-return'),
                onPressed: () {
                  context.unrouter.pop<int>(_qty);
                },
                child: const Text('Add & return'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.route, required this.summary});

  final CartRoute route;
  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    route;
    final controller = context.unrouterAs<AppRoute>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: <Widget>[
        _SectionCard(
          title: 'Cart composition',
          child: summary.entries.isEmpty
              ? const Text('No items yet. Add one from the catalog.')
              : Column(
                  children: summary.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text(entry.name)),
                          Text('x${entry.quantity}'),
                          const SizedBox(width: 14),
                          Text(_usd(entry.subtotalCents)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Summary',
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Items: ${summary.itemCount}\nTotal: ${_usd(summary.totalCents)}',
                ),
              ),
              FilledButton(
                key: const Key('cart-go-checkout'),
                onPressed: () {
                  controller.go(const CheckoutRoute());
                },
                child: const Text('Checkout'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('cart-clear'),
                onPressed: () {
                  _session.clearCart();
                  _eventFeed.value = 'Cart cleared';
                  controller.go(const CartRoute());
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: <Widget>[
        _SectionCard(
          title: 'Profile lane',
          child: AnimatedBuilder(
            animation: _session,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _session.isSignedIn
                        ? 'Welcome back. Concierge mode enabled.'
                        : 'Guest mode. Sign in for checkout.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('profile-toggle-auth'),
                    onPressed: () {
                      _session.toggleAuth();
                    },
                    child: Text(_session.isSignedIn ? 'Sign out' : 'Sign in'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      controller.go(const DashboardRoute());
                    },
                    child: const Text('Back to explore'),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.route});

  final LoginRoute route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Authentication required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text('After sign-in, you will continue to: ${route.from ?? '/'}'),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('login-sign-in-continue'),
                onPressed: () {
                  _session.signIn();
                  _eventFeed.value = 'Session opened from login';
                  final target = Uri.tryParse(route.from ?? '');
                  if (target == null) {
                    context.unrouter.go(const DashboardRoute());
                    return;
                  }
                  if (target.path == '/checkout' && _session.itemCount == 0) {
                    _eventFeed.value = 'Checkout requires cart items first';
                    context.unrouter.go(const CartRoute());
                    return;
                  }
                  context.unrouter.goUri(target);
                },
                child: const Text('Sign in and continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.summary});

  final CheckoutSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: <Widget>[
        _SectionCard(
          title: 'Checkout ready',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Subtotal: ${_usd(summary.subtotalCents)}',
                key: const Key('checkout-title'),
              ),
              Text('Shipping: ${_usd(summary.shippingCents)}'),
              Text('Tax: ${_usd(summary.taxCents)}'),
              const SizedBox(height: 8),
              Text(
                'Total: ${_usd(summary.totalCents)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  _session.clearCart();
                  _eventFeed.value = 'Order confirmed';
                  context.unrouter.go(const DashboardRoute());
                },
                child: const Text('Place order'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Route not found',
      message: 'No screen is mapped to ${uri.path}.',
      actionLabel: 'Back to dashboard',
      onAction: () => context.unrouter.go(const DashboardRoute()),
    );
  }
}

class BlockedRouteScreen extends StatelessWidget {
  const BlockedRouteScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Unable to continue',
      message: 'Your cart is empty. Add products before opening ${uri.path}.',
      messageKey: const Key('blocked-message'),
      actionLabel: 'Open catalog',
      onAction: () =>
          context.unrouter.go(const CatalogRoute(tab: CatalogTab.featured)),
    );
  }
}

class LoadingRouteScreen extends StatelessWidget {
  const LoadingRouteScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Resolving route',
      message: 'Loading ${uri.path}...',
      loading: true,
      actionLabel: 'Cancel',
      onAction: () => context.unrouter.back(),
    );
  }
}

class ErrorRouteScreen extends StatelessWidget {
  const ErrorRouteScreen({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Route error',
      message: '$error\n\n$stackTrace',
      actionLabel: 'Back to dashboard',
      onAction: () => context.unrouter.go(const DashboardRoute()),
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.loading = false,
    this.messageKey,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool loading;
  final Key? messageKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 560,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 5),
                ),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(message, key: messageKey),
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

Future<ProductDetails> _loadProduct(ProductRoute route) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  final seed = _catalogById[route.id];
  if (seed == null) {
    throw StateError('Unknown product id ${route.id}.');
  }
  return ProductDetails(
    id: seed.id,
    name: seed.name,
    story: seed.description,
    priceCents: seed.priceCents,
    rating: seed.rating,
  );
}

Future<CartSummary> _loadCartSummary() async {
  await Future<void>.delayed(const Duration(milliseconds: 70));
  return _session.toCartSummary();
}

Future<CheckoutSummary> _loadCheckoutSummary() async {
  await Future<void>.delayed(const Duration(milliseconds: 90));
  final cart = _session.toCartSummary();
  final shipping = cart.itemCount == 0 ? 0 : 1200;
  final tax = (cart.totalCents * 0.08).round();
  return CheckoutSummary(
    subtotalCents: cart.totalCents,
    shippingCents: shipping,
    taxCents: tax,
    totalCents: cart.totalCents + shipping + tax,
  );
}

List<ProductSeed> _productsForTab(CatalogTab tab) {
  if (tab == CatalogTab.featured) {
    return _products;
  }
  return _products.where((product) => product.tab == tab).toList();
}

String _catalogLabel(CatalogTab tab) {
  return switch (tab) {
    CatalogTab.featured => 'Featured',
    CatalogTab.keyboards => 'Keyboards',
    CatalogTab.accessories => 'Accessories',
  };
}

String _panelCopy(ProductPanel panel, ProductDetails data) {
  return switch (panel) {
    ProductPanel.overview => data.story,
    ProductPanel.specs =>
      'CNC frame, hot-swappable PCB, gasket mount, and tuned stabilizers.',
    ProductPanel.reviews =>
      '“Incredibly balanced acoustics and a refined typing feel.”',
  };
}

String _usd(int cents) {
  final dollars = cents ~/ 100;
  final remains = (cents % 100).toString().padLeft(2, '0');
  return '\$$dollars.$remains';
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class DashboardRoute extends AppRoute {
  const DashboardRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

enum CatalogTab { featured, keyboards, accessories }

final class CatalogRoute extends AppRoute {
  const CatalogRoute({this.tab = CatalogTab.featured});

  final CatalogTab tab;

  @override
  Uri toUri() =>
      Uri(path: '/catalog', queryParameters: <String, String>{'tab': tab.name});
}

enum ProductPanel { overview, specs, reviews }

final class ProductRoute extends AppRoute {
  const ProductRoute({required this.id, this.panel = ProductPanel.overview});

  final int id;
  final ProductPanel panel;

  @override
  Uri toUri() {
    return Uri(
      path: '/products/$id',
      queryParameters: <String, String>{'panel': panel.name},
    );
  }
}

final class CartRoute extends AppRoute {
  const CartRoute();

  @override
  Uri toUri() => Uri(path: '/cart');
}

final class ProfileRoute extends AppRoute {
  const ProfileRoute();

  @override
  Uri toUri() => Uri(path: '/profile');
}

final class CheckoutRoute extends AppRoute {
  const CheckoutRoute();

  @override
  Uri toUri() => Uri(path: '/checkout');
}

final class LoginRoute extends AppRoute {
  const LoginRoute({this.from});

  final String? from;

  @override
  Uri toUri() {
    return Uri(
      path: '/login',
      queryParameters: from == null ? null : <String, String>{'from': from!},
    );
  }
}

final class ProductSeed {
  const ProductSeed({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.priceCents,
    required this.rating,
    required this.tab,
    required this.tint,
  });

  final int id;
  final String name;
  final String tagline;
  final String description;
  final int priceCents;
  final double rating;
  final CatalogTab tab;
  final Color tint;
}

final List<ProductSeed> _products = <ProductSeed>[
  const ProductSeed(
    id: 11,
    name: 'Aster 68',
    tagline: 'Compact board with luminous underglow.',
    description:
        'Aster 68 blends a dense aluminum chassis with a bright but calm profile.',
    priceCents: 11900,
    rating: 4.7,
    tab: CatalogTab.keyboards,
    tint: Color(0xFF7A87FF),
  ),
  const ProductSeed(
    id: 42,
    name: 'Nebula 75',
    tagline: 'Gasket-mounted daily driver with sculpted acoustics.',
    description:
        'Nebula 75 is tuned for long sessions with a soft, confident key feel.',
    priceCents: 14900,
    rating: 4.9,
    tab: CatalogTab.keyboards,
    tint: Color(0xFF1380EF),
  ),
  const ProductSeed(
    id: 73,
    name: 'Silk Wrist Rest',
    tagline: 'Layered resin support with subtle texture.',
    description: 'Silk Wrist Rest adds comfort without stealing desk space.',
    priceCents: 3900,
    rating: 4.6,
    tab: CatalogTab.accessories,
    tint: Color(0xFF5FAE87),
  ),
];

final Map<int, ProductSeed> _catalogById = <int, ProductSeed>{
  for (final product in _products) product.id: product,
};

final class ProductDetails {
  const ProductDetails({
    required this.id,
    required this.name,
    required this.story,
    required this.priceCents,
    required this.rating,
  });

  final int id;
  final String name;
  final String story;
  final int priceCents;
  final double rating;
}

final class CartEntry {
  const CartEntry({
    required this.id,
    required this.name,
    required this.quantity,
    required this.subtotalCents,
  });

  final int id;
  final String name;
  final int quantity;
  final int subtotalCents;
}

final class CartSummary {
  const CartSummary({
    required this.entries,
    required this.itemCount,
    required this.totalCents,
  });

  final List<CartEntry> entries;
  final int itemCount;
  final int totalCents;
}

final class CheckoutSummary {
  const CheckoutSummary({
    required this.subtotalCents,
    required this.shippingCents,
    required this.taxCents,
    required this.totalCents,
  });

  final int subtotalCents;
  final int shippingCents;
  final int taxCents;
  final int totalCents;
}

class StoreSession extends ChangeNotifier {
  bool _isSignedIn = false;
  final Map<int, int> _cart = <int, int>{};

  bool get isSignedIn => _isSignedIn;
  int get itemCount => _cart.values.fold<int>(0, (sum, qty) => sum + qty);

  void signIn() {
    _isSignedIn = true;
    notifyListeners();
  }

  void signOut() {
    _isSignedIn = false;
    notifyListeners();
  }

  void toggleAuth() {
    if (_isSignedIn) {
      signOut();
      return;
    }
    signIn();
  }

  void addToCart(int productId, int quantity) {
    if (quantity <= 0) {
      return;
    }
    _cart.update(
      productId,
      (value) => value + quantity,
      ifAbsent: () => quantity,
    );
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  CartSummary toCartSummary() {
    final entries = <CartEntry>[];
    var total = 0;
    var count = 0;

    for (final entry in _cart.entries) {
      final product = _catalogById[entry.key];
      if (product == null) {
        continue;
      }
      final subtotal = product.priceCents * entry.value;
      entries.add(
        CartEntry(
          id: product.id,
          name: product.name,
          quantity: entry.value,
          subtotalCents: subtotal,
        ),
      );
      total += subtotal;
      count += entry.value;
    }

    entries.sort((a, b) => a.name.compareTo(b.name));
    return CartSummary(entries: entries, itemCount: count, totalCents: total);
  }

  void reset() {
    _isSignedIn = false;
    _cart.clear();
    notifyListeners();
  }
}
