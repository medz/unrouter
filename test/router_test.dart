import 'dart:async';

import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Route Table Construction
  // ---------------------------------------------------------------------------

  group('Route table', () {
    test('root inlet registers as /', () {
      final router = _router([Inlet(view: _view)]);
      final match = router.matcher.match('/');
      expect(match, isNotNull);
      expect(match!.data.views.length, 1);
    });

    test('child paths combine with parent path', () {
      final router = _router([
        Inlet(
          view: _view,
          children: [
            Inlet(path: 'users/:id', view: _view),
            Inlet(path: 'search', view: _view),
          ],
        ),
      ]);

      expect(router.matcher.match('/users/42'), isNotNull);
      expect(router.matcher.match('/search'), isNotNull);
      expect(router.matcher.match('/unknown'), isNull);
    });

    test('nested views form a chain from root to leaf', () {
      final router = _router([
        Inlet(
          view: _view,
          children: [
            Inlet(
              path: 'a',
              view: _view,
              children: [Inlet(path: 'b', view: _view)],
            ),
          ],
        ),
      ]);

      final match = router.matcher.match('/a/b');
      expect(match, isNotNull);
      expect(match!.data.views.length, 3);
    });

    test('supports multiple top-level inlets', () {
      final router = _router([
        Inlet(name: 'landing', path: '/', view: _view),
        Inlet(name: 'login', path: '/login', view: _view),
        Inlet(
          path: '/workspace',
          view: _view,
          children: [
            Inlet(name: 'workspaceHome', path: '', view: _view),
            Inlet(name: 'projects', path: 'projects/:id', view: _view),
          ],
        ),
      ]);

      final landing = router.matcher.match('/');
      final login = router.matcher.match('/login');
      final workspaceHome = router.matcher.match('/workspace');
      final project = router.matcher.match('/workspace/projects/7');

      expect(landing, isNotNull);
      expect(landing!.data.views.length, 1);
      expect(login, isNotNull);
      expect(login!.data.views.length, 1);
      expect(workspaceHome, isNotNull);
      expect(workspaceHome!.data.views.length, 2);
      expect(project, isNotNull);
      expect(project!.params, {'id': '7'});
    });

    test('meta merges from parent to child', () {
      final router = _router([
        Inlet(
          view: _view,
          meta: const {'layout': 'shell'},
          children: [
            Inlet(path: 'admin', view: _view, meta: const {'title': 'Admin'}),
          ],
        ),
      ]);

      final match = router.matcher.match('/admin');
      expect(match!.data.meta, {'layout': 'shell', 'title': 'Admin'});
    });

    test('child meta overrides parent meta with same key', () {
      final router = _router([
        Inlet(
          view: _view,
          meta: const {'title': 'Root'},
          children: [
            Inlet(path: 'page', view: _view, meta: const {'title': 'Page'}),
          ],
        ),
      ]);

      final match = router.matcher.match('/page');
      expect(match!.data.meta, {'title': 'Page'});
    });

    test('middleware chain is global + parent + child', () {
      final router = _router(
        [
          Inlet(
            view: _view,
            middleware: [_passthrough1],
            children: [
              Inlet(path: 'page', view: _view, middleware: [_passthrough2]),
            ],
          ),
        ],
        middleware: [_passthrough0],
      );

      final match = router.matcher.match('/page');
      expect(match!.data.middleware.length, 3);
      expect(
        match.data.middleware.toList(),
        orderedEquals([_passthrough0, _passthrough1, _passthrough2]),
      );
    });

    test('throws on duplicate alias mapping to different paths', () {
      expect(
        () => _router([
          Inlet(
            view: _view,
            children: [
              Inlet(name: 'same', path: 'a', view: _view),
              Inlet(name: 'same', path: 'b', view: _view),
            ],
          ),
        ]),
        throwsStateError,
      );
    });

    test('throws on duplicate path with conflicting views', () {
      expect(
        () => _router([
          Inlet(
            view: _view,
            children: [
              Inlet(path: 'a', view: _view),
              Inlet(path: 'a', view: _view2),
            ],
          ),
        ]),
        throwsStateError,
      );
    });

    test('throws on duplicate path with conflicting middleware', () {
      expect(
        () => _router([
          Inlet(
            view: _view,
            children: [
              Inlet(path: 'a', view: _view, middleware: [_passthrough0]),
              Inlet(path: 'a', view: _view, middleware: [_passthrough1]),
            ],
          ),
        ]),
        throwsStateError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Named Navigation
  // ---------------------------------------------------------------------------

  group('Named navigation', () {
    test('push by name resolves to correct path', () async {
      final router = _navRouter();
      await router.push('profile', params: {'id': '42'});
      expect(router.history.location.path, '/users/42');
    });

    test('push by name with query', () async {
      final router = _navRouter();
      await router.push(
        'search',
        query: URLSearchParams(const {'q': 'dart', 'page': '1'}),
      );
      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=dart&page=1');
    });

    test('push by name with state', () async {
      final router = _navRouter();
      await router.push('home', state: 'from-test');
      expect(router.history.location.state, 'from-test');
    });

    test('wildcard named route fills param', () async {
      final router = _navRouter();
      await router.push(
        'docs',
        params: const {'wildcard': 'guide/getting-started'},
      );
      expect(router.history.location.path, '/docs/guide/getting-started');
    });

    test('throws on unknown route name', () async {
      final router = _navRouter();
      await expectLater(router.push('nonexistent'), throwsStateError);
    });

    test('throws on missing required param', () async {
      final router = _navRouter();
      await expectLater(router.push('profile'), throwsArgumentError);
    });

    test('throws on extra unexpected params', () async {
      final router = _navRouter();
      await expectLater(
        router.push('profile', params: {'id': '1', 'extra': 'x'}),
        throwsArgumentError,
      );
    });

    test('throws when param value contains /', () async {
      final router = _navRouter();
      await expectLater(
        router.push('profile', params: {'id': '1/2'}),
        throwsArgumentError,
      );
    });

    test('throws when wildcard param is missing', () async {
      final router = _navRouter();
      await expectLater(router.push('docs'), throwsArgumentError);
    });
  });

  // ---------------------------------------------------------------------------
  // Path Navigation
  // ---------------------------------------------------------------------------

  group('Path navigation', () {
    test('push by absolute path', () async {
      final router = _navRouter();
      await router.push('/search?q=flutter');
      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=flutter');
    });

    test('explicit query overrides path query', () async {
      final router = _navRouter();
      await router.push(
        '/search?q=old',
        query: URLSearchParams(const {'q': 'new'}),
      );
      expect(router.history.location.uri.query, 'q=new');
    });

    test('throws on unknown absolute path', () async {
      final router = _navRouter();
      await expectLater(router.push('/not/found'), throwsStateError);
    });

    test('rejects params with absolute path', () async {
      final router = _navRouter();
      await expectLater(
        router.push('/search', params: {'id': '1'}),
        throwsArgumentError,
      );
    });

    test('normalizes trailing slash', () async {
      final router = _navRouter();
      await router.push('/search/');
      expect(router.history.location.path, '/search');
    });
  });

  // ---------------------------------------------------------------------------
  // Replace
  // ---------------------------------------------------------------------------

  group('Replace', () {
    test('replace does not grow history', () async {
      final router = _navRouter();
      await router.push('search');
      final indexAfterPush = router.history.index;
      await router.replace('home');
      expect(router.history.index, indexAfterPush);
    });

    test('replace updates location', () async {
      final router = _navRouter();
      await router.replace(
        'search',
        query: URLSearchParams(const {'q': 'test'}),
        state: 'replaced',
      );
      expect(router.history.location.path, '/search');
      expect(router.history.location.uri.query, 'q=test');
      expect(router.history.location.state, 'replaced');
    });

    test('replace throws on unknown route name', () async {
      final router = _navRouter();
      await expectLater(router.replace('missing'), throwsStateError);
    });

    test('replace throws on unknown absolute path', () async {
      final router = _navRouter();
      await expectLater(router.replace('/missing'), throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // History Traversal
  // ---------------------------------------------------------------------------

  group('History traversal', () {
    test('home -> profile -> search keeps expected location', () async {
      final router = _navRouter();

      await router.push('home', state: 'home');
      expect(router.history.location.path, '/');
      expect(router.history.index, 1);

      await router.push(
        'profile',
        params: const {'id': '42'},
        state: 'profile',
      );
      expect(router.history.location.path, '/users/42');
      expect(router.history.index, 2);

      await router.push('search', state: 'search');
      expect(router.history.location.path, '/search');
      expect(router.history.location.state, 'search');
      expect(router.history.index, 3);
    });

    test('back returns to previous location', () async {
      final router = _navRouter();
      await router.push('profile', params: const {'id': '7'});
      await router.push('search');
      expect(router.history.location.path, '/search');

      router.back();
      expect(router.history.location.path, '/users/7');
    });

    test('forward reverses a back', () async {
      final router = _navRouter();
      await router.push('search');
      router.back();
      expect(router.history.location.path, '/');

      router.forward();
      expect(router.history.location.path, '/search');
    });

    test('go(delta) jumps multiple entries', () async {
      final router = _navRouter();
      await router.push('profile', params: const {'id': '1'});
      await router.push('search');
      expect(router.history.location.path, '/search');

      router.go(-2);
      expect(router.history.location.path, '/');
    });

    test('state is restored when moving back and forward', () async {
      final router = _navRouter();
      await router.push('home', state: 'home-state');
      await router.push('search', state: 'search-state');
      expect(router.history.location.state, 'search-state');

      router.back();
      expect(router.history.location.path, '/');
      expect(router.history.location.state, 'home-state');

      router.forward();
      expect(router.history.location.path, '/search');
      expect(router.history.location.state, 'search-state');
    });

    test('push after back truncates forward history', () async {
      final router = _navRouter();
      await router.push('profile', params: const {'id': '1'});
      await router.push('search');
      expect(router.history.index, 2);

      router.back();
      expect(router.history.location.path, '/users/1');
      expect(router.history.index, 1);

      await router.push('docs', params: const {'wildcard': 'guide/start'});
      expect(router.history.location.path, '/docs/guide/start');
      expect(router.history.index, 2);

      router.forward();
      expect(router.history.location.path, '/docs/guide/start');
      expect(router.history.index, 2);
    });

    test('go clamps to history boundaries', () async {
      final router = _navRouter();
      await router.push('profile', params: const {'id': '1'});
      await router.push('search');

      router.go(-999);
      expect(router.history.location.path, '/');
      expect(router.history.index, 0);

      router.go(999);
      expect(router.history.location.path, '/search');
      expect(router.history.index, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Listener Notifications
  // ---------------------------------------------------------------------------

  group('Listener notifications', () {
    test('push notifies listeners', () async {
      final router = _navRouter();
      var notified = false;
      router.addListener(() => notified = true);

      await router.push('search');
      expect(notified, isTrue);
    });

    test('replace notifies listeners when location changes', () async {
      final router = _navRouter();
      var count = 0;
      router.addListener(() => count++);

      await router.replace('search');
      expect(count, 1);
    });

    test('replace to same location does not notify', () async {
      final router = _navRouter();
      var count = 0;
      router.addListener(() => count++);

      await router.replace('/');
      expect(count, 0);
    });

    test('back notifies listeners', () async {
      final router = _navRouter();
      await router.push('search');
      var notified = false;
      router.addListener(() => notified = true);

      router.back();
      expect(notified, isTrue);
    });

    test('forward and go notify listeners', () async {
      final router = _navRouter();
      await router.push('search');
      router.back();

      var count = 0;
      router.addListener(() => count++);
      router.forward();
      router.go(-1);
      expect(count, 2);
    });

    test('back at root does not notify', () {
      final router = _navRouter();
      var notified = false;
      router.addListener(() => notified = true);
      router.back();
      expect(notified, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  group('Lifecycle', () {
    test('dispose detaches history listener', () async {
      final router = _navRouter();
      var count = 0;
      router.addListener(() => count++);

      await router.push('search');
      expect(count, 1);

      router.dispose();
      router.back();
      expect(count, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // RouteParams
  // ---------------------------------------------------------------------------

  group('RouteParams', () {
    test('required returns value when present', () {
      final params = RouteParams(const {'id': '42'});
      expect(params.required('id'), '42');
    });

    test('required throws when param is missing', () {
      final params = RouteParams(const {});
      expect(() => params.required('id'), throwsArgumentError);
    });

    test('map access works as expected', () {
      final params = RouteParams(const {'a': '1', 'b': '2'});
      expect(params['a'], '1');
      expect(params['b'], '2');
      expect(params['c'], isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _view() => const SizedBox.shrink();
Widget _view2() => const Text('different', textDirection: TextDirection.ltr);

FutureOr<Widget> _passthrough0(BuildContext _, Next next) => next();
FutureOr<Widget> _passthrough1(BuildContext _, Next next) => next();
FutureOr<Widget> _passthrough2(BuildContext _, Next next) => next();

Unrouter _router(List<Inlet> routes, {Iterable<Middleware>? middleware}) {
  return createRouter(routes: routes, middleware: middleware);
}

Unrouter _navRouter() {
  return createRouter(
    routes: [
      Inlet(
        view: _view,
        children: [
          Inlet(name: 'home', view: _view),
          Inlet(name: 'profile', path: 'users/:id', view: _view),
          Inlet(name: 'search', path: 'search', view: _view),
          Inlet(name: 'docs', path: 'docs/*', view: _view),
        ],
      ),
    ],
  );
}
