import 'package:test/test.dart';
import 'package:unrouter_core/unrouter_core.dart';

import 'support/fakes.dart';

void main() {
  group('route meta', () {
    test('RouteNode defaults meta to empty map', () {
      final node = RouteNode(path: '/', view: emptyView);
      expect(node.meta, isEmpty);
    });

    test('RouteRecord defaults meta to empty map', () {
      final record = RouteRecord<Object>(views: [emptyView], guards: []);
      expect(record.meta, isEmpty);
    });

    test(
      'meta is merged from parent to child with child values winning',
      () async {
        final router = createRouter<Object>(
          routes: [
            RouteNode(
              path: '/',
              view: emptyView,
              meta: {'role': 'user', 'layout': 'default'},
              children: [
                RouteNode(
                  path: 'admin',
                  view: emptyView,
                  meta: {'role': 'admin'},
                ),
              ],
            ),
          ],
        );

        await router.push('/admin');
        final match = router.matcher.find('/admin');
        expect(match?.data.meta['role'], 'admin');
        expect(match?.data.meta['layout'], 'default');
      },
    );

    test('meta is empty map when no meta is declared on route', () async {
      final router = createRouter<Object>(
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/plain', view: emptyView),
        ],
      );

      final match = router.matcher.find('/plain');
      expect(match?.data.meta, isEmpty);
    });
  });
}
