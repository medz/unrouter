import 'package:test/test.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter_core/unrouter_core.dart';

import 'support/fakes.dart';

void main() {
  group('guard flow', () {
    test('blocks navigation when guard returns block', () async {
      final blockGuard = defineGuard((context) {
        if (context.to.path == '/private') {
          return const GuardResult.block();
        }
        return const GuardResult.allow();
      });
      final router = createRouter<Object>(
        guards: [blockGuard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/private', view: emptyView),
        ],
      );

      await router.push('/private');
      expect(router.history.location.path, '/');
      expect(router.history.index, 0);
    });

    test('redirects with replace when guard returns redirect', () async {
      final redirectGuard = defineGuard((context) {
        if (context.to.path == '/private') {
          return GuardResult.redirect('/login');
        }
        return const GuardResult.allow();
      });
      final history = MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/'))],
      );
      final router = createRouter<Object>(
        history: history,
        guards: [redirectGuard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/private', view: emptyView),
          RouteNode(path: '/login', view: emptyView),
        ],
      );

      await router.push('/private');
      expect(router.history.location.path, '/login');
      expect(router.history.index, 0);
    });

    test('redirect accepts params query and state overrides', () async {
      final redirectGuard = defineGuard((context) {
        if (context.to.path == '/private') {
          return GuardResult.redirect(
            'profile',
            params: {'id': '42'},
            query: URLSearchParams({'from': 'guard'}),
            state: 'redirect-state',
          );
        }
        return const GuardResult.allow();
      });
      final history = MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/'))],
      );
      final router = createRouter<Object>(
        history: history,
        guards: [redirectGuard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/private', view: emptyView),
          RouteNode(name: 'profile', path: '/users/:id', view: emptyView),
        ],
      );

      await router.push('/private', state: 'origin-state');
      expect(router.history.location.path, '/users/42');
      expect(
        URLSearchParams(router.history.location.query).get('from'),
        'guard',
      );
      expect(router.history.location.state, 'redirect-state');
      expect(router.history.index, 0);
    });

    test('supports redirect chain and enforces max redirect depth', () async {
      final chainedGuard = defineGuard((context) {
        if (context.to.path == '/a') {
          return GuardResult.redirect('/b');
        }
        if (context.to.path == '/b') {
          return GuardResult.redirect('/c');
        }
        return const GuardResult.allow();
      });
      final loopGuard = defineGuard((context) {
        if (context.to.path == '/loop') {
          return GuardResult.redirect('/loop');
        }
        return const GuardResult.allow();
      });

      final chainRouter = createRouter<Object>(
        guards: [chainedGuard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/a', view: emptyView),
          RouteNode(path: '/b', view: emptyView),
          RouteNode(path: '/c', view: emptyView),
        ],
      );
      await chainRouter.push('/a');
      expect(chainRouter.history.location.path, '/c');

      final loopRouter = createRouter<Object>(
        guards: [loopGuard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/loop', view: emptyView),
        ],
      );
      expect(
        loopRouter.push('/loop'),
        throwsStateErrorContaining('Guard redirect loop exceeded max depth'),
      );

      final limitedDepthRouter = createRouter<Object>(
        maxRedirectDepth: 1,
        guards: [chainedGuard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/a', view: emptyView),
          RouteNode(path: '/b', view: emptyView),
          RouteNode(path: '/c', view: emptyView),
        ],
      );
      expect(
        limitedDepthRouter.push('/a'),
        throwsStateErrorContaining('Guard redirect loop exceeded max depth'),
      );

      final exactDepthRouter = createRouter<Object>(
        maxRedirectDepth: 2,
        guards: [chainedGuard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/a', view: emptyView),
          RouteNode(path: '/b', view: emptyView),
          RouteNode(path: '/c', view: emptyView),
        ],
      );
      await exactDepthRouter.push('/a');
      expect(exactDepthRouter.history.location.path, '/c');
    });

    test('applies guard on history pop and keeps view when blocked', () async {
      final guard = defineGuard((context) {
        if (context.to.path == '/private') {
          return const GuardResult.block();
        }
        return const GuardResult.allow();
      });
      final history = MemoryHistory(
        initialEntries: [
          HistoryLocation(Uri(path: '/')),
          HistoryLocation(Uri(path: '/private')),
          HistoryLocation(Uri(path: '/safe')),
        ],
        initialIndex: 2,
      );
      final router = createRouter<Object>(
        history: history,
        guards: [guard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/private', view: emptyView),
          RouteNode(path: '/safe', view: emptyView),
        ],
      );

      router.back();
      await flushAsyncQueue(delay: Duration.zero);
      expect(router.history.location.path, '/safe');
    });

    test('applies guard on history pop and redirects when requested', () async {
      final guard = defineGuard((context) {
        if (context.to.path == '/private') {
          return GuardResult.redirect('/login');
        }
        return const GuardResult.allow();
      });
      final history = MemoryHistory(
        initialEntries: [
          HistoryLocation(Uri(path: '/')),
          HistoryLocation(Uri(path: '/private')),
          HistoryLocation(Uri(path: '/safe')),
        ],
        initialIndex: 2,
      );
      final router = createRouter<Object>(
        history: history,
        guards: [guard],
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/private', view: emptyView),
          RouteNode(path: '/safe', view: emptyView),
          RouteNode(path: '/login', view: emptyView),
        ],
      );

      router.back();
      await flushAsyncQueue(delay: Duration.zero);
      expect(router.history.location.path, '/login');
    });
  });
}
