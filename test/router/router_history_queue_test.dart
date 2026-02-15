import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';

void main() {
  group('router history queue', () {
    test('keeps pop processing order for rapid back calls', () async {
      final seenPaths = <String>[];
      final guard = defineGuard((context) async {
        seenPaths.add(context.to.path);
        await Future<void>.delayed(const Duration(milliseconds: 8));
        return const GuardResult.allow();
      });

      final history = createMemoryHistory([
        '/',
        '/a',
        '/b',
        '/c',
      ], initialIndex: 3);
      final router = createRouter(
        history: history,
        guards: [guard],
        routes: [
          Inlet(path: '/', view: emptyView),
          Inlet(path: '/a', view: emptyView),
          Inlet(path: '/b', view: emptyView),
          Inlet(path: '/c', view: emptyView),
        ],
      );

      router.back();
      router.back();
      await flushAsyncQueue(delay: const Duration(milliseconds: 40));

      expect(seenPaths, ['/b', '/a']);
      expect(router.history.location.path, '/a');
      expect(router.history.index, 1);
    });

    test('continues processing queue after guard throws', () async {
      FlutterErrorDetails? reported;
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        reported = details;
      };
      addTearDown(() {
        FlutterError.onError = previousHandler;
      });

      final guard = defineGuard((context) {
        if (context.to.path == '/b') {
          throw StateError('guard failed');
        }
        return const GuardResult.allow();
      });

      final history = createMemoryHistory([
        '/',
        '/a',
        '/b',
        '/c',
      ], initialIndex: 3);
      final router = createRouter(
        history: history,
        guards: [guard],
        routes: [
          Inlet(path: '/', view: emptyView),
          Inlet(path: '/a', view: emptyView),
          Inlet(path: '/b', view: emptyView),
          Inlet(path: '/c', view: emptyView),
        ],
      );

      router.back();
      await flushAsyncQueue();
      expect(router.history.location.path, '/b');

      router.back();
      await flushAsyncQueue();
      expect(router.history.location.path, '/a');
      expect(reported?.exception.toString(), contains('guard failed'));
    });

    test(
      'applies redirect and block correctly under rapid pop events',
      () async {
        final guard = defineGuard((context) {
          if (context.to.path == '/private') {
            return const GuardResult.block();
          }
          if (context.to.path == '/legacy') {
            return GuardResult.redirect('/login');
          }
          return const GuardResult.allow();
        });

        final history = createMemoryHistory([
          '/',
          '/private',
          '/legacy',
          '/safe',
        ], initialIndex: 3);
        final router = createRouter(
          history: history,
          guards: [guard],
          routes: [
            Inlet(path: '/', view: emptyView),
            Inlet(path: '/private', view: emptyView),
            Inlet(path: '/legacy', view: emptyView),
            Inlet(path: '/safe', view: emptyView),
            Inlet(path: '/login', view: emptyView),
          ],
        );

        router.back();
        router.back();
        await flushAsyncQueue(delay: const Duration(milliseconds: 50));

        expect(router.history.location.path, '/login');
      },
    );
  });
}
