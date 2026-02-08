import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('buildShellRouteRecords flattens branches and reuses one runtime', () {
    final branches = <ShellBranch<_AppRoute>>[
      branch<_AppRoute>(
        routes: <RouteRecord<_AppRoute>>[
          _TestRecord(path: '/feed', name: 'feed'),
        ],
        initialLocation: Uri(path: '/feed'),
        name: 'feed',
      ),
      branch<_AppRoute>(
        routes: <RouteRecord<_AppRoute>>[
          _TestRecord(path: '/settings', name: 'settings'),
        ],
        initialLocation: Uri(path: '/settings'),
        name: 'settings',
      ),
    ];

    final wrapped =
        buildShellRouteRecords<_AppRoute, _TestRecord, _WrappedRecord>(
          branches: branches,
          shellName: 'root',
          resolveRecord: (record) => record as _TestRecord,
          wrapRecord:
              ({
                required record,
                required runtime,
                required branchIndex,
                shellName,
              }) {
                return _WrappedRecord(
                  record: record,
                  runtime: runtime,
                  branchIndex: branchIndex,
                  shellName: shellName,
                );
              },
        );

    expect(wrapped, hasLength(2));
    expect(wrapped[0].path, '/feed');
    expect(wrapped[1].path, '/settings');
    expect(wrapped[0].branchIndex, 0);
    expect(wrapped[1].branchIndex, 1);
    expect(wrapped[0].shellName, 'root');
    expect(wrapped[1].shellName, 'root');
    expect(identical(wrapped[0].runtime, wrapped[1].runtime), isTrue);
  });
}

final class _AppRoute implements RouteData {
  const _AppRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}

final class _TestRecord implements RouteRecord<_AppRoute> {
  _TestRecord({required this.path, this.name})
    : parse = ((_) => _AppRoute(path));

  @override
  final String path;

  @override
  final String? name;

  @override
  final RouteParser<_AppRoute> parse;

  @override
  Future<RouteGuardResult> runGuards(RouteContext<RouteData> context) {
    return Future<RouteGuardResult>.value(RouteGuardResult.allow());
  }

  @override
  Future<Uri?> runRedirect(RouteContext<RouteData> context) {
    return Future<Uri?>.value(null);
  }
}

final class _WrappedRecord implements RouteRecord<_AppRoute> {
  const _WrappedRecord({
    required this.record,
    required this.runtime,
    required this.branchIndex,
    required this.shellName,
  });

  final _TestRecord record;
  final ShellRuntimeBinding<_AppRoute> runtime;
  final int branchIndex;
  final String? shellName;

  @override
  String get path => record.path;

  @override
  String? get name => record.name;

  @override
  RouteParser<_AppRoute> get parse => record.parse;

  @override
  Future<RouteGuardResult> runGuards(RouteContext<RouteData> context) {
    return record.runGuards(context);
  }

  @override
  Future<Uri?> runRedirect(RouteContext<RouteData> context) {
    return record.runRedirect(context);
  }
}
