import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

import '../platform/route_information_provider.dart';

final Expando<_ControllerStateListenable<RouteData>> _stateListenables =
    Expando<_ControllerStateListenable<RouteData>>('flutter_unrouter.state');

UnrouterController<R> createUnrouterController<R extends RouteData>({
  required Unrouter<R> router,
  required UnrouterRouteInformationProvider routeInformationProvider,
  bool resolveInitialRoute = false,
  bool publishPendingState = false,
}) {
  return UnrouterController<R>(
    router: router,
    history: _UnrouterProviderBackedHistory(routeInformationProvider),
    resolveInitialRoute: resolveInitialRoute,
    publishPendingState: publishPendingState,
    disposeHistory: false,
  );
}

_ControllerStateListenable<RouteData> _stateListenableFor(
  UnrouterController<RouteData> controller,
) {
  final existing = _stateListenables[controller];
  if (existing != null) {
    return existing;
  }

  final created = _ControllerStateListenable<RouteData>(controller);
  _stateListenables[controller] = created;
  return created;
}

/// Flutter `ValueListenable` bridge for core controller states.
extension UnrouterControllerListenableExtension<R extends RouteData>
    on UnrouterController<R> {
  ValueListenable<StateSnapshot<R>> get stateListenable {
    final source = _stateListenableFor(cast<RouteData>());
    return _UnrouterTypedStateListenable<R>(source);
  }
}

class _ControllerStateListenable<R extends RouteData>
    implements ValueListenable<StateSnapshot<R>> {
  _ControllerStateListenable(this._controller) : _value = _controller.state {
    _controller.states.listen((snapshot) {
      _value = snapshot;
      if (_listeners.isEmpty) {
        return;
      }
      final listeners = List<VoidCallback>.of(_listeners);
      for (final listener in listeners) {
        listener();
      }
    });
  }

  final UnrouterController<R> _controller;
  final List<VoidCallback> _listeners = <VoidCallback>[];
  StateSnapshot<R> _value;

  @override
  StateSnapshot<R> get value => _value;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

class _UnrouterTypedStateListenable<R extends RouteData>
    implements ValueListenable<StateSnapshot<R>> {
  const _UnrouterTypedStateListenable(this._source);

  final ValueListenable<StateSnapshot<RouteData>> _source;

  @override
  StateSnapshot<R> get value => _source.value.cast<R>();

  @override
  void addListener(VoidCallback listener) {
    _source.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _source.removeListener(listener);
  }
}

class _UnrouterProviderBackedHistory extends History {
  _UnrouterProviderBackedHistory(this._provider);

  final UnrouterRouteInformationProvider _provider;

  @override
  String get base => _provider.history.base;

  @override
  HistoryAction get action => _provider.lastAction;

  @override
  HistoryLocation get location {
    return HistoryLocation(_provider.value.uri, _provider.value.state);
  }

  @override
  int? get index => _provider.historyIndex;

  @override
  String createHref(Uri uri) => _provider.history.createHref(uri);

  @override
  void push(Uri uri, {Object? state}) {
    _provider.push(uri, state: state);
  }

  @override
  void replace(Uri uri, {Object? state}) {
    _provider.replace(uri, state: state);
  }

  @override
  void go(int delta, {bool triggerListeners = true}) {
    if (triggerListeners) {
      _provider.go(delta);
      return;
    }
    _provider.history.go(delta, triggerListeners: false);
  }

  @override
  void Function() listen(HistoryListener listener) {
    void onChanged() {
      if (_provider.lastAction != HistoryAction.pop) {
        return;
      }
      listener(
        HistoryEvent(
          action: HistoryAction.pop,
          location: HistoryLocation(_provider.value.uri, _provider.value.state),
          delta: _provider.lastDelta,
        ),
      );
    }

    _provider.addListener(onChanged);
    return () {
      _provider.removeListener(onChanged);
    };
  }

  @override
  void dispose() {}
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
