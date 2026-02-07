import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('RouteParserState exposes path and query helpers', () {
    final state = RouteParserState(
      uri: Uri(
        path: '/users/42',
        queryParameters: {'tab': 'likes', 'page': '2'},
      ),
      pathParameters: const {'id': '42'},
    );

    expect(state.path('id'), '42');
    expect(state.pathInt('id'), 42);
    expect(state.query('tab'), 'likes');
    expect(state.queryInt('page'), 2);
    expect(state.queryEnum('tab', _Tab.values), _Tab.likes);
  });
}

enum _Tab { posts, likes }
