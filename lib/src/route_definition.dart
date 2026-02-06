import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

import 'navigation.dart';
import 'route_data.dart';

typedef RouteParser<T extends RouteData> = T Function(RouteParserState state);
typedef RouteWidgetBuilder<T extends RouteData> =
    Widget Function(BuildContext context, T route);
typedef RouteLoadedWidgetBuilder<T extends RouteData, L> =
    Widget Function(BuildContext context, T route, L data);
typedef RouteGuard<T extends RouteData> =
    FutureOr<RouteGuardResult> Function(RouteHookContext<T> context);
typedef RouteRedirect<T extends RouteData> =
    FutureOr<Uri?> Function(RouteHookContext<T> context);
typedef RouteLoader<T extends RouteData, L> =
    FutureOr<L> Function(RouteHookContext<T> context);
typedef ShellBuilder<R extends RouteData> =
    Widget Function(BuildContext context, ShellState<R> shell, Widget child);
typedef RouteTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    );
typedef RoutePageBuilder = Page<void> Function(RoutePageBuilderState state);

class RoutePageBuilderState {
  const RoutePageBuilderState({
    required this.key,
    required this.name,
    required this.child,
  });

  final LocalKey key;
  final String name;
  final Widget child;
}

abstract interface class RouteRecord<T extends RouteData> {
  String get path;

  String? get name;

  T parse(RouteParserState state);

  Future<Uri?> runRedirect(RouteHookContext<RouteData> context);

  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context);

  Future<Object?> load(RouteHookContext<RouteData> context);

  Widget build(BuildContext context, RouteData route, Object? loaderData);

  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  });
}

class RouteDefinition<T extends RouteData> implements RouteRecord<T> {
  RouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    required RouteWidgetBuilder<T> builder,
    this.name,
    List<RouteGuard<T>> guards = const [],
    this.redirect,
    this.pageBuilder,
    this.transitionBuilder,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  }) : _parse = parse,
       _builder = builder,
       _guards = List<RouteGuard<T>>.unmodifiable(guards);

  @override
  final String path;

  @override
  final String? name;

  final RouteParser<T> _parse;
  final RouteWidgetBuilder<T> _builder;
  final List<RouteGuard<T>> _guards;
  final RouteRedirect<T>? redirect;
  final RoutePageBuilder? pageBuilder;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  T parse(RouteParserState state) => _parse(state);

  @override
  Future<Uri?> runRedirect(RouteHookContext<RouteData> context) async {
    final resolver = redirect;
    if (resolver == null) {
      return null;
    }

    context.signal.throwIfCancelled();
    final uri = await resolver(context.cast<T>());
    context.signal.throwIfCancelled();
    return uri;
  }

  @override
  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context) {
    return runRouteGuards(_guards, context.cast<T>());
  }

  @override
  Future<Object?> load(RouteHookContext<RouteData> context) async => null;

  @override
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
    return _builder(context, route as T);
  }

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return _createRoutePage(
      key: key,
      name: name,
      child: child,
      pageBuilder: pageBuilder,
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
}

class LoadedRouteDefinition<T extends RouteData, L> implements RouteRecord<T> {
  LoadedRouteDefinition({
    required this.path,
    required RouteParser<T> parse,
    required RouteLoader<T, L> loader,
    required RouteLoadedWidgetBuilder<T, L> builder,
    this.name,
    List<RouteGuard<T>> guards = const [],
    this.redirect,
    this.pageBuilder,
    this.transitionBuilder,
    this.transitionDuration = Duration.zero,
    this.reverseTransitionDuration = Duration.zero,
  }) : _parse = parse,
       _loader = loader,
       _builder = builder,
       _guards = List<RouteGuard<T>>.unmodifiable(guards);

  @override
  final String path;

  @override
  final String? name;

  final RouteParser<T> _parse;
  final RouteLoader<T, L> _loader;
  final RouteLoadedWidgetBuilder<T, L> _builder;
  final List<RouteGuard<T>> _guards;
  final RouteRedirect<T>? redirect;
  final RoutePageBuilder? pageBuilder;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  T parse(RouteParserState state) => _parse(state);

  @override
  Future<Uri?> runRedirect(RouteHookContext<RouteData> context) async {
    final resolver = redirect;
    if (resolver == null) {
      return null;
    }

    context.signal.throwIfCancelled();
    final uri = await resolver(context.cast<T>());
    context.signal.throwIfCancelled();
    return uri;
  }

  @override
  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context) {
    return runRouteGuards(_guards, context.cast<T>());
  }

  @override
  Future<Object?> load(RouteHookContext<RouteData> context) async {
    final typedContext = context.cast<T>();
    context.signal.throwIfCancelled();
    final data = await _loader(typedContext);
    context.signal.throwIfCancelled();
    return data;
  }

  @override
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
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

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return _createRoutePage(
      key: key,
      name: name,
      child: child,
      pageBuilder: pageBuilder,
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
}

RouteDefinition<T> route<T extends RouteData>({
  required String path,
  required RouteParser<T> parse,
  required RouteWidgetBuilder<T> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
  RoutePageBuilder? pageBuilder,
  RouteTransitionBuilder? transitionBuilder,
  Duration transitionDuration = Duration.zero,
  Duration reverseTransitionDuration = Duration.zero,
}) {
  return RouteDefinition<T>(
    path: path,
    parse: parse,
    builder: builder,
    name: name,
    guards: guards,
    redirect: redirect,
    pageBuilder: pageBuilder,
    transitionBuilder: transitionBuilder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

LoadedRouteDefinition<T, L> routeWithLoader<T extends RouteData, L>({
  required String path,
  required RouteParser<T> parse,
  required RouteLoader<T, L> loader,
  required RouteLoadedWidgetBuilder<T, L> builder,
  String? name,
  List<RouteGuard<T>> guards = const [],
  RouteRedirect<T>? redirect,
  RoutePageBuilder? pageBuilder,
  RouteTransitionBuilder? transitionBuilder,
  Duration transitionDuration = Duration.zero,
  Duration reverseTransitionDuration = Duration.zero,
}) {
  return LoadedRouteDefinition<T, L>(
    path: path,
    parse: parse,
    loader: loader,
    builder: builder,
    name: name,
    guards: guards,
    redirect: redirect,
    pageBuilder: pageBuilder,
    transitionBuilder: transitionBuilder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

Page<void> _createRoutePage({
  required LocalKey key,
  required String name,
  required Widget child,
  required RoutePageBuilder? pageBuilder,
  required RouteTransitionBuilder? transitionBuilder,
  required Duration transitionDuration,
  required Duration reverseTransitionDuration,
}) {
  final builder = pageBuilder;
  if (builder != null) {
    return builder(RoutePageBuilderState(key: key, name: name, child: child));
  }

  return _RouteTransitionPage(
    key: key,
    name: name,
    child: child,
    transitionBuilder: transitionBuilder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
  );
}

class _RouteTransitionPage extends Page<void> {
  const _RouteTransitionPage({
    required this.child,
    required this.transitionBuilder,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    super.key,
    super.name,
  });

  final Widget child;
  final RouteTransitionBuilder? transitionBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  @override
  Route<void> createRoute(BuildContext context) {
    final builder = transitionBuilder;
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: builder ?? (_, _, _, child) => child,
    );
  }
}

class ShellBranch<R extends RouteData> {
  ShellBranch({
    required List<RouteRecord<R>> routes,
    required Uri initialLocation,
    this.name,
  }) : assert(
         routes.isNotEmpty,
         'A shell branch must define at least one route.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       initialLocation = _normalizeShellLocation(initialLocation);

  final List<RouteRecord<R>> routes;
  final Uri initialLocation;
  final String? name;
}

ShellBranch<R> branch<R extends RouteData>({
  required List<RouteRecord<R>> routes,
  required Uri initialLocation,
  String? name,
}) {
  return ShellBranch<R>(
    routes: routes,
    initialLocation: initialLocation,
    name: name,
  );
}

abstract interface class ShellRouteRecordHost<R extends RouteData> {
  Uri resolveBranchTarget(int index, {bool initialLocation = false});

  bool canPopBranch();

  Uri? popBranch({Object? result});
}

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

  bool popBranch<T extends Object?>([T? result]) {
    return _onPopBranch(result);
  }
}

List<RouteRecord<R>> shell<R extends RouteData>({
  required ShellBuilder<R> builder,
  required List<ShellBranch<R>> branches,
  String? name,
}) {
  assert(branches.isNotEmpty, 'shell() requires at least one branch.');
  final immutableBranches = List<ShellBranch<R>>.unmodifiable(branches);
  final runtime = _ShellRuntime<R>(immutableBranches);
  final wrapped = <RouteRecord<R>>[];
  for (var i = 0; i < immutableBranches.length; i++) {
    final branch = immutableBranches[i];
    for (final record in branch.routes) {
      wrapped.add(
        _ShellRouteRecord<R>(
          record: record,
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
  const _ShellRouteRecord({
    required RouteRecord<R> record,
    required _ShellRuntime<R> runtime,
    required ShellBuilder<R> shellBuilder,
    required int branchIndex,
    String? shellName,
  }) : _record = record,
       _runtime = runtime,
       _shellBuilder = shellBuilder,
       _branchIndex = branchIndex,
       _shellName = shellName;

  final RouteRecord<R> _record;
  final _ShellRuntime<R> _runtime;
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
  R parse(RouteParserState state) => _record.parse(state);

  @override
  Future<Uri?> runRedirect(RouteHookContext<RouteData> context) {
    return _record.runRedirect(context);
  }

  @override
  Future<RouteGuardResult> runGuards(RouteHookContext<RouteData> context) {
    return _record.runGuards(context);
  }

  @override
  Future<Object?> load(RouteHookContext<RouteData> context) {
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
  Widget build(BuildContext context, RouteData route, Object? loaderData) {
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
        request: request,
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

  @override
  Page<void> createPage({
    required LocalKey key,
    required String name,
    required Widget child,
  }) {
    return _record.createPage(key: key, name: name, child: child);
  }
}

class _ShellRuntime<R extends RouteData> {
  _ShellRuntime(this.branches);

  final List<ShellBranch<R>> branches;
  final Map<int, _BranchStack> _stacks = <int, _BranchStack>{};
  int? _lastRecordedHistoryIndex;
  HistoryAction? _lastRecordedAction;
  String? _lastRecordedUri;
  String? _lastRestorationSignature;

  void restoreFromState(Object? state) {
    final envelope = _UnrouterStateEnvelope.tryParse(state);
    final snapshot = envelope?.shell;
    if (snapshot == null) {
      return;
    }

    final signature = snapshot.signature;
    if (_lastRestorationSignature == signature) {
      return;
    }
    _lastRestorationSignature = signature;

    _stacks.clear();
    snapshot.stacks.forEach((branchIndex, stack) {
      if (branchIndex < 0 || branchIndex >= branches.length) {
        return;
      }
      if (stack.entries.isEmpty) {
        return;
      }
      final safeIndex = stack.index.clamp(0, stack.entries.length - 1);
      _stacks[branchIndex] = _BranchStack(
        entries: List<Uri>.from(stack.entries),
        index: safeIndex,
      );
    });
  }

  Object? composeHistoryState({
    required UnrouterHistoryStateRequest request,
    required int activeBranchIndex,
  }) {
    _assertBranchIndex(activeBranchIndex);
    final requested = _UnrouterStateEnvelope.parseOrRaw(request.state);
    final current = _UnrouterStateEnvelope.parseOrRaw(request.currentState);
    final userState = request.state == null
        ? current.userState
        : requested.userState;

    final projectedStacks = _cloneStacks(_stacks);
    final branchIndex =
        _findBranchIndexForUri(request.uri) ?? activeBranchIndex;
    final stack = _ensureStackIn(
      projectedStacks,
      branchIndex,
      seed: request.uri,
    );
    switch (request.action) {
      case HistoryAction.push:
        _applyPush(stack, request.uri);
      case HistoryAction.replace:
        _applyReplace(stack, request.uri);
      case HistoryAction.pop:
        _applyPop(stack, request.uri, null);
    }

    final snapshot = _ShellRestorationSnapshot.fromStacks(
      activeBranchIndex: branchIndex,
      stacks: projectedStacks,
    );
    return _UnrouterStateEnvelope(
      userState: userState,
      shell: snapshot,
    ).encode();
  }

  void recordNavigation({
    required int branchIndex,
    required Uri uri,
    required HistoryAction action,
    required int? delta,
    required int? historyIndex,
  }) {
    _assertBranchIndex(branchIndex);
    if (_isDuplicateEvent(uri, action, historyIndex)) {
      return;
    }

    final stack = _ensureStack(branchIndex, seed: uri);
    switch (action) {
      case HistoryAction.push:
        _applyPush(stack, uri);
      case HistoryAction.replace:
        _applyReplace(stack, uri);
      case HistoryAction.pop:
        _applyPop(stack, uri, delta);
    }

    _lastRecordedHistoryIndex = historyIndex;
    _lastRecordedAction = action;
    _lastRecordedUri = uri.toString();
    _lastRestorationSignature = _ShellRestorationSnapshot.fromStacks(
      activeBranchIndex: branchIndex,
      stacks: _stacks,
    ).signature;
  }

  Uri resolveTargetUri(int branchIndex, {required bool initialLocation}) {
    _assertBranchIndex(branchIndex);
    if (initialLocation) {
      final initial = branches[branchIndex].initialLocation;
      _stacks[branchIndex] = _BranchStack(entries: <Uri>[initial], index: 0);
      return initial;
    }

    final stack = _stacks[branchIndex];
    if (stack == null || stack.entries.isEmpty) {
      final initial = branches[branchIndex].initialLocation;
      _stacks[branchIndex] = _BranchStack(entries: <Uri>[initial], index: 0);
      return initial;
    }

    return stack.entries[stack.index];
  }

  List<Uri> currentBranchHistory(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null || stack.entries.isEmpty) {
      return const <Uri>[];
    }
    return List<Uri>.unmodifiable(stack.entries);
  }

  bool canPopBranch(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null) {
      return false;
    }
    return stack.index > 0;
  }

  Uri? popBranch(int branchIndex) {
    _assertBranchIndex(branchIndex);
    final stack = _stacks[branchIndex];
    if (stack == null || stack.index <= 0) {
      return null;
    }

    stack.index -= 1;
    return stack.entries[stack.index];
  }

  _BranchStack _ensureStack(int branchIndex, {required Uri seed}) {
    final existing = _stacks[branchIndex];
    if (existing != null) {
      return existing;
    }

    final stack = _BranchStack(entries: <Uri>[seed], index: 0);
    _stacks[branchIndex] = stack;
    return stack;
  }

  _BranchStack _ensureStackIn(
    Map<int, _BranchStack> stacks,
    int branchIndex, {
    required Uri seed,
  }) {
    final existing = stacks[branchIndex];
    if (existing != null) {
      return existing;
    }
    final stack = _BranchStack(entries: <Uri>[seed], index: 0);
    stacks[branchIndex] = stack;
    return stack;
  }

  Map<int, _BranchStack> _cloneStacks(Map<int, _BranchStack> source) {
    return source.map<int, _BranchStack>(
      (branchIndex, stack) => MapEntry<int, _BranchStack>(
        branchIndex,
        _BranchStack(
          entries: List<Uri>.from(stack.entries),
          index: stack.index,
        ),
      ),
    );
  }

  int? _findBranchIndexForUri(Uri uri) {
    final path = _normalizeShellPathForMatch(uri.path);
    for (var i = 0; i < branches.length; i++) {
      final branch = branches[i];
      for (final route in branch.routes) {
        if (_pathMatchesRoutePattern(route.path, path)) {
          return i;
        }
      }
    }
    return null;
  }

  bool _isDuplicateEvent(Uri uri, HistoryAction action, int? historyIndex) {
    final uriString = uri.toString();
    if (historyIndex != null) {
      return _lastRecordedHistoryIndex == historyIndex &&
          _lastRecordedAction == action &&
          _lastRecordedUri == uriString;
    }

    return _lastRecordedAction == action && _lastRecordedUri == uriString;
  }

  void _applyPush(_BranchStack stack, Uri uri) {
    if (_sameUri(stack.entries[stack.index], uri)) {
      return;
    }

    if (stack.index < stack.entries.length - 1) {
      stack.entries.removeRange(stack.index + 1, stack.entries.length);
    }
    stack.entries.add(uri);
    stack.index = stack.entries.length - 1;
  }

  void _applyReplace(_BranchStack stack, Uri uri) {
    stack.entries[stack.index] = uri;
  }

  void _applyPop(_BranchStack stack, Uri uri, int? delta) {
    final matchedIndex = _findPopMatchIndex(stack, uri, delta);
    if (matchedIndex != null) {
      stack.index = matchedIndex;
      return;
    }

    stack.entries[stack.index] = uri;
  }

  int? _findPopMatchIndex(_BranchStack stack, Uri uri, int? delta) {
    if (delta != null && delta < 0) {
      for (var i = stack.index; i >= 0; i--) {
        if (_sameUri(stack.entries[i], uri)) {
          return i;
        }
      }
    } else if (delta != null && delta > 0) {
      for (var i = stack.index; i < stack.entries.length; i++) {
        if (_sameUri(stack.entries[i], uri)) {
          return i;
        }
      }
    }

    for (var i = 0; i < stack.entries.length; i++) {
      if (_sameUri(stack.entries[i], uri)) {
        return i;
      }
    }

    return null;
  }

  bool _sameUri(Uri a, Uri b) {
    return a.toString() == b.toString();
  }

  void _assertBranchIndex(int branchIndex) {
    if (branchIndex < 0 || branchIndex >= branches.length) {
      throw RangeError.index(branchIndex, branches, 'branchIndex');
    }
  }
}

class _BranchStack {
  _BranchStack({required this.entries, required this.index});

  final List<Uri> entries;
  int index;
}

class _BranchStackSnapshot {
  const _BranchStackSnapshot({required this.entries, required this.index});

  final List<Uri> entries;
  final int index;

  Map<String, Object?> toJson(int branchIndex) {
    return <String, Object?>{
      'branchIndex': branchIndex,
      'index': index,
      'entries': entries.map((uri) => uri.toString()).toList(),
    };
  }

  static _BranchStackSnapshot? tryParse(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }

    final entriesValue = value['entries'];
    if (entriesValue is! List<Object?> || entriesValue.isEmpty) {
      return null;
    }

    final entries = <Uri>[];
    for (final rawEntry in entriesValue) {
      if (rawEntry is! String) {
        return null;
      }
      entries.add(Uri.parse(rawEntry));
    }

    final rawIndex = value['index'];
    if (rawIndex is! int) {
      return null;
    }
    final safeIndex = rawIndex.clamp(0, entries.length - 1);
    return _BranchStackSnapshot(entries: entries, index: safeIndex);
  }
}

class _ShellRestorationSnapshot {
  const _ShellRestorationSnapshot({
    required this.activeBranchIndex,
    required this.stacks,
  });

  final int activeBranchIndex;
  final Map<int, _BranchStackSnapshot> stacks;

  String get signature {
    final indices = stacks.keys.toList()..sort();
    final buffer = StringBuffer('a:$activeBranchIndex');
    for (final branchIndex in indices) {
      final stack = stacks[branchIndex]!;
      buffer.write('|$branchIndex:${stack.index}');
      for (final uri in stack.entries) {
        buffer.write(':${uri.toString()}');
      }
    }
    return buffer.toString();
  }

  Map<String, Object?> toJson() {
    final indices = stacks.keys.toList()..sort();
    return <String, Object?>{
      'activeBranchIndex': activeBranchIndex,
      'stacks': indices.map((branchIndex) {
        return stacks[branchIndex]!.toJson(branchIndex);
      }).toList(),
    };
  }

  static _ShellRestorationSnapshot fromStacks({
    required int activeBranchIndex,
    required Map<int, _BranchStack> stacks,
  }) {
    final serialized = <int, _BranchStackSnapshot>{};
    stacks.forEach((branchIndex, stack) {
      if (stack.entries.isEmpty) {
        return;
      }
      final safeIndex = stack.index.clamp(0, stack.entries.length - 1);
      serialized[branchIndex] = _BranchStackSnapshot(
        entries: List<Uri>.from(stack.entries),
        index: safeIndex,
      );
    });
    return _ShellRestorationSnapshot(
      activeBranchIndex: activeBranchIndex,
      stacks: serialized,
    );
  }

  static _ShellRestorationSnapshot? tryParse(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }

    final activeBranchIndex = value['activeBranchIndex'];
    if (activeBranchIndex is! int) {
      return null;
    }

    final stacksValue = value['stacks'];
    if (stacksValue is! List<Object?>) {
      return null;
    }

    final stacks = <int, _BranchStackSnapshot>{};
    for (final rawStack in stacksValue) {
      if (rawStack is! Map<Object?, Object?>) {
        continue;
      }
      final branchIndex = rawStack['branchIndex'];
      if (branchIndex is! int) {
        continue;
      }
      final parsed = _BranchStackSnapshot.tryParse(rawStack);
      if (parsed == null) {
        continue;
      }
      stacks[branchIndex] = parsed;
    }

    return _ShellRestorationSnapshot(
      activeBranchIndex: activeBranchIndex,
      stacks: stacks,
    );
  }
}

class _UnrouterStateEnvelope {
  const _UnrouterStateEnvelope({required this.userState, required this.shell});

  static const String _metaKey = '__unrouter_meta__';
  static const String _userStateKey = '__unrouter_state__';
  static const String _versionKey = 'v';
  static const int _version = 1;
  static const String _shellKey = 'shell';

  final Object? userState;
  final _ShellRestorationSnapshot? shell;

  Object? encode() {
    if (shell == null) {
      return userState;
    }
    return <String, Object?>{
      _metaKey: <String, Object?>{
        _versionKey: _version,
        _shellKey: shell!.toJson(),
      },
      _userStateKey: userState,
    };
  }

  static _UnrouterStateEnvelope parseOrRaw(Object? state) {
    return tryParse(state) ??
        _UnrouterStateEnvelope(userState: state, shell: null);
  }

  static _UnrouterStateEnvelope? tryParse(Object? state) {
    if (state is! Map<Object?, Object?>) {
      return null;
    }

    final metaValue = state[_metaKey];
    if (metaValue is! Map<Object?, Object?>) {
      return null;
    }

    final version = metaValue[_versionKey];
    if (version != _version) {
      return null;
    }

    final shell = _ShellRestorationSnapshot.tryParse(metaValue[_shellKey]);
    final userState = state.containsKey(_userStateKey)
        ? state[_userStateKey]
        : null;
    return _UnrouterStateEnvelope(userState: userState, shell: shell);
  }
}

Uri _normalizeShellLocation(Uri uri) {
  if (uri.path.isEmpty) {
    return uri.replace(path: '/');
  }
  if (!uri.path.startsWith('/')) {
    return uri.replace(path: '/${uri.path}');
  }
  return uri;
}

String _normalizeShellPathForMatch(String path) {
  if (path.isEmpty) {
    return '/';
  }
  var normalized = path;
  if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }
  if (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

bool _pathMatchesRoutePattern(String pattern, String path) {
  final normalizedPattern = _normalizeShellPathForMatch(pattern);
  final normalizedPath = _normalizeShellPathForMatch(path);
  final patternSegments = _splitShellPathSegments(normalizedPattern);
  final pathSegments = _splitShellPathSegments(normalizedPath);
  if (patternSegments.length != pathSegments.length) {
    return false;
  }

  for (var i = 0; i < patternSegments.length; i++) {
    final patternSegment = patternSegments[i];
    final pathSegment = pathSegments[i];
    if (patternSegment.startsWith(':')) {
      if (pathSegment.isEmpty) {
        return false;
      }
      continue;
    }
    if (patternSegment != pathSegment) {
      return false;
    }
  }
  return true;
}

List<String> _splitShellPathSegments(String path) {
  if (path == '/') {
    return const <String>[];
  }
  return path.substring(1).split('/');
}

Future<RouteGuardResult> runRouteGuards<T extends RouteData>(
  List<RouteGuard<T>> guards,
  RouteHookContext<T> context,
) async {
  if (guards.isEmpty) {
    return RouteGuardResult.allow();
  }

  for (final guard in guards) {
    context.signal.throwIfCancelled();
    final result = await guard(context);
    context.signal.throwIfCancelled();

    if (!result.isAllowed) {
      return result;
    }
  }

  return RouteGuardResult.allow();
}

class RouteHookContext<T extends RouteData> {
  const RouteHookContext({
    required this.uri,
    required this.route,
    required this.signal,
  });

  final Uri uri;
  final T route;
  final RouteExecutionSignal signal;

  RouteHookContext<S> cast<S extends RouteData>() {
    return RouteHookContext<S>(uri: uri, route: route as S, signal: signal);
  }
}

abstract interface class RouteExecutionSignal {
  bool get isCancelled;

  void throwIfCancelled();
}

class RouteNeverCancelledSignal implements RouteExecutionSignal {
  const RouteNeverCancelledSignal();

  @override
  bool get isCancelled => false;

  @override
  void throwIfCancelled() {}
}

class RouteExecutionCancelledException implements Exception {
  const RouteExecutionCancelledException();

  @override
  String toString() {
    return 'RouteExecutionCancelledException()';
  }
}

enum RouteGuardResultType { allow, block, redirect }

class RouteGuardResult {
  const RouteGuardResult._(this.type, [this.redirectUri]);

  static const RouteGuardResult _allow = RouteGuardResult._(
    RouteGuardResultType.allow,
  );
  static const RouteGuardResult _block = RouteGuardResult._(
    RouteGuardResultType.block,
  );

  final RouteGuardResultType type;
  final Uri? redirectUri;

  bool get isAllowed => type == RouteGuardResultType.allow;

  bool get isBlocked => type == RouteGuardResultType.block;

  bool get isRedirect => type == RouteGuardResultType.redirect;

  static RouteGuardResult allow() => _allow;

  static RouteGuardResult block() => _block;

  factory RouteGuardResult.redirect(Uri uri) {
    return RouteGuardResult._(RouteGuardResultType.redirect, uri);
  }

  factory RouteGuardResult.redirectTo(RouteData route) {
    return RouteGuardResult.redirect(route.toUri());
  }
}

class RouteParserState {
  RouteParserState({
    required this.uri,
    required Map<String, String> pathParameters,
  }) : _pathParameters = Map.unmodifiable(pathParameters);

  final Uri uri;
  final Map<String, String> _pathParameters;

  Map<String, String> get pathParameters {
    return UnmodifiableMapView(_pathParameters);
  }

  Map<String, String> get queryParameters {
    return UnmodifiableMapView(uri.queryParameters);
  }

  String path(String key) {
    final value = _pathParameters[key];
    if (value != null) {
      return value;
    }

    throw FormatException(
      'Missing required path parameter "$key" for uri "$uri".',
    );
  }

  String? pathOrNull(String key) {
    return _pathParameters[key];
  }

  int pathInt(String key) {
    final raw = path(key);
    final parsed = int.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }

    throw FormatException(
      'Path parameter "$key" must be an int, got "$raw" for uri "$uri".',
    );
  }

  String query(String key, {String? fallback}) {
    final value = uri.queryParameters[key];
    if (value != null) {
      return value;
    }

    if (fallback != null) {
      return fallback;
    }

    throw FormatException(
      'Missing required query parameter "$key" for uri "$uri".',
    );
  }

  String? queryOrNull(String key) {
    return uri.queryParameters[key];
  }

  int queryInt(String key, {int? fallback}) {
    final value = queryOrNull(key);
    if (value == null) {
      if (fallback != null) {
        return fallback;
      }

      throw FormatException(
        'Missing required query parameter "$key" for uri "$uri".',
      );
    }

    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }

    throw FormatException(
      'Query parameter "$key" must be an int, got "$value" for uri "$uri".',
    );
  }

  int? queryIntOrNull(String key) {
    final value = queryOrNull(key);
    if (value == null) {
      return null;
    }

    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }

    throw FormatException(
      'Query parameter "$key" must be an int, got "$value" for uri "$uri".',
    );
  }

  T queryEnum<T extends Enum>(String key, List<T> values, {T? fallback}) {
    final value = queryOrNull(key);
    if (value == null) {
      if (fallback != null) {
        return fallback;
      }

      throw FormatException(
        'Missing required query parameter "$key" for uri "$uri".',
      );
    }

    for (final entry in values) {
      if (entry.name == value) {
        return entry;
      }
    }

    throw FormatException(
      'Query parameter "$key" must be one of '
      '${values.map((entry) => entry.name).join(', ')}, got "$value".',
    );
  }
}
