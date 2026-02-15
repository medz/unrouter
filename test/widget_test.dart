import 'dart:async';

import 'package:flutter/material.dart' hide Router;
import 'package:flutter/widgets.dart' as flutter show Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // RouterConfig
  // ---------------------------------------------------------------------------

  group('RouterConfig', () {
    test('creates valid config with custom back button dispatcher', () {
      final router = _simpleRouter();
      final config = createRouterConfig(router);

      expect(config.routerDelegate, isNotNull);
      expect(config.routeInformationParser, isNotNull);
      expect(config.routeInformationProvider, isNotNull);
      expect(config.backButtonDispatcher, isA<UnrouterBackButtonDispatcher>());
    });

    test('parser restores route information', () {
      final router = _simpleRouter();
      final config = createRouterConfig(router);
      final parser = config.routeInformationParser!;

      final restored = parser.restoreRouteInformation(
        HistoryLocation(Uri.parse('/users/1?tab=posts'), 'state'),
      );

      expect(restored, isNotNull);
      expect(restored!.uri.path, '/users/1');
      expect(restored.uri.query, 'tab=posts');
      expect(restored.state, 'state');
    });

    test('parser parses route information into HistoryLocation', () async {
      final router = _simpleRouter();
      final parser = createRouterConfig(router).routeInformationParser!;

      final parsed = await parser.parseRouteInformation(
        RouteInformation(
          uri: Uri(path: '/search', query: 'q=dart'),
        ),
      );

      expect(parsed.path, '/search');
      expect(parsed.uri.query, 'q=dart');
      expect(parsed.state, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Material Integration
  // ---------------------------------------------------------------------------

  group('Material integration', () {
    testWidgets('provides Navigator and Overlay for Material widgets', (
      tester,
    ) async {
      final router = createRouter(
        routes: [
          Inlet(
            view: () => Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('page'),
                  actions: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ],
                ),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) =>
                            const AlertDialog(content: Text('dialog open')),
                      );
                    },
                    child: const Text('open dialog'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(_materialTestApp(createRouterConfig(router)));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('open dialog'));
      await tester.pumpAndSettle();
      expect(find.text('dialog open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Back Button Dispatcher
  // ---------------------------------------------------------------------------

  group('BackButtonDispatcher', () {
    test('serializes concurrent pops', () async {
      final dispatcher = UnrouterBackButtonDispatcher();
      final completer = Completer<bool>();
      var calls = 0;
      Future<bool> callback() {
        calls += 1;
        return completer.future;
      }

      dispatcher.addCallback(callback);

      final first = dispatcher.didPopRoute();
      final second = dispatcher.didPopRoute();

      completer.complete(true);
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(calls, 1);

      dispatcher.removeCallback(callback);
    });

    testWidgets('pops router when wired in Router widget', (tester) async {
      final router = _simpleRouter();
      final config = createRouterConfig(router);
      await tester.pumpWidget(_testApp(config));

      await router.push('/search');
      await tester.pump();
      await tester.pump();
      expect(router.history.location.path, '/search');

      final dispatcher =
          config.backButtonDispatcher! as UnrouterBackButtonDispatcher;
      final handled = await dispatcher.didPopRoute();
      await tester.pump();
      await tester.pump();

      expect(handled, isTrue);
      expect(router.history.location.path, '/');
    });
  });

  // ---------------------------------------------------------------------------
  // Delegate
  // ---------------------------------------------------------------------------

  group('Delegate', () {
    test('popRoute returns false at root', () async {
      final router = _simpleRouter();
      final delegate = createRouterConfig(router).routerDelegate;
      expect(await delegate.popRoute(), isFalse);
    });

    test('popRoute returns true and goes back when history exists', () async {
      final router = _simpleRouter();
      final delegate = createRouterConfig(router).routerDelegate;

      await router.push('/search');
      expect(router.history.location.path, '/search');
      expect(await delegate.popRoute(), isTrue);
      expect(router.history.location.path, '/');
    });

    test('setNewRoutePath replaces current location', () async {
      final router = _simpleRouter();
      final delegate = createRouterConfig(router).routerDelegate;

      await delegate.setNewRoutePath(
        HistoryLocation(Uri.parse('/search?q=1'), 'next'),
      );

      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=1');
      expect(router.history.location.state, 'next');
    });

    test('setNewRoutePath no-ops when location is unchanged', () async {
      final router = _simpleRouter();
      final delegate = createRouterConfig(router).routerDelegate;
      var notifyCount = 0;
      router.addListener(() => notifyCount++);

      await delegate.setNewRoutePath(router.history.location);
      expect(notifyCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Route Information Provider
  // ---------------------------------------------------------------------------

  group('RouteInformationProvider', () {
    test('syncs value when router navigates before widget mount', () async {
      final router = _simpleRouter();
      final config = createRouterConfig(router);
      final provider = config.routeInformationProvider!;

      await router.push('/search');
      expect(provider.value.uri.path, '/search');
    });

    testWidgets('follows router updates in a live widget tree', (tester) async {
      final router = _simpleRouter();
      final config = createRouterConfig(router);
      await tester.pumpWidget(_testApp(config));

      final provider = config.routeInformationProvider!;
      expect(provider.value.uri.path, '/');

      await router.push('/search?q=flutter');
      await tester.pump();
      await tester.pump();
      expect(provider.value.uri.path, '/search');
      expect(provider.value.uri.query, 'q=flutter');

      await router.replace('/', state: 'replaced');
      await tester.pump();
      await tester.pump();
      expect(provider.value.uri.path, '/');
      expect(provider.value.state, 'replaced');
    });

    test('routerReportsNewRouteInformation updates provider value', () {
      final router = _simpleRouter();
      final config = createRouterConfig(router);
      final provider = config.routeInformationProvider!;

      provider.routerReportsNewRouteInformation(
        RouteInformation(uri: Uri(path: '/search')),
      );

      expect(provider.value.uri.path, '/search');
    });

    testWidgets('provider value and view stay consistent after router push', (
      tester,
    ) async {
      final router = _simpleRouter();
      final config = createRouterConfig(router);
      final provider = config.routeInformationProvider!;
      await tester.pumpWidget(_testApp(config));

      await router.push('/search');
      await tester.pump();
      await tester.pump();

      expect(router.history.location.path, '/search');
      expect(provider.value.uri.path, '/search');
      expect(find.text('search'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Outlet
  // ---------------------------------------------------------------------------

  group('Outlet', () {
    testWidgets('renders parent and child route view', (tester) async {
      final router = _simpleRouter();
      final config = createRouterConfig(router);

      await tester.pumpWidget(_testApp(config));
      expect(find.text('root'), findsOneWidget);
      expect(find.text('search'), findsNothing);

      await router.push('/search');
      await tester.pump();
      await tester.pump();
      expect(find.text('root'), findsOneWidget);
      expect(find.text('search'), findsOneWidget);
    });

    testWidgets('renders nothing for unmatched route', (tester) async {
      final router = createRouter(routes: [Inlet(view: _rootView)]);
      final config = createRouterConfig(router);

      await tester.pumpWidget(_testApp(config));
      expect(find.text('root'), findsOneWidget);
    });

    testWidgets('supports multiple top-level inlets without shared shell', (
      tester,
    ) async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: () => const Text('landing')),
          Inlet(path: '/login', view: () => const Text('login')),
          Inlet(path: '/workspace', view: () => const Text('workspace')),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      expect(find.text('landing'), findsOneWidget);

      await router.push('/login');
      await tester.pump();
      await tester.pump();
      expect(find.text('login'), findsOneWidget);
      expect(find.text('landing'), findsNothing);

      await router.push('/workspace');
      await tester.pump();
      await tester.pump();
      expect(find.text('workspace'), findsOneWidget);
      expect(find.text('login'), findsNothing);
    });

    testWidgets('renders multi-level nested outlet chain', (tester) async {
      final router = createRouter(
        routes: [
          Inlet(
            view: () => const Column(children: [Text('level0'), Outlet()]),
            children: [
              Inlet(
                path: 'a',
                view: () => const Column(children: [Text('level1'), Outlet()]),
                children: [Inlet(path: 'b', view: () => const Text('level2'))],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/a/b');
      await tester.pump();
      await tester.pump();

      expect(find.text('level0'), findsOneWidget);
      expect(find.text('level1'), findsOneWidget);
      expect(find.text('level2'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Rebuild Granularity
  // ---------------------------------------------------------------------------

  group('Rebuild granularity', () {
    testWidgets('switching /a/b -> /a/c does not recreate parent view', (
      tester,
    ) async {
      _trackedParentInitCount = 0;
      _trackedParentBuildCount = 0;

      final router = createRouter(
        routes: [
          Inlet(
            view: () => const Column(children: [Text('root'), Outlet()]),
            children: [
              Inlet(
                path: 'a',
                view: () => const _TrackedParentView(useParams: true),
                children: [
                  Inlet(
                    path: ':leaf',
                    view: () => Builder(
                      builder: (context) {
                        final leaf = useRouteParams(context)['leaf'];
                        return Text('leaf:$leaf');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));

      await router.push('/a/b');
      await tester.pump();
      await tester.pump();

      expect(find.text('leaf:b'), findsOneWidget);
      expect(_trackedParentInitCount, 1);
      final firstBuildCount = _trackedParentBuildCount;

      await router.push('/a/c');
      await tester.pump();
      await tester.pump();

      expect(find.text('leaf:c'), findsOneWidget);
      expect(_trackedParentInitCount, 1);
      expect(_trackedParentBuildCount, greaterThan(firstBuildCount));
    });
  });

  // ---------------------------------------------------------------------------
  // Reactive Hooks
  // ---------------------------------------------------------------------------

  group('Hooks', () {
    testWidgets('useRouter returns the router instance', (tester) async {
      late Unrouter captured;
      final router = createRouter(
        routes: [
          Inlet(
            view: () {
              return Builder(
                builder: (context) {
                  captured = useRouter(context);
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      expect(captured, same(router));
    });

    testWidgets('useRouteParams exposes matched params', (tester) async {
      String? capturedId;
      final router = createRouter(
        routes: [
          Inlet(
            view: _rootView,
            children: [
              Inlet(
                path: 'users/:id',
                view: () => Builder(
                  builder: (context) {
                    capturedId = useRouteParams(context)['id'];
                    return Text('user:$capturedId');
                  },
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/users/99');
      await tester.pump();
      await tester.pump();
      expect(capturedId, '99');
      expect(find.text('user:99'), findsOneWidget);
    });

    testWidgets('useQuery exposes parsed query string', (tester) async {
      String? capturedQ;
      final router = createRouter(
        routes: [
          Inlet(
            view: _rootView,
            children: [
              Inlet(
                path: 'search',
                view: () => Builder(
                  builder: (context) {
                    capturedQ = useQuery(context).get('q');
                    return Text('q:$capturedQ');
                  },
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/search?q=flutter');
      await tester.pump();
      await tester.pump();
      expect(capturedQ, 'flutter');
    });

    testWidgets('useRouteMeta returns merged meta', (tester) async {
      Map<String, Object?>? capturedMeta;
      final router = createRouter(
        routes: [
          Inlet(
            view: _rootView,
            meta: const {'layout': 'shell'},
            children: [
              Inlet(
                path: 'page',
                view: () => Builder(
                  builder: (context) {
                    capturedMeta = useRouteMeta(context);
                    return const Text('page');
                  },
                ),
                meta: const {'title': 'Page'},
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/page');
      await tester.pump();
      await tester.pump();
      expect(capturedMeta, {'layout': 'shell', 'title': 'Page'});
    });

    testWidgets('useFromLocation tracks the previous location', (tester) async {
      HistoryLocation? capturedFrom;
      final router = createRouter(
        routes: [
          Inlet(
            view: () => Builder(
              builder: (context) {
                capturedFrom = useFromLocation(context);
                return Column(children: [const Text('root'), const Outlet()]);
              },
            ),
            children: [Inlet(path: 'search', view: _searchView)],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      expect(capturedFrom, isNull);

      await router.push('/search');
      await tester.pump();
      await tester.pump();
      expect(capturedFrom, isNotNull);
      expect(capturedFrom!.path, '/');
    });

    testWidgets('useRouteURI and useLocation expose current uri', (
      tester,
    ) async {
      Uri? capturedUri;
      String? capturedPath;
      final router = createRouter(
        routes: [
          Inlet(
            view: _rootView,
            children: [
              Inlet(
                path: 'search',
                view: () => Builder(
                  builder: (context) {
                    capturedUri = useRouteURI(context);
                    capturedPath = useLocation(context).path;
                    return const Text('uri');
                  },
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/search?q=1');
      await tester.pump();
      await tester.pump();

      expect(capturedUri?.path, '/search');
      expect(capturedUri?.query, 'q=1');
      expect(capturedPath, '/search');
    });

    testWidgets('useRouteState returns typed state', (tester) async {
      String? captured;
      final router = createRouter(
        routes: [
          Inlet(
            view: _rootView,
            children: [
              Inlet(
                path: 'search',
                view: () => Builder(
                  builder: (context) {
                    captured = useRouteState<String>(context);
                    return Text('state:$captured');
                  },
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/search', state: 'from-home');
      await tester.pump();
      await tester.pump();

      expect(captured, 'from-home');
      expect(find.text('state:from-home'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Middleware
  // ---------------------------------------------------------------------------

  group('Middleware', () {
    testWidgets('async middleware chain runs in order', (tester) async {
      final events = <String>[];
      FutureOr<Widget> rootMiddleware(BuildContext context, Next next) async {
        events.add('root:before');
        final child = await next();
        events.add('root:after');
        return child;
      }

      FutureOr<Widget> childMiddleware(BuildContext context, Next next) async {
        events.add('child:before');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final child = await next();
        events.add('child:after');
        return child;
      }

      final router = createRouter(
        middleware: [rootMiddleware],
        routes: [
          Inlet(
            view: _rootView,
            children: [
              Inlet(
                path: 'search',
                view: _searchView,
                middleware: [childMiddleware],
              ),
            ],
          ),
        ],
      );
      final config = createRouterConfig(router);

      await tester.pumpWidget(_testApp(config));
      events.clear();

      await router.push('/search');
      await tester.pump();
      // Not rendered yet — child middleware has a 20ms delay
      expect(find.text('search'), findsNothing);

      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('search'), findsOneWidget);
      expect(events, containsAllInOrder(['root:before', 'child:before']));
      expect(events, containsAllInOrder(['child:after', 'root:after']));
    });

    testWidgets('middleware can block navigation by returning a widget', (
      tester,
    ) async {
      FutureOr<Widget> guard(BuildContext context, Next next) async {
        return const Text('blocked', textDirection: TextDirection.ltr);
      }

      final router = createRouter(
        routes: [
          Inlet(
            view: _rootView,
            children: [
              Inlet(
                path: 'admin',
                view: () => const Text('admin'),
                middleware: [guard],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/admin');
      await tester.pump();
      await tester.pump();
      expect(find.text('admin'), findsNothing);
      expect(find.text('blocked'), findsOneWidget);
    });

    testWidgets('middleware throws when next is called twice', (tester) async {
      FutureOr<Widget> invalid(BuildContext context, Next next) {
        next();
        return next();
      }

      final router = createRouter(
        routes: [
          Inlet(
            view: _rootView,
            children: [
              Inlet(path: 'search', view: _searchView, middleware: [invalid]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_testApp(createRouterConfig(router)));
      await router.push('/search');
      await tester.pump();
      final error = tester.takeException();
      expect(error, isStateError);
      expect(error.toString(), contains('next() called more than once'));
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _testApp(RouterConfig<HistoryLocation> config) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: flutter.Router.withConfig(config: config),
  );
}

Widget _materialTestApp(RouterConfig<HistoryLocation> config) {
  return MaterialApp.router(routerConfig: config);
}

Widget _rootView() => const Column(children: [Text('root'), Outlet()]);
Widget _searchView() => const Text('search');

int _trackedParentInitCount = 0;
int _trackedParentBuildCount = 0;

class _TrackedParentView extends StatefulWidget {
  const _TrackedParentView({required this.useParams});

  final bool useParams;

  @override
  State<_TrackedParentView> createState() => _TrackedParentViewState();
}

class _TrackedParentViewState extends State<_TrackedParentView> {
  @override
  void initState() {
    super.initState();
    _trackedParentInitCount += 1;
  }

  @override
  Widget build(BuildContext context) {
    _trackedParentBuildCount += 1;
    final marker = widget.useParams
        ? (useRouteParams(context)['leaf'] ?? '-')
        : '-';
    return Column(children: [Text('tracked:$marker'), const Outlet()]);
  }
}

Unrouter _simpleRouter() {
  return createRouter(
    routes: [
      Inlet(
        view: _rootView,
        children: [Inlet(path: 'search', view: _searchView)],
      ),
    ],
  );
}
