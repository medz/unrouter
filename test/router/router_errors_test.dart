import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';

Matcher throwsWith<T extends Object>(String text) {
  return throwsA(
    isA<T>().having((error) => error.toString(), 'toString', contains(text)),
  );
}

void main() {
  group('router errors', () {
    test('throws when maxRedirectDepth is not positive', () {
      expect(
        () => createRouter(
          maxRedirectDepth: 0,
          routes: [Inlet(path: '/', view: EmptyView.new)],
        ),
        throwsWith<ArgumentError>('maxRedirectDepth must be greater than 0'),
      );
    });

    test('throws on duplicate alias with different target paths', () {
      expect(
        () => createRouter(
          routes: [
            Inlet(
              path: '/',
              view: EmptyView.new,
              children: [
                Inlet(name: 'same', path: 'a', view: EmptyView.new),
                Inlet(name: 'same', path: 'b', view: EmptyView.new),
              ],
            ),
          ],
        ),
        throwsWith<StateError>('Duplicate route alias'),
      );
    });

    test('throws on duplicate route view conflict', () {
      expect(
        () => createRouter(
          routes: [
            Inlet(
              path: '/',
              view: EmptyView.new,
              children: [
                Inlet(path: 'same', view: EmptyView.new),
                Inlet(path: 'same', view: AltEmptyView.new),
              ],
            ),
          ],
        ),
        throwsWith<StateError>('Duplicate route views'),
      );
    });

    test('throws on duplicate route guards conflict', () {
      final allow = defineGuard((_) => const GuardResult.allow());
      expect(
        () => createRouter(
          routes: [
            Inlet(
              path: '/',
              view: EmptyView.new,
              children: [
                Inlet(path: 'same', view: EmptyView.new),
                Inlet(path: 'same', view: EmptyView.new, guards: [allow]),
              ],
            ),
          ],
        ),
        throwsWith<StateError>('Duplicate route guards'),
      );
    });

    test('throws when pathOrName is empty', () {
      final router = createRouter(
        routes: [Inlet(path: '/', view: EmptyView.new)],
      );
      expect(router.push(''), throwsWith<ArgumentError>('must not be empty'));
    });

    test('throws for unknown route name', () {
      final router = createRouter(
        routes: [Inlet(path: '/', view: EmptyView.new)],
      );
      expect(
        router.push('missing-name'),
        throwsWith<StateError>('Route name "missing-name" was not found'),
      );
    });

    test('throws when path navigation receives params', () {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(path: '/a', view: EmptyView.new),
        ],
      );
      expect(
        router.push('/a', params: {'id': '1'}),
        throwsWith<ArgumentError>('Path navigation does not accept params'),
      );
    });

    test('throws when location path has no route match', () {
      final router = createRouter(
        routes: [Inlet(path: '/', view: EmptyView.new)],
      );
      expect(
        router.push('/missing'),
        throwsWith<StateError>('No route matched path'),
      );
    });

    test('throws when required param is missing', () {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(name: 'profile', path: '/users/:id', view: EmptyView.new),
        ],
      );
      expect(
        router.push('profile'),
        throwsWith<ArgumentError>('Missing required param "id"'),
      );
    });

    test('throws when wildcard param is missing', () {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(name: 'docs', path: '/docs/*', view: EmptyView.new),
        ],
      );
      expect(
        router.push('docs'),
        throwsWith<ArgumentError>('Missing required param "wildcard"'),
      );
    });

    test('throws when param contains slash', () {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(name: 'profile', path: '/users/:id', view: EmptyView.new),
        ],
      );
      expect(
        router.push('profile', params: {'id': 'a/b'}),
        throwsWith<ArgumentError>('must not contain "/"'),
      );
    });

    test('throws when extra params are passed', () {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: EmptyView.new),
          Inlet(name: 'profile', path: '/users/:id', view: EmptyView.new),
        ],
      );
      expect(
        router.push('profile', params: {'id': '42', 'extra': 'x'}),
        throwsWith<ArgumentError>('Unexpected params'),
      );
    });
  });
}
