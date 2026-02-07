part of 'navigation.dart';

class _UnrouterTypedStateListenable<R extends RouteData>
    implements ValueListenable<UnrouterStateSnapshot<R>> {
  const _UnrouterTypedStateListenable(this._source);

  final ValueListenable<UnrouterStateSnapshot<RouteData>> _source;

  @override
  UnrouterStateSnapshot<R> get value => _source.value.cast<R>();

  @override
  void addListener(VoidCallback listener) {
    _source.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _source.removeListener(listener);
  }
}

class _UnrouterStateStore {
  _UnrouterStateStore({
    required UnrouterStateSnapshot<RouteData> Function() stateGetter,
  }) : _stateGetter = stateGetter,
       _current = ValueNotifier<UnrouterStateSnapshot<RouteData>>(
         stateGetter(),
       );

  final UnrouterStateSnapshot<RouteData> Function() _stateGetter;
  final ValueNotifier<UnrouterStateSnapshot<RouteData>> _current;
  bool _isDisposed = false;

  ValueListenable<UnrouterStateSnapshot<RouteData>> get listenable => _current;

  UnrouterStateSnapshot<RouteData> get current => _current.value;

  void refresh() {
    if (_isDisposed) {
      return;
    }

    final next = _stateGetter();
    if (_isSameSnapshot(_current.value, next)) {
      return;
    }

    _current.value = next;
  }

  bool _isSameSnapshot(
    UnrouterStateSnapshot<RouteData> a,
    UnrouterStateSnapshot<RouteData> b,
  ) {
    return a.uri.toString() == b.uri.toString() &&
        _routeIdentity(a.route) == _routeIdentity(b.route) &&
        a.resolution == b.resolution &&
        a.routePath == b.routePath &&
        a.routeName == b.routeName &&
        a.error == b.error &&
        a.stackTrace == b.stackTrace &&
        a.lastAction == b.lastAction &&
        a.lastDelta == b.lastDelta &&
        a.historyIndex == b.historyIndex;
  }

  String? _routeIdentity(RouteData? route) {
    if (route == null) {
      return null;
    }
    return '${route.runtimeType}:${route.toUri()}';
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _current.dispose();
  }
}

class _UnrouterNavigationState {
  _UnrouterNavigationState(this._routeInformationProvider)
    : _trackedHistoryIndex = _routeInformationProvider.historyIndex ?? 0 {
    _routeInformationProvider.addListener(_onRouteInformationChanged);
  }

  final UnrouterRouteInformationProvider _routeInformationProvider;
  final List<Completer<Object?>> _pendingPushResults = <Completer<Object?>>[];
  final ListQueue<Object?> _popResultQueue = ListQueue<Object?>();

  int _trackedHistoryIndex;
  bool _isDisposed = false;

  Future<T?> pushForResult<T extends Object?>(Uri uri, {Object? state}) {
    final completer = Completer<Object?>();
    _pendingPushResults.add(completer);
    _routeInformationProvider.push(uri, state: state);
    return completer.future.then((value) => value as T?);
  }

  bool popWithResult<T extends Object?>([T? result]) {
    if (!_routeInformationProvider.canGoBack) {
      return false;
    }

    _popResultQueue.addLast(result);
    _routeInformationProvider.back();
    return true;
  }

  void replaceAsPop(Uri uri, {Object? state, Object? result}) {
    _completeTopPending(result);
    _routeInformationProvider.replace(uri, state: state);
  }

  void _onRouteInformationChanged() {
    if (_isDisposed) {
      return;
    }

    final previousIndex = _trackedHistoryIndex;
    final action = _routeInformationProvider.lastAction;
    final nextIndex = _resolveHistoryIndex(
      fallbackIndex: previousIndex,
      historyIndex: _routeInformationProvider.historyIndex,
      action: action,
      delta: _routeInformationProvider.lastDelta,
    );

    if (action == HistoryAction.pop) {
      final poppedCount = _resolvePoppedCount(
        previousIndex: previousIndex,
        nextIndex: nextIndex,
        delta: _routeInformationProvider.lastDelta,
      );
      _completePoppedEntries(poppedCount);
    }

    _trackedHistoryIndex = nextIndex;
  }

  int _resolveHistoryIndex({
    required int fallbackIndex,
    required int? historyIndex,
    required HistoryAction action,
    required int? delta,
  }) {
    if (historyIndex != null) {
      return historyIndex;
    }

    switch (action) {
      case HistoryAction.push:
        return fallbackIndex + 1;
      case HistoryAction.replace:
        return fallbackIndex;
      case HistoryAction.pop:
        final movement = delta ?? 0;
        final next = fallbackIndex + movement;
        if (next < 0) {
          return 0;
        }
        return next;
    }
  }

  int _resolvePoppedCount({
    required int previousIndex,
    required int nextIndex,
    required int? delta,
  }) {
    if (delta != null) {
      if (delta < 0) {
        return -delta;
      }
      return 0;
    }

    if (nextIndex < previousIndex) {
      return previousIndex - nextIndex;
    }

    return 0;
  }

  void _completePoppedEntries(int poppedCount) {
    for (var i = 0; i < poppedCount; i++) {
      final result = i == 0 && _popResultQueue.isNotEmpty
          ? _popResultQueue.removeFirst()
          : null;
      _completeTopPending(result);
    }
  }

  void _completeTopPending(Object? result) {
    if (_pendingPushResults.isEmpty) {
      return;
    }

    final completer = _pendingPushResults.removeLast();
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _routeInformationProvider.removeListener(_onRouteInformationChanged);
    for (final completer in _pendingPushResults) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _pendingPushResults.clear();
    _popResultQueue.clear();
  }
}

class UnrouterScope extends InheritedWidget {
  const UnrouterScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final UnrouterController<RouteData> controller;

  /// Reads untyped controller from widget tree.
  static UnrouterController<RouteData> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UnrouterScope>();
    if (scope != null) {
      return scope.controller;
    }

    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('UnrouterScope was not found in context.'),
      ErrorDescription(
        'No Unrouter widget is available above this BuildContext.',
      ),
    ]);
  }

  /// Reads typed controller from widget tree.
  static UnrouterController<R> ofAs<R extends RouteData>(BuildContext context) {
    return of(context).cast<R>();
  }

  @override
  bool updateShouldNotify(UnrouterScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// `BuildContext` helpers for core router access.
extension UnrouterBuildContextExtension on BuildContext {
  /// Returns the untyped router controller.
  UnrouterController<RouteData> get unrouter => UnrouterScope.of(this);

  /// Returns a typed router controller.
  UnrouterController<R> unrouterAs<R extends RouteData>() {
    return UnrouterScope.ofAs<R>(this);
  }
}
