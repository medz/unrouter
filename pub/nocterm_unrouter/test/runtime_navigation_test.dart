import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart' as core;
import 'package:unstory/unstory.dart';

void main() {
  test('UnrouterScope.of and context extensions expose controller', () async {
    final controller = _createController();
    addTearDown(controller.dispose);

    final scope = UnrouterScope(
      controller: controller.cast<RouteData>(),
      child: const Text('child'),
    );
    final context = _TestNoctermContext(scope);

    expect(UnrouterScope.of(context), same(scope.controller));
    expect(context.unrouter, same(scope.controller));
    expect(
      context.unrouterAs<AppRoute>(),
      isA<core.UnrouterController<AppRoute>>(),
    );
  });

  test('UnrouterScope.of throws when scope is missing', () {
    final context = _TestNoctermContext(null);

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
      child: const Text('a'),
    );
    final b = UnrouterScope(
      controller: c1.cast<RouteData>(),
      child: const Text('b'),
    );
    final c = UnrouterScope(
      controller: c2.cast<RouteData>(),
      child: const Text('c'),
    );

    expect(a.updateShouldNotify(b), isFalse);
    expect(a.updateShouldNotify(c), isTrue);
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
        builder: (_, __) => const Text('home'),
      ),
      route<CartRoute>(
        path: '/cart',
        parse: (_) => const CartRoute(),
        builder: (_, __) => const Text('cart'),
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

class _TestNoctermContext extends StatefulElement {
  _TestNoctermContext(this._scope) : super(const _HostComponent());

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
  Component build(BuildContext context) => const Text('host');
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
