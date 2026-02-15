import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('createRouter route table', () {
    test('builds aliases, merged meta, views, and middleware chain', () {
      final global = defineMiddleware((context, next) => next());
      final parent = defineMiddleware((context, next) => next());
      final child = defineMiddleware((context, next) => next());

      final router = createRouter(
        middleware: [global],
        routes: [
          Inlet(
            path: '/',
            view: _rootView,
            middleware: [parent],
            meta: const {'layout': 'shell'},
            children: [
              Inlet(
                name: 'profile',
                path: 'users/:id',
                view: _profileView,
                middleware: [child],
                meta: const {'title': 'Profile'},
              ),
            ],
          ),
        ],
      );

      final alias = router.aliases.match('/profile');
      expect(alias, isNotNull);
      expect(alias!.data, '/users/:id');

      final match = router.matcher.match('/users/42');
      expect(match, isNotNull);
      expect(match!.params?['id'], '42');
      expect(match.data.views.length, 2);
      expect(match.data.middleware.length, 3);
      expect(match.data.meta, const {'layout': 'shell', 'title': 'Profile'});
    });

    test('throws on duplicate alias', () {
      expect(
        () => createRouter(
          routes: [
            Inlet(
              path: '/',
              view: _rootView,
              children: [
                Inlet(name: 'same', path: 'a', view: _rootView),
                Inlet(name: 'same', path: 'b', view: _profileView),
              ],
            ),
          ],
        ),
        throwsStateError,
      );
    });

    test('throws on duplicate route views conflict', () {
      expect(
        () => createRouter(
          routes: [
            Inlet(
              path: '/',
              view: _rootView,
              children: [
                Inlet(path: 'a', view: _rootView),
                Inlet(path: 'a', view: _profileView),
              ],
            ),
          ],
        ),
        throwsStateError,
      );
    });

    test('throws on duplicate route middleware conflict', () {
      final guardA = defineMiddleware((context, next) => next());
      final guardB = defineMiddleware((context, next) => next());
      expect(
        () => createRouter(
          routes: [
            Inlet(
              path: '/',
              view: _rootView,
              children: [
                Inlet(path: 'a', view: _rootView, middleware: [guardA]),
                Inlet(path: 'a', view: _rootView, middleware: [guardB]),
              ],
            ),
          ],
        ),
        throwsStateError,
      );
    });
  });
}

Widget _rootView() => const SizedBox.shrink();
Widget _profileView() => const SizedBox.shrink();
