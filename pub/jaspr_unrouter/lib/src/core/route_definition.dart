import 'dart:collection';

import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart' show RouteData;
import 'package:unrouter/unrouter.dart'
    as core
    show
        LoadedRouteDefinition,
        RouteDefinition,
        RouteGuard,
        RouteGuardResult,
        RouteHookContext,
        RouteLoader,
        RouteParser,
        RouteParserState,
        RouteRecord,
        RouteRedirect,
        ShellBranch,
        ShellRuntimeBinding,
        branch;

import '../runtime/navigation.dart';

/// Parses a matched [RouteParserState] into a typed route object.
typedef RouteParser<T extends RouteData> = core.RouteParser<T>;

/// Builds a route component without loader data.
typedef RouteComponentBuilder<T extends RouteData> =
    Component Function(BuildContext context, T route);

/// Builds a route component with resolved loader data.
typedef RouteLoadedComponentBuilder<T extends RouteData, L> =
    Component Function(BuildContext context, T route, L data);

/// Route guard that can allow, block, or redirect navigation.
typedef RouteGuard<T extends RouteData> = core.RouteGuard<T>;

/// Route-level redirect resolver.
typedef RouteRedirect<T extends RouteData> = core.RouteRedirect<T>;

/// Asynchronous loader executed before route build.
typedef RouteLoader<T extends RouteData, L> = core.RouteLoader<T, L>;

/// Shell frame builder used by [shell].
typedef ShellBuilder<R extends RouteData> =
    Component Function(
      BuildContext context,
      ShellState<R> shell,
      Component child,
    );

typedef ShellBranch<R extends RouteData> = core.ShellBranch<R>;

abstract interface class RouteRecord<T extends RouteData>
    implements core.RouteRecord<T> {
  Component build(BuildContext context, RouteData route, Object? loaderData);
}

/// Route definition without asynchronous loader data.
class RouteDefinition<T extends RouteData> extends core.RouteDefinition<T>
    implements RouteRecord<T> {
  RouteDefinition({
    required String path,
    required RouteParser<T> parse,
    required RouteComponentBuilder<T> builder,
    String? name,
    List<RouteGuard<T>> guards = const [],
    RouteRedirect<T>? redirect,
  }) : _builder = builder,
       super(
         path: path,
         parse: parse,
         name: name,
         guards: guards,
         redirect: redirect,
       );

  final RouteComponentBuilder<T> _builder;

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    return _builder(context, route as T);
  }
}

/// Route definition that resolves typed loader data before build.
class LoadedRouteDefinition<T extends RouteData, L>
    extends core.LoadedRouteDefinition<T, L>
    implements RouteRecord<T> {
  LoadedRouteDefinition({
    required String path,
    required RouteParser<T> parse,
    required RouteLoader<T, L> loader,
    required RouteLoadedComponentBuilder<T, L> builder,
    String? name,
    List<RouteGuard<T>> guards = const [],
    RouteRedirect<T>? redirect,
  }) : _builder = builder,
       super(
         path: path,
         parse: parse,
         loader: loader,
         name: name,
         guards: guards,
         redirect: redirect,
       );

  final RouteLoadedComponentBuilder<T, L> _builder;

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    if (loaderData is! L) {
      final actualType = loaderData == null
          ? 'null'
          : loaderData.runtimeType.toString();
      throw StateError(
        'Route "$path" expected loader data of type "$L" '
        'but got "$actualType".',
      );
    }

    return _builder(context, route as T, loaderData);
  }
}

/// Creates a [RouteDefinition].
RouteDefinition<T> route<T extends RouteData>({
  required String path,
  required RouteParser<T> parse,
  required RouteComponentBuilder<T> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
}) {
  return RouteDefinition<T>(
    path: path,
    parse: parse,
    builder: builder,
    name: name,
    guards: guards,
    redirect: redirect,
  );
}

/// Creates a [LoadedRouteDefinition].
LoadedRouteDefinition<T, L> routeWithLoader<T extends RouteData, L>({
  required String path,
  required RouteParser<T> parse,
  required RouteLoader<T, L> loader,
  required RouteLoadedComponentBuilder<T, L> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
}) {
  return LoadedRouteDefinition<T, L>(
    path: path,
    parse: parse,
    loader: loader,
    builder: builder,
    name: name,
    guards: guards,
    redirect: redirect,
  );
}

/// Creates a [ShellBranch].
ShellBranch<R> branch<R extends RouteData>({
  required List<RouteRecord<R>> routes,
  required Uri initialLocation,
  String? name,
}) {
  return core.branch<R>(
    routes: routes.cast<core.RouteRecord<R>>(),
    initialLocation: initialLocation,
    name: name,
  );
}

/// Contract implemented by shell-aware route records.
abstract interface class ShellRouteRecordHost<R extends RouteData> {
  Uri resolveBranchTarget(int index, {bool initialLocation = false});

  bool canPopBranch();

  Uri? popBranch({Object? result});
}

/// Runtime state passed to shell builders.
class ShellState<R extends RouteData> {
  const ShellState._({
    required this.activeBranchIndex,
    required this.branches,
    required this.currentUri,
    required List<Uri> currentBranchHistory,
    required void Function(
      int index, {
      bool initialLocation,
      bool completePendingResult,
      Object? result,
    })
    onGoBranch,
    required bool Function() canPopBranch,
    required bool Function(Object? result) onPopBranch,
  }) : _currentBranchHistory = currentBranchHistory,
       _onGoBranch = onGoBranch,
       _canPopBranch = canPopBranch,
       _onPopBranch = onPopBranch;

  final int activeBranchIndex;
  final List<ShellBranch<R>> branches;
  final Uri currentUri;
  final List<Uri> _currentBranchHistory;
  final void Function(
    int index, {
    bool initialLocation,
    bool completePendingResult,
    Object? result,
  })
  _onGoBranch;
  final bool Function() _canPopBranch;
  final bool Function(Object? result) _onPopBranch;

  int get branchCount => branches.length;

  List<Uri> get currentBranchHistory {
    return UnmodifiableListView(_currentBranchHistory);
  }

  bool get canPopBranch => _canPopBranch();

  /// Switches active branch.
  ///
  /// Set [initialLocation] to reset the target branch stack, and optionally
  /// complete an active push result with [completePendingResult]/[result].
  void goBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    _onGoBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Pops the active branch stack and optionally completes push result.
  bool popBranch<T extends Object?>([T? result]) {
    return _onPopBranch(result);
  }
}

/// Wraps branch routes into a shared shell.
List<RouteRecord<R>> shell<R extends RouteData>({
  required ShellBuilder<R> builder,
  required List<ShellBranch<R>> branches,
  String? name,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  final immutableBranches = List<ShellBranch<R>>.unmodifiable(branches);
  final runtime = core.ShellRuntimeBinding<R>(branches: immutableBranches);
  final wrapped = <RouteRecord<R>>[];
  for (var i = 0; i < immutableBranches.length; i++) {
    final branch = immutableBranches[i];
    for (final record in branch.routes) {
      final adapterRecord = _asAdapterRouteRecord(record);
      wrapped.add(
        _ShellRouteRecord<R>(
          record: adapterRecord,
          runtime: runtime,
          shellBuilder: builder,
          branchIndex: i,
          shellName: name,
        ),
      );
    }
  }
  return wrapped;
}

class _ShellRouteRecord<R extends RouteData>
    implements RouteRecord<R>, ShellRouteRecordHost<R> {
  _ShellRouteRecord({
    required RouteRecord<R> record,
    required core.ShellRuntimeBinding<R> runtime,
    required ShellBuilder<R> shellBuilder,
    required int branchIndex,
    String? shellName,
  }) : _record = record,
       _runtime = runtime,
       _shellBuilder = shellBuilder,
       _branchIndex = branchIndex,
       _shellName = shellName;

  final RouteRecord<R> _record;
  final core.ShellRuntimeBinding<R> _runtime;
  final ShellBuilder<R> _shellBuilder;
  final int _branchIndex;
  final String? _shellName;

  @override
  String get path => _record.path;

  @override
  String? get name {
    if (_shellName == null) {
      return _record.name;
    }
    final routeName = _record.name;
    if (routeName == null || routeName.isEmpty) {
      return _shellName;
    }
    return '$_shellName.$routeName';
  }

  @override
  R parse(core.RouteParserState state) => _record.parse(state);

  @override
  Future<Uri?> runRedirect(core.RouteHookContext<RouteData> context) {
    return _record.runRedirect(context);
  }

  @override
  Future<core.RouteGuardResult> runGuards(
    core.RouteHookContext<RouteData> context,
  ) {
    return _record.runGuards(context);
  }

  @override
  Future<Object?> load(core.RouteHookContext<RouteData> context) {
    return _record.load(context);
  }

  @override
  Uri resolveBranchTarget(int index, {bool initialLocation = false}) {
    return _runtime.resolveTargetUri(index, initialLocation: initialLocation);
  }

  @override
  bool canPopBranch() {
    return _runtime.canPopBranch(_branchIndex);
  }

  @override
  Uri? popBranch({Object? result}) {
    return _runtime.popBranch(_branchIndex);
  }

  @override
  Component build(BuildContext context, RouteData route, Object? loaderData) {
    final child = _record.build(context, route, loaderData);
    final controller = context.unrouter;
    _runtime.restoreFromState(controller.historyState);
    final currentUri = controller.uri;
    _runtime.recordNavigation(
      branchIndex: _branchIndex,
      uri: currentUri,
      action: controller.lastAction,
      delta: controller.lastDelta,
      historyIndex: controller.historyIndex,
    );
    controller.setHistoryStateComposer((request) {
      return _runtime.composeHistoryState(
        uri: request.uri,
        action: request.action,
        state: request.state,
        currentState: request.currentState,
        activeBranchIndex: _branchIndex,
      );
    });

    final shellState = ShellState<R>._(
      activeBranchIndex: _branchIndex,
      branches: _runtime.branches,
      currentUri: currentUri,
      currentBranchHistory: _runtime.currentBranchHistory(_branchIndex),
      onGoBranch:
          (
            index, {
            initialLocation = false,
            completePendingResult = false,
            result,
          }) {
            controller.switchBranch(
              index,
              initialLocation: initialLocation,
              completePendingResult: completePendingResult,
              result: result,
            );
          },
      canPopBranch: () => _runtime.canPopBranch(_branchIndex),
      onPopBranch: (result) => controller.popBranch(result),
    );

    return _shellBuilder(context, shellState, child);
  }
}

RouteRecord<R> _asAdapterRouteRecord<R extends RouteData>(
  core.RouteRecord<R> record,
) {
  if (record case RouteRecord<R> adapterRecord) {
    return adapterRecord;
  }
  throw StateError(
    'Shell branch route "${record.path}" does not implement jaspr RouteRecord. '
    'Build shell routes with jaspr_unrouter route()/routeWithLoader().',
  );
}
