import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('RouteParserState exposes typed params and query helpers', () {
    final state = RouteParserState(
      uri: Uri(
        path: '/users/42',
        queryParameters: {'tab': 'likes', 'page': '2'},
      ),
      params: const {'id': '42'},
    );

    expect(state.params['id'], '42');
    expect(state.params.required('id'), '42');
    expect(state.params.$int('id'), 42);
    expect(state.params.decode<int>('id', int.tryParse), 42);
    expect(state.query.required('tab'), 'likes');
    expect(state.query.decode<int>('page', int.tryParse), 2);
    expect(state.query.$enum('tab', _Tab.values), _Tab.likes);
  });
}

enum _Tab { posts, likes }
