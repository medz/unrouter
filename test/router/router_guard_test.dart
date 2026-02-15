import 'package:flutter_test/flutter_test.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';

Future<void> _flushQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('guard flow', () {
    test('blocks navigation when guard returns block', () async {
      final blockGuard = defineGuard((context) {
        if (context.to.path == '/private') {
          return const GuardResult.block();
        }
        return const GuardResult.allow();
      });
      final router = createRouter(
        guards: [blockGuard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/private', view: EmptyView.new),
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
      final router = createRouter(
        history: history,
        guards: [redirectGuard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/private', view: EmptyView.new),
          Inlet(path: '/login', view: EmptyView.new),
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
      final router = createRouter(
        history: history,
        guards: [redirectGuard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/private', view: EmptyView.new),
          Inlet(name: 'profile', path: '/users/:id', view: EmptyView.new),
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

      final chainRouter = createRouter(
        guards: [chainedGuard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/a', view: EmptyView.new),
          Inlet(path: '/b', view: EmptyView.new),
          Inlet(path: '/c', view: EmptyView.new),
        ],
      );
      await chainRouter.push('/a');
      expect(chainRouter.history.location.path, '/c');

      final loopRouter = createRouter(
        guards: [loopGuard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/loop', view: EmptyView.new),
        ],
      );
      expect(loopRouter.push('/loop'), throwsStateError);

      final limitedDepthRouter = createRouter(
        maxRedirectDepth: 1,
        guards: [chainedGuard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/a', view: EmptyView.new),
          Inlet(path: '/b', view: EmptyView.new),
          Inlet(path: '/c', view: EmptyView.new),
        ],
      );
      expect(limitedDepthRouter.push('/a'), throwsStateError);

      final exactDepthRouter = createRouter(
        maxRedirectDepth: 2,
        guards: [chainedGuard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/a', view: EmptyView.new),
          Inlet(path: '/b', view: EmptyView.new),
          Inlet(path: '/c', view: EmptyView.new),
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
      final router = createRouter(
        history: history,
        guards: [guard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/private', view: EmptyView.new),
          Inlet(path: '/safe', view: EmptyView.new),
        ],
      );

      router.back();
      await _flushQueue();
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
      final router = createRouter(
        history: history,
        guards: [guard],
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/private', view: EmptyView.new),
          Inlet(path: '/safe', view: EmptyView.new),
          Inlet(path: '/login', view: EmptyView.new),
        ],
      );

      router.back();
      await _flushQueue();
      expect(router.history.location.path, '/login');
    });
  });
}
