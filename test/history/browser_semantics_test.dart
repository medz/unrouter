import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Browser History Semantics', () {
    test('push does NOT trigger listeners', () {
      final history = MemoryHistory('/');
      var listenerCalled = false;

      history.listen((to, from, info) {
        listenerCalled = true;
      });

      // Push should NOT trigger listener (following pushState semantics)
      history.push('/about');

      expect(
        listenerCalled,
        false,
        reason: 'push should not trigger listeners',
      );
      expect(history.location, '/about', reason: 'but location should update');
    });

    test('replace does NOT trigger listeners', () {
      final history = MemoryHistory('/');
      history.push('/page1');

      var listenerCalled = false;
      history.listen((to, from, info) {
        listenerCalled = true;
      });

      // Replace should NOT trigger listener (following replaceState semantics)
      history.replace('/page2');

      expect(
        listenerCalled,
        false,
        reason: 'replace should not trigger listeners',
      );
      expect(history.location, '/page2', reason: 'but location should update');
    });

    test('back DOES trigger listeners', () {
      final history = MemoryHistory('/');
      history.push('/page1');
      history.push('/page2');

      var listenerCalled = false;
      String? capturedTo;
      String? capturedFrom;

      history.listen((to, from, info) {
        listenerCalled = true;
        capturedTo = to;
        capturedFrom = from;
      });

      // Back should trigger listener (following popstate semantics)
      history.back();

      expect(listenerCalled, true, reason: 'back should trigger listeners');
      expect(capturedTo, '/page1');
      expect(capturedFrom, '/page2');
    });

    test('forward DOES trigger listeners', () {
      final history = MemoryHistory('/');
      history.push('/page1');
      history.push('/page2');
      history.back();

      var listenerCalled = false;
      String? capturedTo;

      history.listen((to, from, info) {
        listenerCalled = true;
        capturedTo = to;
      });

      // Forward should trigger listener (following popstate semantics)
      history.forward();

      expect(listenerCalled, true, reason: 'forward should trigger listeners');
      expect(capturedTo, '/page2');
    });

    test('go DOES trigger listeners', () {
      final history = MemoryHistory('/');
      history.push('/page1');
      history.push('/page2');
      history.push('/page3');

      var listenerCalled = false;
      String? capturedTo;

      history.listen((to, from, info) {
        listenerCalled = true;
        capturedTo = to;
      });

      // Go should trigger listener (following popstate semantics)
      history.go(-2);

      expect(listenerCalled, true, reason: 'go should trigger listeners');
      expect(capturedTo, '/page1');
    });

    test('listener receives correct NavigationInformation', () {
      final history = MemoryHistory('/');
      history.push('/page1');
      history.push('/page2');

      NavigationInformation? capturedInfo;

      history.listen((to, from, info) {
        capturedInfo = info;
      });

      history.back();

      expect(capturedInfo, isNotNull);
      expect(capturedInfo!.type, NavigationType.pop);
      expect(capturedInfo!.direction, NavigationDirection.back);
      expect(capturedInfo!.delta, -1);
    });
  });
}
