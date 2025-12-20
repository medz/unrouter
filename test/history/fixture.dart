import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';

/// Reusable test suite for History implementations.
///
/// Tests are written based on browser semantics (async popstate behavior).
/// MemoryHistory can satisfy these tests by simulating the async behavior.
void runHistoryTests(
  String description,
  History Function() createHistory, {
  bool isAsync = true, // Whether navigation (go/back/forward) is async
}) {
  group(description, () {
    late History history;

    setUp(() {
      history = createHistory();
    });

    tearDown(() {
      history.dispose();
    });

    group('Basic Navigation', () {
      test('push updates location synchronously', () {
        history.push(Uri.parse('/users'));
        expect(history.location.uri.path, '/users');
        expect(history.action, HistoryAction.push);
      });

      test('push with search and hash', () {
        history.push(Uri.parse('/search?q=flutter#results'));

        expect(history.location.uri.path, '/search');
        expect(history.location.uri.query, 'q=flutter');
        expect(history.location.uri.fragment, 'results');
        expect(history.action, HistoryAction.push);
      });

      test('replace updates location synchronously', () {
        history.push(Uri.parse('/users'));

        history.replace(Uri.parse('/posts'));

        expect(history.location.uri.path, '/posts');
        expect(history.action, HistoryAction.replace);
      });

      test('replace with state', () {
        history.push(Uri.parse('/users'), {'count': 1});
        history.replace(Uri.parse('/posts'), {'count': 2});

        expect(history.location.uri.path, '/posts');
        expect(history.location.state, {'count': 2});
      });
    });

    group('Navigation (go/back/forward)', () {
      if (isAsync) {
        test('go triggers async navigation with correct delta', () async {
          history.push(Uri.parse('/page1'));
          history.push(Uri.parse('/page2'));
          history.push(Uri.parse('/page3'));

          final completer = Completer<HistoryEvent>();
          history.listen((event) {
            if (!completer.isCompleted) {
              completer.complete(event);
            }
          });

          history.go(-2);

          final event = await completer.future.timeout(
            const Duration(seconds: 2),
            onTimeout: () => throw TimeoutException('Navigation not completed'),
          );

          expect(event.action, HistoryAction.pop);
          expect(event.location.uri.path, '/page1');
          expect(event.delta, -2);
        });

        test('back triggers async navigation', () async {
          history.push(Uri.parse('/page1'));
          history.push(Uri.parse('/page2'));

          final completer = Completer<HistoryEvent>();
          history.listen((event) {
            if (!completer.isCompleted) {
              completer.complete(event);
            }
          });

          history.back();

          final event = await completer.future.timeout(
            const Duration(seconds: 2),
            onTimeout: () => throw TimeoutException('Navigation not completed'),
          );

          expect(event.action, HistoryAction.pop);
          expect(event.location.uri.path, '/page1');
          expect(event.delta, -1);
        });

        test('forward triggers async navigation', () async {
          history.push(Uri.parse('/page1'));
          history.push(Uri.parse('/page2'));

          // First go back
          var completer = Completer<void>();
          history.listen((event) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          });
          history.back();
          await completer.future.timeout(const Duration(seconds: 2));

          // Then test forward
          final forwardCompleter = Completer<HistoryEvent>();
          history.listen((event) {
            if (!forwardCompleter.isCompleted) {
              forwardCompleter.complete(event);
            }
          });

          history.forward();

          final event = await forwardCompleter.future.timeout(
            const Duration(seconds: 2),
            onTimeout: () => throw TimeoutException('Navigation not completed'),
          );

          expect(event.action, HistoryAction.pop);
          expect(event.location.uri.path, '/page2');
          expect(event.delta, 1);
        });

        // identifier test removed - identifiers are now internal implementation details
      } else {
        // Synchronous navigation tests (for MemoryHistory)
        test('go navigates with correct delta', () {
          history.push(Uri.parse('/page1'));
          history.push(Uri.parse('/page2'));
          history.push(Uri.parse('/page3'));

          var eventReceived = false;
          HistoryEvent? lastEvent;
          history.listen((event) {
            eventReceived = true;
            lastEvent = event;
          });

          history.go(-2);

          expect(eventReceived, true);
          expect(lastEvent?.action, HistoryAction.pop);
          expect(history.location.uri.path, '/page1');
          expect(lastEvent?.delta, -2);
        });

        test('back navigates backward', () {
          history.push(Uri.parse('/page1'));
          history.push(Uri.parse('/page2'));

          var eventReceived = false;
          history.listen((event) {
            eventReceived = true;
          });

          history.back();

          expect(eventReceived, true);
          expect(history.location.uri.path, '/page1');
        });

        test('forward navigates forward', () {
          history.push(Uri.parse('/page1'));
          history.push(Uri.parse('/page2'));
          history.back();

          var eventReceived = false;
          history.listen((event) {
            eventReceived = true;
          });

          history.forward();

          expect(eventReceived, true);
          expect(history.location.uri.path, '/page2');
        });
      }
    });

    group('Listeners', () {
      test('push does NOT trigger listeners (browser semantics)', () async {
        var callCount = 0;
        history.listen((event) {
          callCount++;
        });

        history.push(Uri.parse('/page1'));

        // Wait a bit to ensure no async listener call
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callCount, 0);
        expect(history.location.uri.path, '/page1');
      });

      test('replace does NOT trigger listeners (browser semantics)', () async {
        history.push(Uri.parse('/page1'));

        var callCount = 0;
        history.listen((event) {
          callCount++;
        });

        history.replace(Uri.parse('/page2'));

        // Wait a bit to ensure no async listener call
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callCount, 0);
        expect(history.location.uri.path, '/page2');
      });

      test('multiple listeners are all called', () async {
        history.push(Uri.parse('/page1'));

        var count1 = 0;
        var count2 = 0;

        history.listen((event) {
          count1++;
        });

        history.listen((event) {
          count2++;
        });

        if (isAsync) {
          final completer = Completer<void>();
          history.listen((event) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          });
          history.back();
          await completer.future.timeout(const Duration(seconds: 2));
        } else {
          history.back();
        }

        expect(count1, 1);
        expect(count2, 1);
      });

      test('unlisten stops receiving events', () async {
        history.push(Uri.parse('/page1'));
        history.push(Uri.parse('/page2'));

        var callCount = 0;
        final unlisten = history.listen((event) {
          callCount++;
        });

        // First navigation
        if (isAsync) {
          var completer = Completer<void>();
          history.listen((event) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          });
          history.back();
          await completer.future.timeout(const Duration(seconds: 2));
        } else {
          history.back();
        }
        expect(callCount, 1);

        // Unlisten
        unlisten();

        // Second navigation (after unlisten)
        if (isAsync) {
          var completer = Completer<void>();
          history.listen((event) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          });
          history.back();
          await completer.future.timeout(const Duration(seconds: 2));
        } else {
          history.back();
        }

        expect(callCount, 1); // Should still be 1
      });
    });

    group('createHref', () {
      test('creates href with pathname', () {
        final href = history.createHref(Uri.parse('/users'));
        expect(href, contains('/users'));
      });

      test('creates href with search and hash', () {
        final href = history.createHref(Uri.parse('/search?q=test#top'));

        expect(href, contains('/search'));
        expect(href, contains('q=test'));
        expect(href, contains('top'));
      });
    });
  });
}
