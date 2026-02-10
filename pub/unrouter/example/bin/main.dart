// ignore_for_file: avoid_print

import 'dart:async';

import 'package:unrouter/unrouter.dart';

Future<void> main() async {
  final ui = DemoConsole();
  final session = DemoSession();
  final diagnostics = <RedirectDiagnostics>[];

  final router = _createRouter(session: session, diagnostics: diagnostics);
  final controller = UnrouterController<AppRoute>(
    router: router,
    resolveInitialRoute: false,
  );
  final stateSub = controller.states.listen(ui.printState);

  ui.banner('unrouter core - pure dart complete example');

  try {
    await _runScenario(
      ui: ui,
      controller: controller,
      session: session,
      diagnostics: diagnostics,
    );
  } finally {
    await stateSub.cancel();
    controller.dispose();
  }

  ui.section('done');
  ui.item('status', 'example completed');
}

Future<void> _runScenario({
  required DemoConsole ui,
  required UnrouterController<AppRoute> controller,
  required DemoSession session,
  required List<RedirectDiagnostics> diagnostics,
}) async {
  ui.section('1) bootstrap with sync');
  await controller.sync(
    Uri(path: '/', queryParameters: <String, String>{'utm': 'example'}),
  );
  await controller.idle;
  ui.item('current uri', controller.uri);

  ui.section('2) typed query parsing');
  controller.go(
    const SearchRoute(
      query: 'mechanical keyboard',
      sort: SortOrder.priceLowToHigh,
      page: 2,
    ),
  );
  await controller.idle;
  final search = controller.route;
  if (search is SearchRoute) {
    ui.item('search.query', search.query);
    ui.item('search.sort', search.sort.name);
    ui.item('search.page', search.page);
  }

  ui.section('3) route redirect + data loader');
  final pushed = controller.push<String>(const LegacyProductRoute(id: 42));
  await controller.idle;
  final route = controller.route;
  if (route is ProductRoute) {
    ui.item('redirected route', route.runtimeType);
    ui.item('product.id', route.id);
    ui.item('product.tab', route.tab.name);
  }
  final loaded = controller.resolution.loaderData;
  if (loaded is ProductData) {
    ui.item(
      'loader data',
      '${loaded.title} | ${_formatUsd(loaded.priceCents)}',
    );
  }
  session.addToCart(42);
  controller.pop('added-to-cart');
  final pushResult = await pushed;
  ui.item('push/pop typed result', pushResult ?? 'null');

  ui.section('4) guard redirect (checkout requires auth)');
  controller.go(const CheckoutRoute());
  await controller.idle;
  final login = controller.route;
  if (login is LoginRoute) {
    ui.item('redirected to', '/login');
    ui.item('login.from', login.from ?? '-');
  }

  ui.section('5) login and continue');
  session.signIn();
  session.addToCart(7);
  controller.go(const HomeRoute());
  await controller.idle;
  controller.go(const CheckoutRoute());
  await controller.idle;
  ui.item('post-login uri', controller.uri);
  final checkout = controller.resolution.loaderData;
  if (checkout is CheckoutSummary) {
    ui.item('checkout.items', checkout.itemCount);
    ui.item('checkout.total', _formatUsd(checkout.totalCents));
  }

  ui.section('6) blocked route fallback');
  final before = controller.uri;
  controller.go(const BetaRoute());
  await controller.idle;
  ui.item('requested', '/beta');
  ui.item('actual uri', controller.uri);
  ui.item('fallback kept previous route', before == controller.uri);

  ui.section('7) unmatched route');
  await controller.sync(Uri(path: '/missing'));
  await controller.idle;
  ui.item('resolution', controller.state.resolution.name);

  ui.section('8) href + cast');
  final href = controller.href(
    const ProductRoute(id: 7, tab: ProductTab.reviews),
  );
  ui.item('href(product#7)', href);
  final casted = controller.cast<RouteData>();
  ui.item('cast uri matches', casted.uri == controller.uri);

  ui.section('9) redirect loop diagnostics');
  controller.go(const LoopARoute());
  await controller.idle;
  ui.item('loop resolution', controller.state.resolution.name);
  if (controller.state.hasError) {
    ui.item('loop error', controller.state.error ?? '-');
  }
  if (diagnostics.isNotEmpty) {
    final last = diagnostics.last;
    ui.item('diagnostic.reason', last.reason.name);
    ui.item('diagnostic.hops', '${last.hop}/${last.maxHops}');
    ui.item('diagnostic.trail', last.trail.map((uri) => uri.path).join(' -> '));
  }
}

Unrouter<AppRoute> _createRouter({
  required DemoSession session,
  required List<RedirectDiagnostics> diagnostics,
}) {
  return Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<RootRoute>(
        path: '/',
        parse: (_) => const RootRoute(),
        redirect: (_) => const HomeRoute().toUri(),
      ),
      route<HomeRoute>(path: '/home', parse: (_) => const HomeRoute()),
      route<SearchRoute>(
        path: '/search',
        parse: (state) {
          final query = state.query.required('q');
          final sort = state.query.containsKey('sort')
              ? state.query.$enum('sort', SortOrder.values)
              : SortOrder.relevance;
          final page = state.query.containsKey('page')
              ? state.query.$int('page')
              : 1;
          return SearchRoute(query: query, sort: sort, page: page);
        },
      ),
      route<LegacyProductRoute>(
        path: '/p/:id',
        parse: (state) => LegacyProductRoute(id: state.params.$int('id')),
        redirect: (context) {
          return ProductRoute(id: context.route.id).toUri();
        },
      ),
      dataRoute<ProductRoute, ProductData>(
        path: '/products/:id',
        parse: (state) {
          final tab = state.query.containsKey('tab')
              ? state.query.$enum('tab', ProductTab.values)
              : ProductTab.overview;
          return ProductRoute(id: state.params.$int('id'), tab: tab);
        },
        loader: (context) => _loadProduct(context.route),
      ),
      route<LoginRoute>(
        path: '/login',
        parse: (state) => LoginRoute(from: state.query['from']),
      ),
      dataRoute<CheckoutRoute, CheckoutSummary>(
        path: '/checkout',
        parse: (_) => const CheckoutRoute(),
        guards: <RouteGuard<CheckoutRoute>>[
          (context) {
            if (!session.isSignedIn) {
              return RouteGuardResult.redirect(
                route: LoginRoute(from: context.uri.toString()),
              );
            }
            if (session.cartProductIds.isEmpty) {
              return const RouteGuardResult.block();
            }
            return const RouteGuardResult.allow();
          },
        ],
        loader: (context) =>
            _loadCheckout(route: context.route, session: session),
      ),
      route<BetaRoute>(
        path: '/beta',
        parse: (_) => const BetaRoute(),
        guards: <RouteGuard<BetaRoute>>[(_) => const RouteGuardResult.block()],
      ),
      route<LoopARoute>(
        path: '/loop-a',
        parse: (_) => const LoopARoute(),
        redirect: (_) => const LoopBRoute().toUri(),
      ),
      route<LoopBRoute>(
        path: '/loop-b',
        parse: (_) => const LoopBRoute(),
        redirect: (_) => const LoopARoute().toUri(),
      ),
    ],
    maxRedirectHops: 8,
    redirectLoopPolicy: RedirectLoopPolicy.error,
    onRedirectDiagnostics: diagnostics.add,
  );
}

Future<ProductData> _loadProduct(ProductRoute route) async {
  await Future<void>.delayed(const Duration(milliseconds: 80));
  final product = _catalog[route.id];
  if (product == null) {
    throw StateError('Product "${route.id}" was not found.');
  }
  return product;
}

Future<CheckoutSummary> _loadCheckout({
  required CheckoutRoute route,
  required DemoSession session,
}) async {
  route;
  await Future<void>.delayed(const Duration(milliseconds: 60));

  var totalCents = 0;
  for (final id in session.cartProductIds) {
    totalCents += _catalog[id]?.priceCents ?? 0;
  }
  return CheckoutSummary(
    itemCount: session.cartProductIds.length,
    totalCents: totalCents,
  );
}

String _formatUsd(int cents) {
  final dollars = cents ~/ 100;
  final remains = (cents % 100).toString().padLeft(2, '0');
  return '\$$dollars.$remains';
}

final Map<int, ProductData> _catalog = <int, ProductData>{
  7: const ProductData(
    id: 7,
    title: 'Alice keyboard switch set',
    priceCents: 5900,
  ),
  42: const ProductData(id: 42, title: 'Nebula 75 keyboard', priceCents: 12900),
};

enum SortOrder { relevance, priceLowToHigh, newest }

enum ProductTab { overview, specs, reviews }

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class RootRoute extends AppRoute {
  const RootRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/home');
}

final class SearchRoute extends AppRoute {
  const SearchRoute({
    required this.query,
    this.sort = SortOrder.relevance,
    this.page = 1,
  });

  final String query;
  final SortOrder sort;
  final int page;

  @override
  Uri toUri() {
    return Uri(
      path: '/search',
      queryParameters: <String, String>{
        'q': query,
        'sort': sort.name,
        'page': page.toString(),
      },
    );
  }
}

final class LegacyProductRoute extends AppRoute {
  const LegacyProductRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/p/$id');
}

final class ProductRoute extends AppRoute {
  const ProductRoute({required this.id, this.tab = ProductTab.overview});

  final int id;
  final ProductTab tab;

  @override
  Uri toUri() {
    return Uri(
      path: '/products/$id',
      queryParameters: <String, String>{'tab': tab.name},
    );
  }
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

final class CheckoutRoute extends AppRoute {
  const CheckoutRoute();

  @override
  Uri toUri() => Uri(path: '/checkout');
}

final class BetaRoute extends AppRoute {
  const BetaRoute();

  @override
  Uri toUri() => Uri(path: '/beta');
}

final class LoopARoute extends AppRoute {
  const LoopARoute();

  @override
  Uri toUri() => Uri(path: '/loop-a');
}

final class LoopBRoute extends AppRoute {
  const LoopBRoute();

  @override
  Uri toUri() => Uri(path: '/loop-b');
}

final class ProductData {
  const ProductData({
    required this.id,
    required this.title,
    required this.priceCents,
  });

  final int id;
  final String title;
  final int priceCents;
}

final class CheckoutSummary {
  const CheckoutSummary({required this.itemCount, required this.totalCents});

  final int itemCount;
  final int totalCents;
}

final class DemoSession {
  bool _signedIn = false;
  final List<int> _cartProductIds = <int>[];

  bool get isSignedIn => _signedIn;
  List<int> get cartProductIds => List<int>.unmodifiable(_cartProductIds);

  void signIn() {
    _signedIn = true;
  }

  void addToCart(int productId) {
    if (_cartProductIds.contains(productId)) {
      return;
    }
    _cartProductIds.add(productId);
  }
}

final class DemoConsole {
  void banner(String title) {
    print('============================================================');
    print(title);
    print('============================================================');
  }

  void section(String title) {
    print('');
    print('--- $title ---');
  }

  void item(String label, Object value) {
    print('[demo] $label: $value');
  }

  void printState(StateSnapshot<AppRoute> state) {
    final routeName = state.route == null
        ? '-'
        : state.route.runtimeType.toString();
    print(
      '[state] ${state.resolution.name} '
      'uri=${state.uri} '
      'route=$routeName '
      'action=${state.lastAction.name}',
    );
  }
}
