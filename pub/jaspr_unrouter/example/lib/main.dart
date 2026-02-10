import 'dart:async';

import 'package:jaspr/dom.dart' as dom;
import 'package:jaspr/server.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart';

final StoreSession _session = StoreSession();

final Unrouter<AppRoute> _router = _createRouter();

final List<dom.StyleRule> _styles = <dom.StyleRule>[
  dom.css('*').styles(raw: <String, String>{'box-sizing': 'border-box'}),
  dom
      .css('html, body')
      .styles(
        raw: <String, String>{
          'margin': '0',
          'padding': '0',
          'min-height': '100%',
        },
      ),
  dom
      .css('body')
      .styles(
        raw: <String, String>{
          'font-family': '"Avenir Next", "Segoe UI", sans-serif',
          'background': 'linear-gradient(180deg, #f7f2e8 0%, #ece6dc 100%)',
          'color': '#102343',
          'line-height': '1.45',
        },
      ),
  dom.css('a').styles(raw: <String, String>{'text-decoration': 'none'}),
  dom
      .css('.shell-root')
      .styles(
        raw: <String, String>{
          'max-width': '1080px',
          'margin': '0 auto',
          'padding': '24px 16px 40px',
          'display': 'grid',
          'gap': '14px',
        },
      ),
  dom
      .css('.topbar')
      .styles(
        raw: <String, String>{
          'padding': '18px 20px',
          'border-radius': '18px',
          'background': 'linear-gradient(125deg, #0d244f 0%, #17489f 100%)',
          'box-shadow': '0 16px 44px rgba(12, 33, 75, 0.32)',
          'color': '#f6f8ff',
          'display': 'grid',
          'gap': '12px',
        },
      ),
  dom
      .css('.topbar-row')
      .styles(
        raw: <String, String>{
          'display': 'flex',
          'align-items': 'center',
          'justify-content': 'space-between',
          'flex-wrap': 'wrap',
          'gap': '10px',
        },
      ),
  dom
      .css('.brand')
      .styles(
        raw: <String, String>{
          'font-size': '1.2rem',
          'font-weight': '700',
          'letter-spacing': '0.2px',
        },
      ),
  dom
      .css('.uri-chip')
      .styles(
        raw: <String, String>{
          'padding': '5px 10px',
          'border-radius': '999px',
          'background': 'rgba(197, 219, 255, 0.22)',
          'font-size': '0.78rem',
          'letter-spacing': '0.4px',
          'color': '#d9e6ff',
          'word-break': 'break-all',
        },
      ),
  dom
      .css('.chip-row')
      .styles(
        raw: <String, String>{
          'display': 'flex',
          'align-items': 'center',
          'gap': '8px',
          'flex-wrap': 'wrap',
        },
      ),
  dom
      .css('.chip')
      .styles(
        raw: <String, String>{
          'padding': '8px 12px',
          'border-radius': '999px',
          'border': '1px solid #89a9ea',
          'background': '#f4f7ff',
          'color': '#1a3270',
          'font-size': '0.84rem',
          'font-weight': '600',
          'cursor': 'pointer',
          'display': 'inline-flex',
          'align-items': 'center',
          'justify-content': 'center',
        },
      ),
  dom
      .css('.chip-active')
      .styles(
        raw: <String, String>{
          'border-color': '#a9c4ff',
          'background': 'linear-gradient(120deg, #1f56b5, #2c74de)',
          'color': '#ffffff',
        },
      ),
  dom
      .css('.chip-ghost')
      .styles(
        raw: <String, String>{
          'border-color': '#9ab3e3',
          'background': 'transparent',
          'color': '#e6eeff',
        },
      ),
  dom
      .css('.surface')
      .styles(
        raw: <String, String>{
          'background': 'rgba(255, 255, 255, 0.8)',
          'border': '1px solid rgba(160, 181, 216, 0.45)',
          'border-radius': '18px',
          'padding': '16px',
          'box-shadow': '0 8px 28px rgba(17, 35, 67, 0.08)',
        },
      ),
  dom
      .css('.status-row')
      .styles(
        raw: <String, String>{
          'display': 'flex',
          'align-items': 'center',
          'gap': '8px',
          'flex-wrap': 'wrap',
        },
      ),
  dom
      .css('.status-pill')
      .styles(
        raw: <String, String>{
          'padding': '6px 10px',
          'border-radius': '999px',
          'font-size': '0.77rem',
          'font-weight': '600',
        },
      ),
  dom
      .css('.status-warm')
      .styles(
        raw: <String, String>{'background': '#ffe5d9', 'color': '#7f3314'},
      ),
  dom
      .css('.status-cool')
      .styles(
        raw: <String, String>{'background': '#d7f5e8', 'color': '#14583c'},
      ),
  dom
      .css('.status-note')
      .styles(
        raw: <String, String>{
          'background': '#e9edf5',
          'color': '#314a76',
          'font-weight': '500',
        },
      ),
  dom
      .css('.page')
      .styles(raw: <String, String>{'display': 'grid', 'gap': '12px'}),
  dom
      .css('.hero')
      .styles(
        raw: <String, String>{
          'padding': '16px',
          'border-radius': '16px',
          'background': 'linear-gradient(120deg, #fdf4db, #f4ecda)',
          'border': '1px solid #e4d8be',
          'display': 'grid',
          'gap': '10px',
        },
      ),
  dom
      .css('.hero-grid')
      .styles(
        raw: <String, String>{
          'display': 'grid',
          'grid-template-columns': 'repeat(auto-fit, minmax(210px, 1fr))',
          'gap': '10px',
        },
      ),
  dom
      .css('.card-grid')
      .styles(
        raw: <String, String>{
          'display': 'grid',
          'grid-template-columns': 'repeat(auto-fit, minmax(220px, 1fr))',
          'gap': '10px',
        },
      ),
  dom
      .css('.card')
      .styles(
        raw: <String, String>{
          'padding': '12px',
          'border-radius': '14px',
          'border': '1px solid #d8e0ee',
          'background': '#ffffff',
          'display': 'grid',
          'gap': '9px',
        },
      ),
  dom
      .css('.title')
      .styles(
        raw: <String, String>{
          'margin': '0',
          'font-size': '1.08rem',
          'font-weight': '700',
          'letter-spacing': '0.2px',
        },
      ),
  dom
      .css('.subtitle')
      .styles(
        raw: <String, String>{
          'margin': '0',
          'color': '#5f7092',
          'font-size': '0.92rem',
        },
      ),
  dom
      .css('.price')
      .styles(
        raw: <String, String>{
          'font-size': '1.12rem',
          'font-weight': '700',
          'color': '#15438f',
        },
      ),
  dom
      .css('.meta-list')
      .styles(
        raw: <String, String>{
          'margin': '0',
          'padding-left': '18px',
          'color': '#3d527b',
          'display': 'grid',
          'gap': '3px',
          'font-size': '0.88rem',
        },
      ),
  dom
      .css('.btn')
      .styles(
        raw: <String, String>{
          'padding': '9px 12px',
          'border-radius': '10px',
          'border': '1px solid #92aae0',
          'background': '#f4f8ff',
          'color': '#193672',
          'cursor': 'pointer',
          'font-weight': '600',
          'font-size': '0.84rem',
          'display': 'inline-flex',
          'align-items': 'center',
          'justify-content': 'center',
          'gap': '6px',
        },
      ),
  dom
      .css('.btn-primary')
      .styles(
        raw: <String, String>{
          'border-color': '#2d6cdb',
          'background': 'linear-gradient(120deg, #205abf, #2d74dd)',
          'color': '#ffffff',
        },
      ),
  dom
      .css('.btn-danger')
      .styles(
        raw: <String, String>{
          'border-color': '#cd7d68',
          'background': '#fff2ec',
          'color': '#8d3e2c',
        },
      ),
  dom
      .css('.btn-row')
      .styles(
        raw: <String, String>{
          'display': 'flex',
          'gap': '8px',
          'flex-wrap': 'wrap',
          'align-items': 'center',
        },
      ),
  dom
      .css('.line-item')
      .styles(
        raw: <String, String>{
          'display': 'grid',
          'grid-template-columns': '1fr auto',
          'gap': '8px',
          'padding': '10px',
          'border': '1px dashed #c5d2ea',
          'border-radius': '12px',
          'background': '#f8fbff',
        },
      ),
  dom
      .css('.fallback')
      .styles(
        raw: <String, String>{
          'padding': '18px',
          'border-radius': '14px',
          'background': '#fff',
          'border': '1px solid #d3ddec',
          'display': 'grid',
          'gap': '8px',
        },
      ),
  dom
      .css('.hint')
      .styles(
        raw: <String, String>{
          'font-size': '0.8rem',
          'color': '#60739a',
          'margin': '0',
        },
      ),
];

void main() {
  Jaspr.initializeApp();
  _session.reset();

  runApp(
    Document(
      title: 'Atelier Commerce - jaspr_unrouter',
      meta: const <String, String>{
        'description':
            'Complete jaspr_unrouter demo with shell, guards and data routes.',
      },
      styles: _styles,
      body: const StorefrontApp(),
    ),
  );
}

class StorefrontApp extends StatelessComponent {
  const StorefrontApp({super.key});

  @override
  Component build(BuildContext context) {
    return _router;
  }
}

Unrouter<AppRoute> _createRouter() {
  return Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<RootRoute>(
        path: '/',
        parse: (_) => const RootRoute(),
        redirect: (_) => const DiscoverRoute().toUri(),
        builder: (_, __) => const Component.empty(),
      ),
      ...shell<AppRoute>(
        builder: (_, shellState, child) {
          return ShellChrome(shellState: shellState, child: child);
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
                loader: _loadCart,
                builder: (_, route, data) => CartPage(route: route, data: data),
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
                loader: _loadCheckout,
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
    unknown: (_, uri) {
      return FallbackPage(
        title: 'Route not found',
        detail: 'No route matches "${uri.path}".',
      );
    },
    blocked: (_, uri) {
      return FallbackPage(
        title: 'Route blocked by guard',
        detail: 'Access to "${uri.path}" is currently blocked.',
      );
    },
    loading: (_, uri) {
      return FallbackPage(
        title: 'Resolving route',
        detail: 'Loading ${uri.path} ...',
      );
    },
    onError: (_, error, __) {
      return FallbackPage(
        title: 'Route resolution error',
        detail: error.toString(),
      );
    },
  );
}

class ShellChrome extends StatelessComponent {
  const ShellChrome({super.key, required this.shellState, required this.child});

  final ShellState<AppRoute> shellState;
  final Component child;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return ListenableBuilder(
      listenable: _session,
      builder: (context) {
        return dom.div(<Component>[
          dom.header(<Component>[
            dom.div(<Component>[
              dom.div(<Component>[
                Component.text('Atelier Commerce'),
              ], classes: 'brand'),
              dom.div(<Component>[
                Component.text(controller.state.uri.toString()),
              ], classes: 'uri-chip'),
            ], classes: 'topbar-row'),
            dom.div(<Component>[
              _chipButton(
                label: 'Explore',
                active: shellState.activeBranchIndex == 0,
                onClick: () => shellState.goBranch(0),
              ),
              _chipButton(
                label: 'Wallet',
                active: shellState.activeBranchIndex == 1,
                onClick: () => shellState.goBranch(1),
              ),
              _chipButton(
                label: _session.isSignedIn ? 'Sign out' : 'Sign in',
                ghost: true,
                onClick: _session.toggleAuth,
              ),
            ], classes: 'chip-row'),
            dom.div(<Component>[
              _statusPill('Items ${_session.itemCount}', warm: false),
              _statusPill(
                _session.isSignedIn ? 'Signed in' : 'Guest mode',
                warm: !_session.isSignedIn,
              ),
              _statusPill(_session.status, warm: false, note: true),
            ], classes: 'status-row'),
          ], classes: 'topbar'),
          dom.main_(<Component>[child], classes: 'surface'),
          dom.p(<Component>[
            Component.text(
              'Demo coverage: shell branches, redirects, guard block, data loader, typed push/pop result.',
            ),
          ], classes: 'hint'),
        ], classes: 'shell-root');
      },
    );
  }
}

class DiscoverPage extends StatelessComponent {
  const DiscoverPage({super.key});

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    final featured = _productsByTab(CatalogTab.featured);

    return dom.section(<Component>[
      dom.div(<Component>[
        dom.h2(<Component>[
          Component.text('Season Open: studio pieces'),
        ], classes: 'title'),
        dom.p(<Component>[
          Component.text(
            'A calm storefront shell that keeps navigation declarative and typed across screens.',
          ),
        ], classes: 'subtitle'),
        dom.div(<Component>[
          _button(
            label: 'Browse catalog',
            primary: true,
            onClick: () {
              controller.go(const CatalogRoute(tab: CatalogTab.studio));
            },
          ),
          _button(
            label: 'Open legacy /p/102',
            onClick: () {
              controller.go(const LegacyProductRoute(id: 102));
            },
          ),
          _button(
            label: 'Go to cart',
            onClick: () {
              controller.go(const CartRoute());
            },
          ),
        ], classes: 'btn-row'),
      ], classes: 'hero'),
      dom.div(<Component>[
        for (final product in featured)
          dom.article(<Component>[
            dom.h3(<Component>[
              Component.text(product.title),
            ], classes: 'title'),
            dom.p(<Component>[
              Component.text(product.subtitle),
            ], classes: 'subtitle'),
            dom.div(<Component>[
              Component.text(_usd(product.priceCents)),
            ], classes: 'price'),
            UnrouterLink<AppRoute>(
              route: ProductRoute(id: product.id),
              classes: 'btn btn-primary',
              children: <Component>[Component.text('Open product')],
            ),
          ], classes: 'card'),
      ], classes: 'card-grid'),
    ], classes: 'page');
  }
}

class CatalogPage extends StatelessComponent {
  const CatalogPage({super.key, required this.route});

  final CatalogRoute route;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    final products = _productsByTab(route.tab);

    return dom.section(<Component>[
      dom.div(<Component>[
        dom.h2(<Component>[
          Component.text('Catalog · ${_catalogTabLabel(route.tab)}'),
        ], classes: 'title'),
        dom.p(<Component>[
          Component.text(
            'Query-driven tab parsing keeps URLs explicit and portable.',
          ),
        ], classes: 'subtitle'),
        dom.div(<Component>[
          for (final tab in CatalogTab.values)
            _chipButton(
              label: _catalogTabLabel(tab),
              active: route.tab == tab,
              onClick: () {
                controller.go(CatalogRoute(tab: tab));
              },
            ),
        ], classes: 'chip-row'),
      ], classes: 'hero'),
      dom.div(<Component>[
        for (final product in products)
          dom.article(<Component>[
            dom.h3(<Component>[
              Component.text(product.title),
            ], classes: 'title'),
            dom.p(<Component>[
              Component.text(product.summary),
            ], classes: 'subtitle'),
            dom.div(<Component>[
              Component.text(_usd(product.priceCents)),
            ], classes: 'price'),
            dom.div(<Component>[
              UnrouterLink<AppRoute>(
                route: ProductRoute(id: product.id),
                classes: 'btn btn-primary',
                children: <Component>[Component.text('Details')],
              ),
              UnrouterLink<AppRoute>(
                route: ProductRoute(id: product.id, panel: ProductPanel.specs),
                classes: 'btn',
                children: <Component>[Component.text('Specs')],
              ),
            ], classes: 'btn-row'),
          ], classes: 'card'),
      ], classes: 'card-grid'),
    ], classes: 'page');
  }
}

class LegacyRedirectPage extends StatelessComponent {
  const LegacyRedirectPage({super.key, required this.route});

  final LegacyProductRoute route;

  @override
  Component build(BuildContext context) {
    return FallbackPage(
      title: 'Legacy route',
      detail: 'Redirecting from /p/${route.id} ...',
    );
  }
}

class ProductPage extends StatelessComponent {
  const ProductPage({super.key, required this.route, required this.data});

  final ProductRoute route;
  final ProductDetails data;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return dom.section(<Component>[
      dom.div(<Component>[
        dom.h2(<Component>[Component.text(data.title)], classes: 'title'),
        dom.p(<Component>[Component.text(data.subtitle)], classes: 'subtitle'),
        dom.div(<Component>[
          Component.text(_usd(data.priceCents)),
        ], classes: 'price'),
        dom.div(<Component>[
          for (final panel in ProductPanel.values)
            _chipButton(
              label: _panelLabel(panel),
              active: route.panel == panel,
              onClick: () {
                controller.go(ProductRoute(id: route.id, panel: panel));
              },
            ),
        ], classes: 'chip-row'),
      ], classes: 'hero'),
      dom.div(<Component>[
        dom.article(<Component>[
          dom.h3(<Component>[
            Component.text('Panel · ${_panelLabel(route.panel)}'),
          ], classes: 'title'),
          dom.p(<Component>[
            Component.text(_panelCopy(route.panel, data)),
          ], classes: 'subtitle'),
          dom.ul(<Component>[
            for (final item in data.materials)
              dom.li(<Component>[Component.text(item)]),
          ], classes: 'meta-list'),
        ], classes: 'card'),
        dom.article(<Component>[
          dom.h3(<Component>[Component.text('Actions')], classes: 'title'),
          dom.p(<Component>[
            Component.text(
              'Use push/pop result to choose quantity and complete cart updates.',
            ),
          ], classes: 'subtitle'),
          dom.div(<Component>[
            _button(
              label: 'Add one',
              primary: true,
              onClick: () {
                _session.addItem(route.id, qty: 1);
                controller.go(const CartRoute());
              },
            ),
            _button(
              label: 'Choose quantity',
              onClick: () {
                unawaited(
                  controller.push<int>(QuantityRoute(id: route.id)).then((qty) {
                    if (qty == null) {
                      _session.note('Quantity chooser cancelled');
                      return;
                    }
                    _session.addItem(route.id, qty: qty);
                    controller.go(const CartRoute());
                  }),
                );
              },
            ),
            _button(
              label: 'Back to catalog',
              onClick: () {
                controller.go(const CatalogRoute(tab: CatalogTab.featured));
              },
            ),
          ], classes: 'btn-row'),
        ], classes: 'card'),
      ], classes: 'hero-grid'),
    ], classes: 'page');
  }
}

class QuantityPickerPage extends StatelessComponent {
  const QuantityPickerPage({super.key, required this.route});

  final QuantityRoute route;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    final title = _catalog[route.id]?.title ?? 'Product ${route.id}';

    return dom.section(<Component>[
      dom.article(<Component>[
        dom.h2(<Component>[
          Component.text('Choose quantity'),
        ], classes: 'title'),
        dom.p(<Component>[Component.text(title)], classes: 'subtitle'),
        dom.div(<Component>[
          for (var amount = 1; amount <= 4; amount++)
            _button(
              label: '$amount ×',
              primary: amount == 2,
              onClick: () {
                controller.pop<int>(amount);
              },
            ),
          _button(label: 'Cancel', danger: true, onClick: controller.back),
        ], classes: 'btn-row'),
      ], classes: 'card'),
    ], classes: 'page');
  }
}

class CartPage extends StatelessComponent {
  const CartPage({super.key, required this.route, required this.data});

  final CartRoute route;
  final CartSummary data;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    route;

    return dom.section(<Component>[
      dom.div(<Component>[
        dom.h2(<Component>[Component.text('Cart')], classes: 'title'),
        dom.p(<Component>[
          Component.text('Loader-backed summary for current line items.'),
        ], classes: 'subtitle'),
        dom.div(<Component>[
          _statusPill('Lines ${data.lines.length}', warm: false),
          _statusPill('Items ${data.itemCount}', warm: false),
          _statusPill('Total ${_usd(data.totalCents)}', warm: false),
        ], classes: 'status-row'),
      ], classes: 'hero'),
      if (data.lines.isEmpty)
        dom.article(<Component>[
          dom.h3(<Component>[
            Component.text('Cart is empty'),
          ], classes: 'title'),
          dom.p(<Component>[
            Component.text(
              'Add something from Explore to test checkout guards.',
            ),
          ], classes: 'subtitle'),
          _button(
            label: 'Browse catalog',
            primary: true,
            onClick: () {
              controller.go(const CatalogRoute(tab: CatalogTab.featured));
            },
          ),
        ], classes: 'card')
      else
        dom.div(<Component>[
          for (final line in data.lines)
            dom.div(<Component>[
              dom.div(<Component>[
                dom.p(<Component>[
                  Component.text(line.title),
                ], classes: 'title'),
                dom.p(<Component>[
                  Component.text(
                    '${line.quantity} × ${_usd(line.unitPriceCents)}',
                  ),
                ], classes: 'subtitle'),
              ]),
              dom.div(<Component>[
                Component.text(_usd(line.totalCents)),
              ], classes: 'price'),
            ], classes: 'line-item'),
        ], classes: 'page'),
      dom.div(<Component>[
        _button(
          label: 'Checkout',
          primary: true,
          onClick: () {
            controller.go(const CheckoutRoute());
          },
        ),
        _button(
          label: 'Clear cart',
          danger: true,
          onClick: () {
            _session.clearCart(reason: 'Cart cleared from wallet view');
            controller.go(const CartRoute());
          },
        ),
      ], classes: 'btn-row'),
    ], classes: 'page');
  }
}

class CheckoutPage extends StatelessComponent {
  const CheckoutPage({super.key, required this.data});

  final CheckoutSummary data;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return dom.section(<Component>[
      dom.article(<Component>[
        dom.h2(<Component>[Component.text('Checkout')], classes: 'title'),
        dom.p(<Component>[
          Component.text(
            'Guard requires both authentication and a non-empty cart.',
          ),
        ], classes: 'subtitle'),
        dom.div(<Component>[
          _statusPill('${data.itemCount} items', warm: false),
          _statusPill('ETA ${data.etaMinutes} min', warm: false),
          _statusPill(_usd(data.totalCents), warm: false),
        ], classes: 'status-row'),
        dom.div(<Component>[
          _button(
            label: 'Pay now',
            primary: true,
            onClick: () {
              _session.clearCart(reason: 'Order confirmed. Payment captured.');
              controller.go(const DiscoverRoute());
            },
          ),
          _button(
            label: 'Back to cart',
            onClick: () {
              controller.go(const CartRoute());
            },
          ),
        ], classes: 'btn-row'),
      ], classes: 'card'),
    ], classes: 'page');
  }
}

class LoginPage extends StatelessComponent {
  const LoginPage({super.key, required this.route});

  final LoginRoute route;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();
    final target = route.from == null
        ? const CartRoute().toUri()
        : (Uri.tryParse(route.from!) ?? const CartRoute().toUri());

    return dom.section(<Component>[
      dom.article(<Component>[
        dom.h2(<Component>[
          Component.text('Sign in required'),
        ], classes: 'title'),
        dom.p(<Component>[
          Component.text(
            'Checkout is protected. Sign in to continue your route.',
          ),
        ], classes: 'subtitle'),
        dom.p(<Component>[
          Component.text('Return target: ${target.toString()}'),
        ], classes: 'hint'),
        dom.div(<Component>[
          _button(
            label: 'Sign in and continue',
            primary: true,
            onClick: () {
              _session.signIn();
              controller.goUri(target);
            },
          ),
          _button(
            label: 'Back to explore',
            onClick: () {
              controller.go(const DiscoverRoute());
            },
          ),
        ], classes: 'btn-row'),
      ], classes: 'card'),
    ], classes: 'page');
  }
}

class FallbackPage extends StatelessComponent {
  const FallbackPage({super.key, required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<AppRoute>();

    return dom.section(<Component>[
      dom.article(<Component>[
        dom.h2(<Component>[Component.text(title)], classes: 'title'),
        dom.p(<Component>[Component.text(detail)], classes: 'subtitle'),
        _button(
          label: 'Go to discover',
          primary: true,
          onClick: () {
            controller.go(const DiscoverRoute());
          },
        ),
      ], classes: 'fallback'),
    ], classes: 'page');
  }
}

Component _statusPill(String label, {required bool warm, bool note = false}) {
  final classes = StringBuffer('status-pill');
  if (note) {
    classes.write(' status-note');
  } else if (warm) {
    classes.write(' status-warm');
  } else {
    classes.write(' status-cool');
  }

  return dom.span(<Component>[
    Component.text(label),
  ], classes: classes.toString());
}

Component _chipButton({
  required String label,
  required VoidCallback onClick,
  bool active = false,
  bool ghost = false,
}) {
  final classes = StringBuffer('chip');
  if (active) {
    classes.write(' chip-active');
  }
  if (ghost) {
    classes.write(' chip-ghost');
  }

  return dom.button(
    <Component>[Component.text(label)],
    type: dom.ButtonType.button,
    classes: classes.toString(),
    onClick: onClick,
  );
}

Component _button({
  required String label,
  required VoidCallback onClick,
  bool primary = false,
  bool danger = false,
}) {
  final classes = StringBuffer('btn');
  if (primary) {
    classes.write(' btn-primary');
  }
  if (danger) {
    classes.write(' btn-danger');
  }

  return dom.button(
    <Component>[Component.text(label)],
    type: dom.ButtonType.button,
    classes: classes.toString(),
    onClick: onClick,
  );
}

Future<ProductDetails> _loadProduct(RouteContext<ProductRoute> context) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));

  final product = _catalog[context.route.id];
  if (product == null) {
    throw StateError('Product ${context.route.id} does not exist.');
  }
  return product;
}

Future<CartSummary> _loadCart(RouteContext<CartRoute> context) async {
  context.signal.throwIfCancelled();
  await Future<void>.delayed(const Duration(milliseconds: 90));
  context.signal.throwIfCancelled();

  final lines = <CartLine>[];
  var totalCents = 0;
  var totalItems = 0;

  for (final entry in _session.cartEntries) {
    final product = _catalog[entry.key];
    if (product == null) {
      continue;
    }
    final quantity = entry.value;
    final lineTotal = product.priceCents * quantity;
    lines.add(
      CartLine(
        productId: product.id,
        title: product.title,
        quantity: quantity,
        unitPriceCents: product.priceCents,
        totalCents: lineTotal,
      ),
    );
    totalItems += quantity;
    totalCents += lineTotal;
  }

  return CartSummary(
    lines: lines,
    itemCount: totalItems,
    totalCents: totalCents,
  );
}

Future<CheckoutSummary> _loadCheckout(
  RouteContext<CheckoutRoute> context,
) async {
  context.signal.throwIfCancelled();
  await Future<void>.delayed(const Duration(milliseconds: 110));
  context.signal.throwIfCancelled();

  var totalCents = 0;
  var itemCount = 0;
  for (final entry in _session.cartEntries) {
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
    etaMinutes: 12 + itemCount * 2,
  );
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
      'Craft profile tuned for durability and daily ergonomics.',
    ProductPanel.reviews =>
      'Loved by operators who prefer tactile feedback with calm acoustics.',
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
    _status = _signedIn ? 'Signed in for checkout' : 'Signed out to guest mode';
    notifyListeners();
  }

  void signIn() {
    if (_signedIn) {
      _status = 'Already signed in';
      notifyListeners();
      return;
    }
    _signedIn = true;
    _status = 'Sign-in complete';
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
  101: ProductDetails(
    id: 101,
    title: 'Aster 65 Keyboard',
    subtitle: 'Compact aluminum frame, warm tactility',
    summary:
        'A compact board tuned for low-noise tactile response and dense desk setups.',
    priceCents: 15900,
    materials: <String>[
      'CNC aluminum chassis',
      'Poron dampening',
      'PBT keycaps',
    ],
    tabs: <CatalogTab>{CatalogTab.featured, CatalogTab.studio},
  ),
  102: ProductDetails(
    id: 102,
    title: 'Monolith Desk Mat',
    subtitle: 'Textile weave with anti-slip underside',
    summary:
        'Wide desk coverage with muted texture designed for sustained writing sessions.',
    priceCents: 4900,
    materials: <String>[
      'Micro-knit textile',
      'Natural rubber base',
      'Stitched edge',
    ],
    tabs: <CatalogTab>{CatalogTab.featured, CatalogTab.essentials},
  ),
  103: ProductDetails(
    id: 103,
    title: 'Lumen Task Lamp',
    subtitle: 'Dimmable light profile for focus zones',
    summary:
        'Directional lighting with soft diffusion, optimized for long evening workflows.',
    priceCents: 12900,
    materials: <String>[
      'Anodized armature',
      'CRI 95 LED module',
      'Touch dimmer',
    ],
    tabs: <CatalogTab>{CatalogTab.studio, CatalogTab.essentials},
  ),
  104: ProductDetails(
    id: 104,
    title: 'Arc Cable Set',
    subtitle: 'Braided USB-C pair in studio palette',
    summary:
        'Color-matched cable duo to keep routing clean across keyboard and tablet.',
    priceCents: 2900,
    materials: <String>[
      'Braided sleeve',
      'Aluminum connector shell',
      'Detachable coupler',
    ],
    tabs: <CatalogTab>{CatalogTab.essentials, CatalogTab.featured},
  ),
};
