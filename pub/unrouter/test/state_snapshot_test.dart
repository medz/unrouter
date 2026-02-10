import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('StateSnapshot flags and cast keep route state', () {
    final matched = StateSnapshot<AppRoute>(
      uri: Uri(path: '/home'),
      historyState: const {'source': 'test'},
      route: const HomeRoute(),
      resolution: RouteResolutionType.matched,
      routePath: '/home',
      routeName: 'home',
      error: null,
      stackTrace: null,
      lastAction: HistoryAction.replace,
      lastDelta: null,
      historyIndex: 0,
    );

    expect(matched.isPending, isFalse);
    expect(matched.isMatched, isTrue);
    expect(matched.isUnmatched, isFalse);
    expect(matched.isBlocked, isFalse);
    expect(matched.hasError, isFalse);

    final typed = matched.cast<HomeRoute>();
    expect(typed.route, isA<HomeRoute>());
    expect(typed.uri.path, '/home');
    expect(typed.routePath, '/home');
    expect(typed.routeName, 'home');
    expect(typed.historyState, const {'source': 'test'});
  });

  test('StateSnapshot cast throws for incompatible route type', () {
    final snapshot = StateSnapshot<AppRoute>(
      uri: Uri(path: '/other'),
      historyState: null,
      route: const OtherRoute(),
      resolution: RouteResolutionType.matched,
      routePath: '/other',
      routeName: 'other',
      error: null,
      stackTrace: null,
      lastAction: HistoryAction.push,
      lastDelta: null,
      historyIndex: 1,
    );

    expect(() => snapshot.cast<HomeRoute>(), throwsA(isA<TypeError>()));
  });

  test('StateSnapshot flags for pending/unmatched/blocked/error', () {
    final pending = StateSnapshot<AppRoute>(
      uri: Uri(path: '/pending'),
      historyState: null,
      route: null,
      resolution: RouteResolutionType.pending,
      routePath: null,
      routeName: null,
      error: null,
      stackTrace: null,
      lastAction: HistoryAction.replace,
      lastDelta: null,
      historyIndex: 0,
    );
    expect(pending.isPending, isTrue);

    final unmatched = StateSnapshot<AppRoute>(
      uri: Uri(path: '/404'),
      historyState: null,
      route: null,
      resolution: RouteResolutionType.unmatched,
      routePath: null,
      routeName: null,
      error: null,
      stackTrace: null,
      lastAction: HistoryAction.replace,
      lastDelta: null,
      historyIndex: 0,
    );
    expect(unmatched.isUnmatched, isTrue);

    final blocked = StateSnapshot<AppRoute>(
      uri: Uri(path: '/blocked'),
      historyState: null,
      route: null,
      resolution: RouteResolutionType.blocked,
      routePath: null,
      routeName: null,
      error: null,
      stackTrace: null,
      lastAction: HistoryAction.replace,
      lastDelta: null,
      historyIndex: 0,
    );
    expect(blocked.isBlocked, isTrue);

    final errored = StateSnapshot<AppRoute>(
      uri: Uri(path: '/error'),
      historyState: null,
      route: null,
      resolution: RouteResolutionType.error,
      routePath: null,
      routeName: null,
      error: StateError('boom'),
      stackTrace: StackTrace.current,
      lastAction: HistoryAction.replace,
      lastDelta: null,
      historyIndex: 0,
    );
    expect(errored.hasError, isTrue);
  });
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/home');
}

final class OtherRoute extends AppRoute {
  const OtherRoute();

  @override
  Uri toUri() => Uri(path: '/other');
}
