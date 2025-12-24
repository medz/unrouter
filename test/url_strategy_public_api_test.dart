import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('UrlStrategy is exposed in the public API', () {
    expect(
      UrlStrategy.values,
      containsAll(<UrlStrategy>[UrlStrategy.browser, UrlStrategy.hash]),
    );
  });
}
