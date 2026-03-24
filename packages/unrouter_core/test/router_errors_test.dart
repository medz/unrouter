import 'package:test/test.dart';
import 'package:unrouter_core/unrouter_core.dart';

import 'support/fakes.dart';

void main() {
  group('router errors', () {
    test('throws when maxRedirectDepth is not positive', () {
      expect(
        () => createRouter<Object>(
          maxRedirectDepth: 0,
          routes: [RouteNode(path: '/', view: emptyView)],
        ),
        throwsArgumentErrorContaining(
          'maxRedirectDepth must be greater than 0',
        ),
      );
    });

    test('throws on duplicate alias with different target paths', () {
      expect(
        () => createRouter<Object>(
          routes: [
            RouteNode(
              path: '/',
              view: emptyView,
              children: [
                RouteNode(name: 'same', path: 'a', view: emptyView),
                RouteNode(name: 'same', path: 'b', view: emptyView),
              ],
            ),
          ],
        ),
        throwsStateErrorContaining('Duplicate route alias'),
      );
    });

    test('throws on duplicate route view conflict', () {
      expect(
        () => createRouter<Object>(
          routes: [
            RouteNode(
              path: '/',
              view: emptyView,
              children: [
                RouteNode(path: 'same', view: emptyView),
                RouteNode(path: 'same', view: altEmptyView),
              ],
            ),
          ],
        ),
        throwsStateErrorContaining('Duplicate route views'),
      );
    });

    test('throws on duplicate route guards conflict', () {
      final allow = defineGuard((_) => const GuardResult.allow());
      expect(
        () => createRouter<Object>(
          routes: [
            RouteNode(
              path: '/',
              view: emptyView,
              children: [
                RouteNode(path: 'same', view: emptyView),
                RouteNode(path: 'same', view: emptyView, guards: [allow]),
              ],
            ),
          ],
        ),
        throwsStateErrorContaining('Duplicate route guards'),
      );
    });

    test('throws when pathOrName is empty', () {
      final router = createRouter<Object>(
        routes: [RouteNode(path: '/', view: emptyView)],
      );
      expect(
        router.push(''),
        throwsArgumentErrorContaining('must not be empty'),
      );
    });

    test('throws for unknown route name', () {
      final router = createRouter<Object>(
        routes: [RouteNode(path: '/', view: emptyView)],
      );
      expect(
        router.push('missing-name'),
        throwsStateErrorContaining('Route name "missing-name" was not found'),
      );
    });

    test('throws when path navigation receives params', () {
      final router = createRouter<Object>(
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(path: '/a', view: emptyView),
        ],
      );
      expect(
        router.push('/a', params: {'id': '1'}),
        throwsArgumentErrorContaining('Path navigation does not accept params'),
      );
    });

    test('throws when location path has no route match', () {
      final router = createRouter<Object>(
        routes: [RouteNode(path: '/', view: emptyView)],
      );
      expect(
        router.push('/missing'),
        throwsStateErrorContaining('No route matched path'),
      );
    });

    test('throws when required param is missing', () {
      final router = createRouter<Object>(
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(name: 'profile', path: '/users/:id', view: emptyView),
        ],
      );
      expect(
        router.push('profile'),
        throwsArgumentErrorContaining('Missing required param "id"'),
      );
    });

    test('throws when wildcard param is missing', () {
      final router = createRouter<Object>(
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(name: 'docs', path: '/docs/**:wildcard', view: emptyView),
        ],
      );
      expect(
        router.push('docs'),
        throwsArgumentErrorContaining('Missing required param "wildcard"'),
      );
    });

    test('throws when single-segment wildcard contains slash', () {
      final router = createRouter<Object>(
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(name: 'file', path: '/files/*', view: emptyView),
        ],
      );
      expect(
        router.push('file', params: {'wildcard': 'guide/getting-started'}),
        throwsArgumentErrorContaining(
          'Single-segment wildcard "wildcard" must not be empty or contain "/"',
        ),
      );
    });

    test('throws when param contains slash', () {
      final router = createRouter<Object>(
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(name: 'profile', path: '/users/:id', view: emptyView),
        ],
      );
      expect(
        router.push('profile', params: {'id': 'a/b'}),
        throwsArgumentErrorContaining('must not contain "/"'),
      );
    });

    test('throws when extra params are passed', () {
      final router = createRouter<Object>(
        routes: [
          RouteNode(path: '/', view: emptyView),
          RouteNode(name: 'profile', path: '/users/:id', view: emptyView),
        ],
      );
      expect(
        router.push('profile', params: {'id': '42', 'extra': 'x'}),
        throwsArgumentErrorContaining('Unexpected params'),
      );
    });
  });
}
