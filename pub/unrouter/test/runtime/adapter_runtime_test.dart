import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('cast helpers return typed records and shell hosts', () {
    final record = _RouteRecord(path: '/');
    final shellRecord = _ShellRecord(path: '/shell');

    expect(castRouteRecord<_AppRoute, _RouteRecord>(record), same(record));
    expect(castRouteRecord<_AppRoute, _ShellRecord>(record), isNull);

    expect(castShellRouteRecordHost<_AppRoute>(shellRecord), same(shellRecord));
    expect(castShellRouteRecordHost<_AppRoute>(record), isNull);
  });

  test('resolveRouteResolution dispatches callbacks by lifecycle state', () {
    final matched = RouteResolution<_AppRoute>.matched(
      uri: Uri(path: '/'),
      record: _RouteRecord(path: '/'),
      route: const _AppRoute('/'),
    );
    final blocked = RouteResolution<_AppRoute>.blocked(Uri(path: '/blocked'));
    final pending = RouteResolution<_AppRoute>.pending(Uri(path: '/pending'));
    final redirect = RouteResolution<_AppRoute>.redirect(
      uri: Uri(path: '/old'),
      redirectUri: Uri(path: '/new'),
    );
    final unmatched = RouteResolution<_AppRoute>.unmatched(Uri(path: '/404'));
    final errored = RouteResolution<_AppRoute>.error(
      uri: Uri(path: '/error'),
      error: StateError('boom'),
      stackTrace: StackTrace.current,
    );

    expect(
      resolveRouteResolution<_AppRoute, String>(
        resolution: pending,
        onPending: (_) => 'pending',
        onMatched: (_) => 'matched',
        onBlocked: (_) => 'blocked',
        onUnmatched: (_) => 'unmatched',
        onError: (_) => 'error',
      ),
      'pending',
    );
    expect(
      resolveRouteResolution<_AppRoute, String>(
        resolution: matched,
        onPending: (_) => 'pending',
        onMatched: (_) => 'matched',
        onBlocked: (_) => 'blocked',
        onUnmatched: (_) => 'unmatched',
        onError: (_) => 'error',
      ),
      'matched',
    );
    expect(
      resolveRouteResolution<_AppRoute, String>(
        resolution: blocked,
        onPending: (_) => 'pending',
        onMatched: (_) => 'matched',
        onBlocked: (_) => 'blocked',
        onUnmatched: (_) => 'unmatched',
        onError: (_) => 'error',
      ),
      'blocked',
    );
    expect(
      resolveRouteResolution<_AppRoute, String>(
        resolution: redirect,
        onPending: (_) => 'pending',
        onMatched: (_) => 'matched',
        onBlocked: (_) => 'blocked',
        onUnmatched: (_) => 'unmatched',
        onError: (_) => 'error',
        onRedirect: (_) => 'redirect',
      ),
      'redirect',
    );
    expect(
      resolveRouteResolution<_AppRoute, String>(
        resolution: redirect,
        onPending: (_) => 'pending',
        onMatched: (_) => 'matched',
        onBlocked: (_) => 'blocked',
        onUnmatched: (_) => 'unmatched',
        onError: (_) => 'error',
      ),
      'unmatched',
    );
    expect(
      resolveRouteResolution<_AppRoute, String>(
        resolution: unmatched,
        onPending: (_) => 'pending',
        onMatched: (_) => 'matched',
        onBlocked: (_) => 'blocked',
        onUnmatched: (_) => 'unmatched',
        onError: (_) => 'error',
      ),
      'unmatched',
    );
    expect(
      resolveRouteResolution<_AppRoute, String>(
        resolution: errored,
        onPending: (_) => 'pending',
        onMatched: (_) => 'matched',
        onBlocked: (_) => 'blocked',
        onUnmatched: (_) => 'unmatched',
        onError: (_) => 'error',
      ),
      'error',
    );
  });

  test('syncControllerResolution clears stale shell composer', () async {
    final history = MemoryHistory(
      initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/'))],
      initialIndex: 0,
    );
    final controller = UnrouterController<_AppRoute>(
      router: Unrouter<_AppRoute>(
        routes: <RouteRecord<_AppRoute>>[_RouteRecord(path: '/')],
      ),
      history: history,
      resolveInitialRoute: true,
      disposeHistory: false,
    );
    addTearDown(controller.dispose);

    await controller.idle;
    controller.setHistoryStateComposer((request) {
      return <String, Object?>{'wrapped': request.state};
    });

    final resolution = syncControllerResolution(controller);
    expect(resolution.isMatched, isTrue);

    controller.goUri(Uri(path: '/'), state: 'raw');
    await controller.idle;

    expect(history.location.state, 'raw');
  });
}

final class _AppRoute implements RouteData {
  const _AppRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}

class _RouteRecord implements RouteRecord<_AppRoute> {
  _RouteRecord({required this.path}) : parse = ((_) => _AppRoute(path));

  @override
  final String path;

  @override
  final RouteParser<_AppRoute> parse;

  @override
  String? get name => null;

  @override
  Future<Uri?> runRedirect(RouteContext<RouteData> context) async => null;

  @override
  Future<RouteGuardResult> runGuards(RouteContext<RouteData> context) async {
    return RouteGuardResult.allow();
  }
}

final class _ShellRecord extends _RouteRecord
    implements ShellRouteRecordHost {
  _ShellRecord({required super.path});

  @override
  bool canPopBranch() => false;

  @override
  Uri? popBranch({Object? result}) => null;

  @override
  // ignore: unused_element_parameter
  Uri resolveBranchTarget(int index, {bool initialLocation = false}) {
    return Uri(path: '/shell');
  }
}
