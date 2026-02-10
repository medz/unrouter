import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';

final StoreSession _session = StoreSession();
final Unrouter<AppRoute> _router = createRouter();

Future<void> main() async {
  _session.reset();

  await runApp(
    NoctermApp(
      title: 'Atelier Terminal Router',
      iconName: 'unrouter',
      theme: TuiThemeData.catppuccinMocha,
      child: _router,
    ),
  );
}

Unrouter<AppRoute> createRouter({StoreSession? session}) {
  final activeSession = session ?? _session;
  return Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<RootRoute>(
        path: '/',
        parse: (_) => const RootRoute(),
        redirect: (_) => const DiscoverRoute().toUri(),
        builder: (_, __) => const SizedBox.shrink(),
      ),
      ...shell<AppRoute>(
        builder: (_, shellState, child) {
          return TerminalShell(shellState: shellState, child: child);
        },
        branches: <ShellBranch<AppRoute>>[
          branch<AppRoute>(
            initialLocation: const DiscoverRoute().toUri(),
            routes: <RouteRecord<AppRoute>>[
              route<DiscoverRoute>(
                path: '/discover',
                parse: (_) => const DiscoverRoute(),
                builder: (_, __) => const DiscoverPage(),
              ),
              route<CatalogRoute>(
                path: '/catalog',
                parse: (state) {
                  final tab = state.query.containsKey('tab')
                      ? state.query.$enum('tab', CatalogTab.values)
                      : CatalogTab.featured;
                  return CatalogRoute(tab: tab);
                },
                builder: (_, route) => CatalogPage(route: route),
              ),
              route<LegacyProductRoute>(
                path: '/p/:id',
                parse: (state) =>
                    LegacyProductRoute(id: state.params.$int('id')),
                redirect: (context) =>
                    ProductRoute(id: context.route.id).toUri(),
                builder: (_, route) => LegacyRedirectPage(route: route),
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
                loader: _loadProduct,
                builder: (_, route, data) =>
                    ProductPage(route: route, data: data),
              ),
              route<QuantityRoute>(
                path: '/products/:id/quantity',
                parse: (state) => QuantityRoute(id: state.params.$int('id')),
                builder: (_, route) => QuantityPickerPage(route: route),
              ),
            ],
          ),
          branch<AppRoute>(
            initialLocation: const CartRoute().toUri(),
            routes: <RouteRecord<AppRoute>>[
              dataRoute<CartRoute, CartSummary>(
                path: '/cart',
                parse: (_) => const CartRoute(),
                loader: (context) => _loadCart(context, activeSession),
                builder: (_, __, data) => CartPage(data: data),
              ),
              dataRoute<CheckoutRoute, CheckoutSummary>(
                path: '/checkout',
                parse: (_) => const CheckoutRoute(),
                guards: <RouteGuard<CheckoutRoute>>[
                  (context) {
                    if (!activeSession.isSignedIn) {
                      return RouteGuardResult.redirect(
                        route: LoginRoute(from: context.uri.toString()),
                      );
                    }
                    if (activeSession.itemCount == 0) {
                      return const RouteGuardResult.block();
                    }
                    return const RouteGuardResult.allow();
                  },
                ],
                loader: (context) => _loadCheckout(context, activeSession),
                builder: (_, __, data) => CheckoutPage(data: data),
              ),
            ],
          ),
        ],
      ),
      route<LoginRoute>(
        path: '/login',
        parse: (state) => LoginRoute(from: state.query['from']),
        builder: (_, route) => LoginPage(route: route),
      ),
    ],
    unknown: (_, uri) => FallbackPage(
      title: 'Unknown route',
      detail: 'No route matches ${uri.path}.',
    ),
    blocked: (_, uri) => FallbackPage(
      title: 'Blocked route',
      detail: 'Guard prevented access to ${uri.path}.',
    ),
    loading: (_, uri) =>
        FallbackPage(title: 'Loading', detail: 'Resolving ${uri.path} ...'),
    onError: (_, error, __) =>
        FallbackPage(title: 'Router error', detail: error.toString()),
    resolveInitialRoute: true,
  );
}

class TerminalShell extends StatelessComponent {
  const TerminalShell({
    super.key,
    required this.shellState,
    required this.child,
  });

  final ShellState<AppRoute> shellState;
  final Component child;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final theme = TuiTheme.of(context);

        return Focusable(
          focused: true,
          onKeyEvent: (event) {
            return _handleKey(event: event, controller: controller);
          },
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(color: theme.background),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Component>[
                _panel(
                  title: 'Atelier Terminal',
                  color: theme.surface.withOpacity(0.8),
                  children: <Component>[
                    Row(
                      children: <Component>[
                        Expanded(
                          child: Text(
                            'URI ${controller.state.uri}',
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 1),
                        Text(
                          shellState.activeBranchIndex == 0
                              ? 'Explore branch'
                              : 'Wallet branch',
                          style: TextStyle(color: theme.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: <Component>[
                        _badge(
                          'Items ${_session.itemCount}',
                          color: theme.primary,
                        ),
                        const SizedBox(width: 1),
                        _badge(
                          _session.isSignedIn ? 'Signed in' : 'Guest',
                          color: _session.isSignedIn
                              ? theme.success
                              : theme.warning,
                        ),
                        const SizedBox(width: 1),
                        Expanded(
                          child: Text(
                            _session.status,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.onSurface),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Global keys: [E] Explore  [W] Wallet  [A] Auth toggle  [B] Back',
                      style: TextStyle(color: theme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _handleKey({
    required KeyboardEvent event,
    required UnrouterController<AppRoute> controller,
  }) {
    final key = event.logicalKey;

    if (key == LogicalKey.keyE) {
      shellState.goBranch(0);
      return true;
    }
    if (key == LogicalKey.keyW) {
      shellState.goBranch(1);
      return true;
    }
    if (key == LogicalKey.keyA) {
      _session.toggleAuth();
      return true;
    }
    if (key == LogicalKey.keyB) {
      if (shellState.popBranch()) {
        return true;
      }
      if (controller.back()) {
        return true;
      }
      final fallback = _fallbackBackRoute(controller.route);
      if (fallback != null) {
        controller.go(fallback);
        return true;
      }
      return false;
    }

    final route = controller.route;
    if (route == null) {
      if (key == LogicalKey.keyH) {
        controller.go(const DiscoverRoute());
        return true;
      }
      return false;
    }

    if (route is DiscoverRoute) {
      if (key == LogicalKey.keyC) {
        controller.go(const CatalogRoute(tab: CatalogTab.featured));
        return true;
      }
      if (key == LogicalKey.keyP) {
        controller.go(const ProductRoute(id: 201));
        return true;
      }
      if (key == LogicalKey.keyL) {
        controller.go(const LegacyProductRoute(id: 202));
        return true;
      }
      return false;
    }

    if (route is CatalogRoute) {
      if (key == LogicalKey.keyF) {
        controller.go(const CatalogRoute(tab: CatalogTab.featured));
        return true;
      }
      if (key == LogicalKey.keyS) {
        controller.go(const CatalogRoute(tab: CatalogTab.studio));
        return true;
      }
      if (key == LogicalKey.keyT) {
        controller.go(const CatalogRoute(tab: CatalogTab.essentials));
        return true;
      }

      final index = _digitToIndex(key);
      if (index != null) {
        final products = _productsByTab(route.tab);
        if (index < products.length) {
          controller.go(ProductRoute(id: products[index].id));
          return true;
        }
      }
      return false;
    }

    if (route is ProductRoute) {
      if (key == LogicalKey.keyO) {
        final panels = ProductPanel.values;
        final next = panels[(route.panel.index + 1) % panels.length];
        controller.go(ProductRoute(id: route.id, panel: next));
        return true;
      }
      if (key == LogicalKey.keyR) {
        _session.addItem(route.id, qty: 1);
        controller.go(const CartRoute());
        return true;
      }
      if (key == LogicalKey.keyQ) {
        unawaited(
          controller.push<int>(QuantityRoute(id: route.id)).then((qty) {
            if (qty == null) {
              _session.note('Quantity picker dismissed');
              return;
            }
            _session.addItem(route.id, qty: qty);
            controller.go(const CartRoute());
          }),
        );
        return true;
      }
      return false;
    }

    if (route is QuantityRoute) {
      final quantity = _digitToQuantity(key);
      if (quantity != null) {
        controller.pop<int>(quantity);
        return true;
      }
      if (key == LogicalKey.escape) {
        return controller.back();
      }
      return false;
    }

    if (route is CartRoute) {
      if (key == LogicalKey.keyK) {
        controller.go(const CheckoutRoute());
        return true;
      }
      if (key == LogicalKey.keyX) {
        _session.clearCart(reason: 'Cart cleared from wallet');
        controller.go(const CartRoute());
        return true;
      }
      if (key == LogicalKey.keyD) {
        controller.go(const DiscoverRoute());
        return true;
      }
      return false;
    }

    if (route is CheckoutRoute) {
      if (key == LogicalKey.keyP) {
        _session.clearCart(reason: 'Payment completed successfully');
        controller.go(const DiscoverRoute());
        return true;
      }
      if (key == LogicalKey.escape) {
        controller.go(const CartRoute());
        return true;
      }
      return false;
    }

    return false;
  }

  AppRoute? _fallbackBackRoute(AppRoute? route) {
    return switch (route) {
      QuantityRoute r => ProductRoute(id: r.id),
      ProductRoute _ => const CatalogRoute(tab: CatalogTab.featured),
      CatalogRoute _ => const DiscoverRoute(),
      CheckoutRoute _ => const CartRoute(),
      CartRoute _ => const DiscoverRoute(),
      DiscoverRoute _ => null,
      _ => const DiscoverRoute(),
    };
  }
}

class DiscoverPage extends StatelessComponent {
  const DiscoverPage({super.key});

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final featured = _productsByTab(CatalogTab.featured);

    return _panel(
      title: 'Discover',
      color: theme.surface.withOpacity(0.9),
      children: <Component>[
        Text(
          'Pure terminal storefront driven by unrouter core runtime.',
          style: TextStyle(color: theme.onSurface),
        ),
        const SizedBox(height: 1),
        Text(
          'Keys: [C] Catalog  [P] Product  [L] Legacy redirect',
          style: TextStyle(color: theme.outline),
        ),
        const SizedBox(height: 1),
        for (final product in featured) _productRow(product, theme),
      ],
    );
  }
}

class CatalogPage extends StatelessComponent {
  const CatalogPage({super.key, required this.route});

  final CatalogRoute route;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final products = _productsByTab(route.tab);

    return _panel(
      title: 'Catalog · ${_catalogTabLabel(route.tab)}',
      color: theme.surface.withOpacity(0.9),
      children: <Component>[
        Text(
          'Query parsing via /catalog?tab=. Choose product using [1]-[4].',
          style: TextStyle(color: theme.outline),
        ),
        const SizedBox(height: 1),
        Text(
          'Tabs: [F] Featured  [S] Studio  [T] Essentials',
          style: TextStyle(color: theme.onSurface),
        ),
        const SizedBox(height: 1),
        for (var i = 0; i < products.length; i++)
          Text(
            '[${i + 1}] ${products[i].title} · ${_usd(products[i].priceCents)}',
            style: TextStyle(color: theme.onSurface),
          ),
      ],
    );
  }
}

class LegacyRedirectPage extends StatelessComponent {
  const LegacyRedirectPage({super.key, required this.route});

  final LegacyProductRoute route;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    return _panel(
      title: 'Legacy',
      color: theme.surface.withOpacity(0.9),
      children: <Component>[
        Text(
          'Redirecting /p/${route.id} -> /products/${route.id}',
          style: TextStyle(color: theme.onSurface),
        ),
      ],
    );
  }
}

class ProductPage extends StatelessComponent {
  const ProductPage({super.key, required this.route, required this.data});

  final ProductRoute route;
  final ProductDetails data;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);

    return _panel(
      title: 'Product · ${data.title}',
      color: theme.surface.withOpacity(0.9),
      children: <Component>[
        Text(data.subtitle, style: TextStyle(color: theme.outline)),
        Text(
          _usd(data.priceCents),
          style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 1),
        Text(
          'Panel: ${_panelLabel(route.panel)}',
          style: TextStyle(color: theme.onSurface),
        ),
        Text(
          _panelCopy(route.panel, data),
          style: TextStyle(color: theme.outline),
        ),
        const SizedBox(height: 1),
        Text(
          'Keys: [O] Next panel  [R] Add one  [Q] Quantity picker (push/pop)',
          style: TextStyle(color: theme.onSurface),
        ),
      ],
    );
  }
}

class QuantityPickerPage extends StatelessComponent {
  const QuantityPickerPage({super.key, required this.route});

  final QuantityRoute route;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final product = _catalog[route.id];

    return _panel(
      title: 'Quantity picker',
      color: theme.surface.withOpacity(0.9),
      children: <Component>[
        Text(
          product == null ? 'Product ${route.id}' : product.title,
          style: TextStyle(color: theme.onSurface),
        ),
        const SizedBox(height: 1),
        Text(
          'Press [1]-[4] to return typed result.',
          style: TextStyle(color: theme.outline),
        ),
        Text(
          'Press [Esc] to cancel picker.',
          style: TextStyle(color: theme.outline),
        ),
      ],
    );
  }
}

class CartPage extends StatelessComponent {
  const CartPage({super.key, required this.data});
  final CartSummary data;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);

    return _panel(
      title: 'Cart',
      color: theme.surface.withOpacity(0.9),
      children: <Component>[
        Text(
          'Items ${data.itemCount} · Total ${_usd(data.totalCents)}',
          style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 1),
        if (data.lines.isEmpty)
          Text(
            'Cart is empty. Use Explore/Catalog to add products.',
            style: TextStyle(color: theme.outline),
          )
        else
          ...data.lines.map((line) {
            return Text(
              '- ${line.title} | ${line.quantity} × ${_usd(line.unitPriceCents)} = ${_usd(line.totalCents)}',
              style: TextStyle(color: theme.onSurface),
            );
          }),
        const SizedBox(height: 1),
        Text(
          'Keys: [K] Checkout  [X] Clear cart  [D] Discover',
          style: TextStyle(color: theme.outline),
        ),
      ],
    );
  }
}

class CheckoutPage extends StatelessComponent {
  const CheckoutPage({super.key, required this.data});

  final CheckoutSummary data;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);

    return _panel(
      title: 'Checkout',
      color: theme.surface.withOpacity(0.9),
      children: <Component>[
        Text(
          'Guard passed: signed-in + non-empty cart.',
          style: TextStyle(color: theme.outline),
        ),
        Text(
          '${data.itemCount} items · ${_usd(data.totalCents)} · ETA ${data.etaMinutes}m',
          style: TextStyle(color: theme.success, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 1),
        Text(
          'Keys: [P] Pay now  [Esc] Back to cart',
          style: TextStyle(color: theme.onSurface),
        ),
      ],
    );
  }
}

class LoginPage extends StatelessComponent {
  const LoginPage({super.key, required this.route});

  final LoginRoute route;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);
    final controller = context.unrouterAs<AppRoute>();

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.enter) {
          _completeLogin(controller: controller, route: route);
          return true;
        }
        if (event.logicalKey == LogicalKey.escape ||
            event.logicalKey == LogicalKey.keyB) {
          controller.go(const DiscoverRoute());
          return true;
        }
        return false;
      },
      child: _panel(
        title: 'Login required',
        color: theme.surface.withOpacity(0.9),
        children: <Component>[
          Text(
            'Checkout requires authentication in this demo.',
            style: TextStyle(color: theme.onSurface),
          ),
          Text(
            'Return target: ${route.from ?? '/cart'}',
            style: TextStyle(color: theme.outline),
          ),
          const SizedBox(height: 1),
          Text(
            'Keys: [Enter] Sign in and continue  [Esc] Explore',
            style: TextStyle(color: theme.primary),
          ),
        ],
      ),
    );
  }
}

class FallbackPage extends StatelessComponent {
  const FallbackPage({super.key, required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Component build(BuildContext context) {
    final theme = TuiTheme.of(context);

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyH ||
            event.logicalKey == LogicalKey.keyB ||
            event.logicalKey == LogicalKey.escape) {
          try {
            context.unrouterAs<AppRoute>().go(const DiscoverRoute());
            return true;
          } on StateError {
            return false;
          }
        }
        return false;
      },
      child: _panel(
        title: title,
        color: theme.surface.withOpacity(0.9),
        children: <Component>[
          Text(detail, style: TextStyle(color: theme.error)),
          const SizedBox(height: 1),
          Text(
            'Press [H] to jump back to Discover.',
            style: TextStyle(color: theme.outline),
          ),
        ],
      ),
    );
  }
}

void _completeLogin({
  required UnrouterController<AppRoute> controller,
  required LoginRoute route,
}) {
  _session.signIn();
  final target = route.from == null
      ? const CartRoute().toUri()
      : (Uri.tryParse(route.from!) ?? const CartRoute().toUri());
  if (target.path == '/checkout' && _session.itemCount == 0) {
    _session.note('Checkout requires cart items first');
    controller.go(const CartRoute());
    return;
  }
  controller.goUri(target);
}

Component _panel({
  required String title,
  required List<Component> children,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
    decoration: BoxDecoration(
      color: color,
      border: BoxBorder.all(style: BoxBorderStyle.rounded),
      title: BorderTitle(text: ' $title ', alignment: TitleAlignment.left),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

Component _badge(String label, {required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(
      color: color.withOpacity(0.24),
      border: BoxBorder.all(color: color, style: BoxBorderStyle.rounded),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    ),
  );
}

Component _productRow(ProductDetails product, TuiThemeData theme) {
  return Row(
    children: <Component>[
      Expanded(
        child: Text(
          product.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.onSurface),
        ),
      ),
      Text(
        _usd(product.priceCents),
        style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

Future<ProductDetails> _loadProduct(RouteContext<ProductRoute> context) async {
  await Future<void>.delayed(const Duration(milliseconds: 80));

  final product = _catalog[context.route.id];
  if (product == null) {
    throw StateError('Product ${context.route.id} was not found.');
  }
  return product;
}

Future<CartSummary> _loadCart(
  RouteContext<CartRoute> context,
  StoreSession session,
) async {
  context.signal.throwIfCancelled();
  await Future<void>.delayed(const Duration(milliseconds: 70));
  context.signal.throwIfCancelled();

  final lines = <CartLine>[];
  var itemCount = 0;
  var totalCents = 0;

  for (final entry in session.cartEntries) {
    final product = _catalog[entry.key];
    if (product == null) {
      continue;
    }

    final quantity = entry.value;
    final lineTotal = product.priceCents * quantity;
    itemCount += quantity;
    totalCents += lineTotal;

    lines.add(
      CartLine(
        productId: product.id,
        title: product.title,
        quantity: quantity,
        unitPriceCents: product.priceCents,
        totalCents: lineTotal,
      ),
    );
  }

  return CartSummary(
    lines: lines,
    itemCount: itemCount,
    totalCents: totalCents,
  );
}

Future<CheckoutSummary> _loadCheckout(
  RouteContext<CheckoutRoute> context,
  StoreSession session,
) async {
  context.signal.throwIfCancelled();
  await Future<void>.delayed(const Duration(milliseconds: 90));
  context.signal.throwIfCancelled();

  var itemCount = 0;
  var totalCents = 0;
  for (final entry in session.cartEntries) {
    final product = _catalog[entry.key];
    if (product == null) {
      continue;
    }
    itemCount += entry.value;
    totalCents += product.priceCents * entry.value;
  }

  return CheckoutSummary(
    itemCount: itemCount,
    totalCents: totalCents,
    etaMinutes: 10 + itemCount,
  );
}

int? _digitToIndex(LogicalKey key) {
  return switch (key) {
    LogicalKey.digit1 => 0,
    LogicalKey.digit2 => 1,
    LogicalKey.digit3 => 2,
    LogicalKey.digit4 => 3,
    _ => null,
  };
}

int? _digitToQuantity(LogicalKey key) {
  return switch (key) {
    LogicalKey.digit1 => 1,
    LogicalKey.digit2 => 2,
    LogicalKey.digit3 => 3,
    LogicalKey.digit4 => 4,
    _ => null,
  };
}

List<ProductDetails> _productsByTab(CatalogTab tab) {
  return _catalog.values
      .where((product) => product.tabs.contains(tab))
      .toList();
}

String _usd(int cents) {
  final dollars = cents ~/ 100;
  final remains = (cents % 100).toString().padLeft(2, '0');
  return '\$$dollars.$remains';
}

String _catalogTabLabel(CatalogTab tab) {
  return switch (tab) {
    CatalogTab.featured => 'Featured',
    CatalogTab.studio => 'Studio',
    CatalogTab.essentials => 'Essentials',
  };
}

String _panelLabel(ProductPanel panel) {
  return switch (panel) {
    ProductPanel.overview => 'Overview',
    ProductPanel.specs => 'Specs',
    ProductPanel.reviews => 'Reviews',
  };
}

String _panelCopy(ProductPanel panel, ProductDetails product) {
  return switch (panel) {
    ProductPanel.overview => product.summary,
    ProductPanel.specs =>
      'Durability-focused materials and travel-ready geometry.',
    ProductPanel.reviews =>
      'Praised for low-noise profile and long-session comfort.',
  };
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class RootRoute extends AppRoute {
  const RootRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class DiscoverRoute extends AppRoute {
  const DiscoverRoute();

  @override
  Uri toUri() => Uri(path: '/discover');
}

final class CatalogRoute extends AppRoute {
  const CatalogRoute({required this.tab});

  final CatalogTab tab;

  @override
  Uri toUri() {
    final query = tab == CatalogTab.featured
        ? null
        : <String, String>{'tab': tab.name};
    return Uri(path: '/catalog', queryParameters: query);
  }
}

final class LegacyProductRoute extends AppRoute {
  const LegacyProductRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/p/$id');
}

final class ProductRoute extends AppRoute {
  const ProductRoute({required this.id, this.panel = ProductPanel.overview});

  final int id;
  final ProductPanel panel;

  @override
  Uri toUri() {
    final query = panel == ProductPanel.overview
        ? null
        : <String, String>{'panel': panel.name};
    return Uri(path: '/products/$id', queryParameters: query);
  }
}

final class QuantityRoute extends AppRoute {
  const QuantityRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/products/$id/quantity');
}

final class CartRoute extends AppRoute {
  const CartRoute();

  @override
  Uri toUri() => Uri(path: '/cart');
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
    final query = from == null ? null : <String, String>{'from': from!};
    return Uri(path: '/login', queryParameters: query);
  }
}

enum CatalogTab { featured, studio, essentials }

enum ProductPanel { overview, specs, reviews }

class ProductDetails {
  const ProductDetails({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.priceCents,
    required this.materials,
    required this.tabs,
  });

  final int id;
  final String title;
  final String subtitle;
  final String summary;
  final int priceCents;
  final List<String> materials;
  final Set<CatalogTab> tabs;
}

class CartLine {
  const CartLine({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPriceCents,
    required this.totalCents,
  });

  final int productId;
  final String title;
  final int quantity;
  final int unitPriceCents;
  final int totalCents;
}

class CartSummary {
  const CartSummary({
    required this.lines,
    required this.itemCount,
    required this.totalCents,
  });

  final List<CartLine> lines;
  final int itemCount;
  final int totalCents;
}

class CheckoutSummary {
  const CheckoutSummary({
    required this.itemCount,
    required this.totalCents,
    required this.etaMinutes,
  });

  final int itemCount;
  final int totalCents;
  final int etaMinutes;
}

class StoreSession extends ChangeNotifier {
  bool _signedIn = false;
  final Map<int, int> _cart = <int, int>{};
  String _status = 'Ready';

  bool get isSignedIn => _signedIn;
  int get itemCount => _cart.values.fold(0, (sum, qty) => sum + qty);
  String get status => _status;
  Iterable<MapEntry<int, int>> get cartEntries => _cart.entries;

  void reset() {
    _signedIn = false;
    _cart.clear();
    _status = 'Ready';
  }

  void toggleAuth() {
    _signedIn = !_signedIn;
    _status = _signedIn ? 'Session opened' : 'Session closed';
    notifyListeners();
  }

  void signIn() {
    if (_signedIn) {
      _status = 'Already signed in';
      notifyListeners();
      return;
    }
    _signedIn = true;
    _status = 'Authentication complete';
    notifyListeners();
  }

  void addItem(int productId, {required int qty}) {
    if (qty <= 0) {
      return;
    }

    _cart[productId] = (_cart[productId] ?? 0) + qty;
    final name = _catalog[productId]?.title ?? 'product $productId';
    _status = 'Added $qty × $name';
    notifyListeners();
  }

  void clearCart({required String reason}) {
    _cart.clear();
    _status = reason;
    notifyListeners();
  }

  void note(String message) {
    _status = message;
    notifyListeners();
  }
}

const Map<int, ProductDetails> _catalog = <int, ProductDetails>{
  201: ProductDetails(
    id: 201,
    title: 'Aster 65 Keyboard',
    subtitle: 'Compact tactile board',
    summary: 'Dense footprint with soft acoustic profile for focused sessions.',
    priceCents: 15900,
    materials: <String>['Aluminum shell', 'Poron layer', 'PBT caps'],
    tabs: <CatalogTab>{CatalogTab.featured, CatalogTab.studio},
  ),
  202: ProductDetails(
    id: 202,
    title: 'Monolith Desk Mat',
    subtitle: 'Large anti-slip textile',
    summary: 'Stable desk foundation tuned for low friction and clean routing.',
    priceCents: 4900,
    materials: <String>['Micro knit', 'Rubber base', 'Stitched edge'],
    tabs: <CatalogTab>{CatalogTab.featured, CatalogTab.essentials},
  ),
  203: ProductDetails(
    id: 203,
    title: 'Lumen Task Lamp',
    subtitle: 'Directional warm light',
    summary: 'Focused illumination with low glare for long-night editing.',
    priceCents: 12900,
    materials: <String>['Anodized arm', 'CRI95 LEDs', 'Touch dimmer'],
    tabs: <CatalogTab>{CatalogTab.studio, CatalogTab.essentials},
  ),
  204: ProductDetails(
    id: 204,
    title: 'Arc Cable Set',
    subtitle: 'Braided USB-C pair',
    summary: 'Utility cable set keeping desk travel loops minimal and clean.',
    priceCents: 2900,
    materials: <String>['Braided weave', 'Metal shell', 'Quick coupler'],
    tabs: <CatalogTab>{CatalogTab.featured, CatalogTab.essentials},
  ),
};
