import 'dart:math' as math;

import '_utils.dart' as utils;
import 'types.dart';

class MemoryHistory implements RouterHistory {
  MemoryHistory([String base = '/']) {
    this.base = utils.normalizeBase(base);
  }

  late final _listeners = <NavigationCallback>[];
  late final _queue = <(String, Object?)>[('', null)];
  int _position = 0;

  @override
  late final String base;

  @override
  String get location => _queue[_position].$1;

  @override
  Object? get state => _queue[_position].$2;

  @override
  void back() => go(-1);

  @override
  void forward() => go(1);

  @override
  void go(int delta) {
    final from = location;
    final NavigationDirection direction = delta > 0 ? .back : .forward;
    _position = math.max(0, math.min(_position + delta, _queue.length - 1));
    trigger(location, from, direction: direction, delta: delta);
  }

  @override
  void push(String to, [Object? state]) => set(to, state);

  @override
  void replace(String to, [Object? state]) {
    _queue.removeAt(_position--);
    set(to, state);
  }

  @override
  String createHref(String location) => utils.createHref(base, location);

  @override
  VoidCallback listen(NavigationCallback callback) {
    _listeners.add(callback);
    return () => _listeners.removeWhere((e) => e == callback);
  }

  @override
  void destroy() {
    _listeners.clear();
    _queue.length = 1;
    _position = 0;
  }
}

extension on MemoryHistory {
  void trigger(
    String to,
    String from, {
    required NavigationDirection direction,
    required int delta,
  }) {
    final info = NavigationInformation(
      direction: direction,
      type: .pop,
      delta: delta,
    );
    for (final listener in _listeners) {
      listener(to, from, info);
    }
  }

  void set(String location, Object? state) {
    _position++;
    if (_position != _queue.length) {
      _queue.length = _position;
    }
    _queue.add((location, state));
  }
}
