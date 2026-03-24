import 'package:test/test.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter_core/unrouter_core.dart';

Object emptyView() => Object();

Future<void> flushQueue() async {
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
      await flushQueue();
      expect(router.history.location.path, '/login');
    });
  });
}
