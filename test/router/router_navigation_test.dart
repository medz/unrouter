import 'package:flutter_test/flutter_test.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';

void main() {
  group('router navigation', () {
    test('resolves route name first then falls back to path', () async {
      final router = createRouter(
        routes: [
          Inlet(name: 'foo', path: '/bar', view: EmptyView.new),
          Inlet(path: '/foo', view: EmptyView.new),
          Inlet(path: '/foo-missing', view: EmptyView.new),
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
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/search', view: EmptyView.new),
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
          Inlet(path: '/', view: EmptyView.new),
          Inlet(name: 'profile', path: '/users/:id', view: EmptyView.new),
          Inlet(name: 'docs', path: '/docs/*', view: EmptyView.new),
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
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/a', view: EmptyView.new),
          Inlet(path: '/b', view: EmptyView.new),
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
