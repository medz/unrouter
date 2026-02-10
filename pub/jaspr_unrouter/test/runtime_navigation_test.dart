import 'package:jaspr/dom.dart' as dom;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_unrouter/jaspr_unrouter.dart';
import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart' as core;
import 'package:unstory/unstory.dart';

void main() {
  test('UnrouterScope.of and context extensions expose controller', () async {
    final controller = _createController();
    addTearDown(controller.dispose);

    final scope = UnrouterScope(
      controller: controller.cast<RouteData>(),
      child: const Component.text('child'),
    );
    final context = _TestJasprContext(scope);

    expect(UnrouterScope.of(context), same(scope.controller));
    expect(context.unrouter, same(scope.controller));
    expect(
      context.unrouterAs<AppRoute>(),
      isA<core.UnrouterController<AppRoute>>(),
    );
  });

  test('UnrouterScope.of throws when scope is missing', () {
    final context = _TestJasprContext(null);

    expect(() => UnrouterScope.of(context), throwsA(isA<StateError>()));
    expect(() => context.unrouter, throwsA(isA<StateError>()));
  });

  test('UnrouterScope notifies only when controller changes', () {
    final c1 = _createController();
    final c2 = _createController();
    addTearDown(c1.dispose);
    addTearDown(c2.dispose);

    final a = UnrouterScope(
      controller: c1.cast<RouteData>(),
      child: const Component.text('a'),
    );
    final b = UnrouterScope(
      controller: c1.cast<RouteData>(),
      child: const Component.text('b'),
    );
    final c = UnrouterScope(
      controller: c2.cast<RouteData>(),
      child: const Component.text('c'),
    );

    expect(a.updateShouldNotify(b), isFalse);
    expect(a.updateShouldNotify(c), isTrue);
  });

  test('UnrouterLink intercepts go/push and skips _blank target', () async {
    final controller = _createController(initialPath: '/cart');
    addTearDown(controller.dispose);

    final scope = UnrouterScope(
      controller: controller.cast<RouteData>(),
      child: const Component.text('child'),
    );
    final context = _TestJasprContext(scope);

    final goLink = UnrouterLink<HomeRoute>(
      route: const HomeRoute(),
      mode: UnrouterLinkMode.go,
      children: const <Component>[Component.text('home')],
    );
    final builtGo = goLink.build(context) as dom.a;
    expect(builtGo.href, '/home');
    expect(builtGo.onClick, isNotNull);

    builtGo.onClick!.call();
    await controller.idle;
    expect(controller.uri.path, '/home');

    final pushLink = UnrouterLink<CartRoute>(
      route: const CartRoute(),
      mode: UnrouterLinkMode.push,
      children: const <Component>[Component.text('cart')],
    );
    final builtPush = pushLink.build(context) as dom.a;
    builtPush.onClick!.call();
    await controller.idle;
    expect(controller.uri.path, '/cart');

    final blankLink = UnrouterLink<HomeRoute>(
      route: const HomeRoute(),
      target: dom.Target.blank,
      children: const <Component>[Component.text('blank')],
    );
    final builtBlank = blankLink.build(context) as dom.a;
    expect(builtBlank.onClick, isNull);
  });
}

core.UnrouterController<AppRoute> _createController({
  String initialPath = '/home',
}) {
  final router = Unrouter<AppRoute>(
    routes: <RouteRecord<AppRoute>>[
      route<HomeRoute>(
        path: '/home',
        parse: (_) => const HomeRoute(),
        builder: (_, __) => const Component.text('home'),
      ),
      route<CartRoute>(
        path: '/cart',
        parse: (_) => const CartRoute(),
        builder: (_, __) => const Component.text('cart'),
      ),
    ],
  );

  return core.UnrouterController<AppRoute>(
    router: router,
    history: MemoryHistory(
      initialEntries: <HistoryLocation>[
        HistoryLocation(Uri(path: initialPath)),
      ],
      initialIndex: 0,
    ),
    resolveInitialRoute: false,
  );
}

class _TestJasprContext extends StatefulElement {
  _TestJasprContext(this._scope) : super(const _HostComponent());

  final UnrouterScope? _scope;

  @override
  T? dependOnInheritedComponentOfExactType<T extends InheritedComponent>({
    Object? aspect,
  }) {
    if (T == UnrouterScope && _scope != null) {
      return _scope as T;
    }
    return null;
  }
}

class _HostComponent extends StatefulComponent {
  const _HostComponent();

  @override
  State createState() => _HostState();
}

class _HostState extends State<_HostComponent> {
  @override
  Component build(BuildContext context) => const Component.text('host');
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/home');
}

final class CartRoute extends AppRoute {
  const CartRoute();

  @override
  Uri toUri() => Uri(path: '/cart');
}
