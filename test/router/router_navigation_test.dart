import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter/unrouter.dart';

Widget _emptyView() => const SizedBox.shrink();

void main() {
  group('router navigation', () {
    test('resolves route name first then falls back to path', () async {
      final router = createRouter(
        routes: [
          Inlet(name: 'foo', path: '/bar', view: _emptyView),
          Inlet(path: '/foo', view: _emptyView),
          Inlet(path: '/foo-missing', view: _emptyView),
        ],
      );

      await router.push('/foo');
      expect(router.history.location.path, '/bar');

      await router.push('/foo-missing');
      expect(router.history.location.path, '/foo-missing');
    });

    test('merges query and explicit query overrides same-name keys', () async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: _emptyView),
          Inlet(path: '/search', view: _emptyView),
        ],
      );

      await router.push(
        '/search?q=old&page=1',
        query: URLSearchParams({'q': 'new', 'sort': 'desc'}),
      );

      final query = URLSearchParams(router.history.location.query);
      expect(query.get('q'), 'new');
      expect(query.get('page'), '1');
      expect(query.get('sort'), 'desc');
    });

    test('fills params and wildcard by route name', () async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: _emptyView),
          Inlet(name: 'profile', path: '/users/:id', view: _emptyView),
          Inlet(name: 'docs', path: '/docs/*', view: _emptyView),
        ],
      );

      await router.push('profile', params: {'id': '42'});
      expect(router.history.location.path, '/users/42');

      await router.push('docs', params: {'wildcard': 'guide/getting-started'});
      expect(router.history.location.path, '/docs/guide/getting-started');
    });

    test('supports push, replace and pop flow', () async {
      final history = MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/'))],
      );
      final router = createRouter(
        history: history,
        routes: [
          Inlet(path: '/', view: _emptyView),
          Inlet(path: '/a', view: _emptyView),
          Inlet(path: '/b', view: _emptyView),
        ],
      );

      await router.push('/a');
      expect(router.history.location.path, '/a');
      expect(router.history.index, 1);

      await router.replace('/b');
      expect(router.history.location.path, '/b');
      expect(router.history.index, 1);

      final popped = await router.pop();
      expect(popped, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(router.history.location.path, '/');
      expect(router.history.index, 0);
    });
  });
}
