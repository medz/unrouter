import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' as flutter show Router;
import 'package:flutter/widgets.dart' hide Router;
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter Router contract', () {
    test('config uses custom route provider and back button dispatcher', () {
      final router = createRouter(
        routes: [Inlet(path: '/', view: _view)],
      );

      final config = createRouterConfig(router);
      expect(
        config.routeInformationProvider,
        isNot(isA<PlatformRouteInformationProvider>()),
      );
      expect(config.backButtonDispatcher, isA<UnrouterBackButtonDispatcher>());
    });

    test('back button dispatcher serializes concurrent pop', () async {
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

    test('parser restores route information from configuration', () {
      final router = createRouter(
        routes: [Inlet(path: '/', view: _view)],
      );

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

    test('delegate popRoute respects history index', () async {
      final router = createRouter(
        routes: [
          Inlet(
            path: '/',
            view: _view,
            children: [Inlet(path: 'search', view: _view)],
          ),
        ],
      );
      final delegate = createRouterConfig(router).routerDelegate;

      expect(await delegate.popRoute(), isFalse);

      await router.push('/search');
      expect(router.history.location.path, '/search');
      expect(await delegate.popRoute(), isTrue);
      expect(router.history.location.path, '/');
    });

    test('delegate setNewRoutePath replaces current location', () async {
      final router = createRouter(
        routes: [
          Inlet(
            path: '/',
            view: _view,
            children: [Inlet(path: 'search', view: _view)],
          ),
        ],
      );
      final delegate = createRouterConfig(router).routerDelegate;

      await delegate.setNewRoutePath(
        HistoryLocation(Uri.parse('/search?q=1'), 'next'),
      );

      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=1');
      expect(router.history.location.state, 'next');
    });

    test('provider value stays in sync before router widget mounts', () async {
      final router = createRouter(
        routes: [
          Inlet(
            path: '/',
            view: _rootView,
            children: [Inlet(path: 'search', view: _searchView)],
          ),
        ],
      );
      final config = createRouterConfig(router);
      final provider = config.routeInformationProvider!;

      await router.push('/search');
      expect(provider.value.uri.path, '/search');
    });

    testWidgets('route information provider follows router updates', (
      tester,
    ) async {
      final router = createRouter(
        routes: [
          Inlet(
            path: '/',
            view: _rootView,
            children: [Inlet(path: 'search', view: _searchView)],
          ),
        ],
      );
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

    testWidgets('Outlet renders nested routes', (tester) async {
      final router = createRouter(
        routes: [
          Inlet(
            path: '/',
            view: _rootView,
            children: [Inlet(path: 'search', view: _searchView)],
          ),
        ],
      );
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

    testWidgets('middleware supports async chain', (tester) async {
      final events = <String>[];
      final rootMiddleware = defineMiddleware((context, next) async {
        events.add('root:before');
        final child = await next();
        events.add('root:after');
        return child;
      });
      final childMiddleware = defineMiddleware((context, next) async {
        events.add('child:before');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final child = await next();
        events.add('child:after');
        return child;
      });

      final router = createRouter(
        middleware: [rootMiddleware],
        routes: [
          Inlet(
            path: '/',
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
      expect(find.text('search'), findsNothing);

      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('search'), findsOneWidget);
      expect(events, containsAllInOrder(['root:before', 'child:before']));
      expect(events, containsAllInOrder(['child:after', 'root:after']));
    });
  });
}

Widget _testApp(RouterConfig<HistoryLocation> config) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: flutter.Router.withConfig(config: config),
  );
}

Widget _view() => const SizedBox.shrink();

Widget _rootView() => const Column(children: [Text('root'), Outlet()]);

Widget _searchView() => const Text('search');
