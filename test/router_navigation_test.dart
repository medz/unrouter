import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  group('Router navigation contract', () {
    test('push/replace resolve name+params+query+state correctly', () async {
      final router = _createNavigationRouter();

      await router.push(
        'profile',
        params: const {'id': '1'},
        query: URLSearchParams(const {'tab': 'posts'}),
        state: 'from-home',
      );

      expect(router.history.location.path, '/users/1');
      expect(router.history.location.uri.query, 'tab=posts');
      expect(router.history.location.state, 'from-home');
      expect(router.history.index, 1);

      await router.push('/search?q=flutter&page=2', state: 'search-state');
      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=flutter&page=2');
      expect(router.history.location.state, 'search-state');
      expect(router.history.index, 2);

      await router.replace('/search?q=replaced&page=1', state: 'replaced');
      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=replaced&page=1');
      expect(router.history.location.state, 'replaced');
      expect(router.history.index, 2);
    });

    test('history movement keeps expected route sequence', () async {
      final router = _createNavigationRouter();

      await router.push('profile', params: const {'id': '7'});
      await router.push('search');

      expect(router.history.location.path, '/search');
      router.back();
      expect(router.history.location.path, '/users/7');

      router.forward();
      expect(router.history.location.path, '/search');

      router.go(-1);
      expect(router.history.location.path, '/users/7');
    });

    test('rejects invalid navigation inputs', () async {
      final router = _createNavigationRouter();

      await expectLater(router.push('missing'), throwsStateError);
      await expectLater(router.push('/not-found'), throwsStateError);
      await expectLater(
        router.push('/search', params: const {'id': '1'}),
        throwsArgumentError,
      );
      await expectLater(router.push('profile'), throwsArgumentError);
      await expectLater(
        router.push('profile', params: const {'id': '1', 'extra': 'x'}),
        throwsArgumentError,
      );
      await expectLater(
        router.push('profile', params: const {'id': '1/2'}),
        throwsArgumentError,
      );
    });

    test('name navigation supports wildcard param', () async {
      final router = _createNavigationRouter();

      await router.push(
        'docs',
        params: const {'wildcard': 'guide/getting-started'},
      );

      expect(router.history.location.path, '/docs/guide/getting-started');
    });

    test('explicit query overrides path query', () async {
      final router = _createNavigationRouter();

      await router.push(
        '/search?q=old&page=1',
        query: URLSearchParams(const {'q': 'new'}),
      );

      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=new');
    });

    test('history listeners observe pop actions only', () async {
      final router = _createNavigationRouter();
      final events = <HistoryEvent>[];
      final unlisten = router.history.listen(events.add);

      await router.push('profile', params: const {'id': '1'});
      await router.replace('search');
      router.back();

      expect(events.length, 1);
      expect(events.single.action, HistoryAction.pop);
      expect(events.single.location.path, '/');

      unlisten();
    });

    test('home -> profile -> search should stay on search', () async {
      final router = _createNavigationRouter();

      await router.push('home');
      await router.push('profile', params: const {'id': '42'});
      await router.push('search');

      expect(router.history.location.path, '/search');
    });
  });
}

Router _createNavigationRouter() {
  return createRouter(
    routes: [
      Inlet(
        path: '/',
        view: _rootView,
        children: [
          Inlet(name: 'home', path: '', view: _homeView),
          Inlet(name: 'profile', path: 'users/:id', view: _profileView),
          Inlet(name: 'search', path: 'search', view: _searchView),
          Inlet(name: 'docs', path: 'docs/*', view: _docsView),
        ],
      ),
    ],
  );
}

Widget _rootView() => const SizedBox.shrink();
Widget _homeView() => const SizedBox.shrink();
Widget _profileView() => const SizedBox.shrink();
Widget _searchView() => const SizedBox.shrink();
Widget _docsView() => const SizedBox.shrink();
