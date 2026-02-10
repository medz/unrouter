import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('redirect throws when uri and route are both missing', () {
    expect(() => RouteGuardResult.redirect(), throwsArgumentError);
  });

  test('redirect derives uri from route', () {
    final result = RouteGuardResult.redirect(route: const _Route('/next'));

    expect(result.isRedirect, isTrue);
    expect(result.uri, Uri(path: '/next'));
  });
}

final class _Route implements RouteData {
  const _Route(this.path);

  final String path;

  @override
  Uri toUri() {
    return Uri(path: path);
  }
}
