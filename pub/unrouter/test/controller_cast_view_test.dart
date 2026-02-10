import 'dart:async';

import 'package:test/test.dart';
import 'package:unrouter/src/runtime/controller_cast_view.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  group('UnrouterControllerCastView', () {
    test('maps source resolution variants', () {
      final source = _FakeController<AppRoute>();
      final view = UnrouterControllerCastView<AppRoute>(source);
      final record = route<AppRoute>(
        path: '/home',
        parse: (_) => const HomeRoute('/home'),
      );

      source.resolution = RouteResolution<AppRoute>.pending(
        Uri(path: '/pending'),
      );
      expect(view.resolution.type, RouteResolutionType.pending);
      expect(view.resolution.uri.path, '/pending');

      source.resolution = RouteResolution<AppRoute>.unmatched(
        Uri(path: '/404'),
      );
      expect(view.resolution.type, RouteResolutionType.unmatched);
      expect(view.resolution.isUnmatched, isTrue);

      source.resolution = RouteResolution<AppRoute>.blocked(
        Uri(path: '/blocked'),
      );
      expect(view.resolution.type, RouteResolutionType.blocked);
      expect(view.resolution.isBlocked, isTrue);

      source.resolution = RouteResolution<AppRoute>.redirect(
        uri: Uri(path: '/from'),
        redirectUri: Uri(path: '/to'),
      );
      expect(view.resolution.type, RouteResolutionType.redirect);
      expect(view.resolution.redirectUri, Uri(path: '/to'));

      source.resolution = RouteResolution<AppRoute>.error(
        uri: Uri(path: '/oops'),
        error: StateError('boom'),
        stackTrace: StackTrace.current,
      );
      expect(view.resolution.type, RouteResolutionType.error);
      expect(view.resolution.hasError, isTrue);

      source.resolution = RouteResolution<AppRoute>.matched(
        uri: Uri(path: '/home'),
        record: record,
        route: const HomeRoute('/home'),
        loaderData: 'loaded',
      );
      expect(view.resolution.type, RouteResolutionType.matched);
      expect(view.resolution.route, isA<HomeRoute>());
      expect(view.resolution.record?.path, '/home');
      expect(view.resolution.loaderData, 'loaded');
    });

    test('forwards navigation and state stream', () async {
      final source = _FakeController<AppRoute>();
      final view = UnrouterControllerCastView<HomeRoute>(source);
      source.route = const HomeRoute('/home');
      source.state = _snapshot<AppRoute>(
        uri: Uri(path: '/home'),
        route: const HomeRoute('/home'),
      );

      expect(view.route, isA<HomeRoute>());
      expect(view.state.route, isA<HomeRoute>());

      final streamedState = view.states.first;
      source.emitState(
        _snapshot<AppRoute>(
          uri: Uri(path: '/next'),
          route: const HomeRoute('/next'),
        ),
      );
      expect((await streamedState).uri.path, '/next');

      view.go(const HomeRoute('/go'), state: const {'k': 'v'});
      expect(source.lastGoRoute, isA<HomeRoute>());
      expect(source.lastGoState, const {'k': 'v'});

      view.goUri(Uri(path: '/go-uri'), state: 7);
      expect(source.lastGoUri, Uri(path: '/go-uri'));
      expect(source.lastGoUriState, 7);

      final pushed = await view.push<int>(const HomeRoute('/push'), state: 's');
      expect(pushed, 99);
      expect(source.lastPushRoute, isA<HomeRoute>());
      expect(source.lastPushState, 's');

      final pushedUri = await view.pushUri<int>(
        Uri(path: '/push-uri'),
        state: 11,
      );
      expect(pushedUri, 99);
      expect(source.lastPushUri, Uri(path: '/push-uri'));
      expect(source.lastPushUriState, 11);

      expect(view.pop(1), isTrue);
      expect(source.lastPopResult, 1);

      expect(view.back(), isTrue);
      expect(source.backCalled, isTrue);

      expect(
        view.switchBranch(
          2,
          initialLocation: true,
          completePendingResult: true,
          result: 'done',
        ),
        isTrue,
      );
      expect(source.lastSwitchBranchIndex, 2);
      expect(source.lastSwitchInitialLocation, isTrue);
      expect(source.lastSwitchCompletePendingResult, isTrue);
      expect(source.lastSwitchResult, 'done');

      expect(view.popBranch('branch-result'), isTrue);
      expect(source.lastPopBranchResult, 'branch-result');

      await view.sync(Uri(path: '/sync'), state: const {'s': 1});
      expect(source.lastSyncUri, Uri(path: '/sync'));
      expect(source.lastSyncState, const {'s': 1});

      expect(view.href(const HomeRoute('/href')), '/href');

      view.dispose();
      expect(source.disposeCalled, isTrue);
    });

    test('cast returns source when target matches source type', () {
      final source = _FakeController<AppRoute>();
      final view = UnrouterControllerCastView<HomeRoute>(source);

      expect(view.cast<AppRoute>(), same(source));
      expect(view.cast<OtherRoute>(), isNot(same(source)));
    });

    test('route getter throws when route type is incompatible', () {
      final source = _FakeController<AppRoute>()
        ..route = const OtherRoute('/x');
      final view = UnrouterControllerCastView<HomeRoute>(source);

      expect(() => view.route, throwsA(isA<TypeError>()));
    });
  });
}

StateSnapshot<R> _snapshot<R extends RouteData>({
  required Uri uri,
  required R route,
}) {
  return StateSnapshot<R>(
    uri: uri,
    historyState: null,
    route: route,
    resolution: RouteResolutionType.matched,
    routePath: route.toUri().path,
    routeName: null,
    error: null,
    stackTrace: null,
    lastAction: HistoryAction.replace,
    lastDelta: null,
    historyIndex: 0,
  );
}

class _FakeController<R extends RouteData> implements UnrouterController<R> {
  _FakeController()
    : uri = Uri(path: '/'),
      state = StateSnapshot<R>(
        uri: Uri(path: '/'),
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
      ),
      resolution = RouteResolution<R>.pending(Uri(path: '/'));

  final StreamController<StateSnapshot<R>> _statesController =
      StreamController<StateSnapshot<R>>.broadcast();

  @override
  R? route;

  @override
  Uri uri;

  @override
  StateSnapshot<R> state;

  @override
  RouteResolution<R> resolution;

  R? lastGoRoute;
  Object? lastGoState;
  Uri? lastGoUri;
  Object? lastGoUriState;
  R? lastPushRoute;
  Object? lastPushState;
  Uri? lastPushUri;
  Object? lastPushUriState;
  Object? lastPopResult;
  bool backCalled = false;
  int? lastSwitchBranchIndex;
  bool? lastSwitchInitialLocation;
  bool? lastSwitchCompletePendingResult;
  Object? lastSwitchResult;
  Object? lastPopBranchResult;
  Uri? lastSyncUri;
  Object? lastSyncState;
  bool disposeCalled = false;

  @override
  Stream<StateSnapshot<R>> get states => _statesController.stream;

  @override
  Future<void> get idle => Future<void>.value();

  void emitState(StateSnapshot<R> snapshot) {
    state = snapshot;
    route = snapshot.route;
    uri = snapshot.uri;
    _statesController.add(snapshot);
  }

  @override
  String href(R route) {
    return route.toUri().toString();
  }

  @override
  void go(R route, {Object? state}) {
    lastGoRoute = route;
    lastGoState = state;
  }

  @override
  void goUri(Uri uri, {Object? state}) {
    lastGoUri = uri;
    lastGoUriState = state;
  }

  @override
  Future<T?> push<T extends Object?>(R route, {Object? state}) {
    lastPushRoute = route;
    lastPushState = state;
    return Future<T?>.value(99 as T);
  }

  @override
  Future<T?> pushUri<T extends Object?>(Uri uri, {Object? state}) {
    lastPushUri = uri;
    lastPushUriState = state;
    return Future<T?>.value(99 as T);
  }

  @override
  bool pop<T extends Object?>([T? result]) {
    lastPopResult = result;
    return true;
  }

  @override
  bool back() {
    backCalled = true;
    return true;
  }

  @override
  bool switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    lastSwitchBranchIndex = index;
    lastSwitchInitialLocation = initialLocation;
    lastSwitchCompletePendingResult = completePendingResult;
    lastSwitchResult = result;
    return true;
  }

  @override
  bool popBranch([Object? result]) {
    lastPopBranchResult = result;
    return true;
  }

  @override
  UnrouterController<S> cast<S extends RouteData>() {
    if (this is UnrouterController<S>) {
      return this as UnrouterController<S>;
    }
    throw UnsupportedError('Not used in this fake controller.');
  }

  @override
  Future<void> sync(Uri uri, {Object? state}) {
    lastSyncUri = uri;
    lastSyncState = state;
    return Future<void>.value();
  }

  @override
  void dispose() {
    disposeCalled = true;
    _statesController.close();
  }
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}

final class OtherRoute extends AppRoute {
  const OtherRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}
