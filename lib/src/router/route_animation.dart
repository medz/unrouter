import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

const Duration _kDefaultRouteAnimationDuration = Duration(milliseconds: 300);

@internal
class RouteAnimationConfig {
  const RouteAnimationConfig({
    required this.defaultValue,
    this.value,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.animationBehavior = AnimationBehavior.normal,
  });

  final double defaultValue;
  final double? value;
  final Duration? duration;
  final Duration? reverseDuration;
  final String? debugLabel;
  final double lowerBound;
  final double upperBound;
  final AnimationBehavior animationBehavior;

  bool isCompatible(RouteAnimationConfig other) {
    return lowerBound == other.lowerBound &&
        upperBound == other.upperBound &&
        debugLabel == other.debugLabel &&
        animationBehavior == other.animationBehavior;
  }
}

@internal
class RouteAnimationHandle extends ChangeNotifier {
  RouteAnimationHandle({required this.vsync});

  final TickerProvider vsync;

  AnimationController? _controller;
  RouteAnimationConfig? _config;
  bool _enabled = false;

  bool get enabled => _enabled;
  AnimationController? get controller => _controller;

  AnimationController ensureController(RouteAnimationConfig config) {
    _enabled = true;
    if (_controller == null) {
      _config = config;
      _controller = AnimationController(
        vsync: vsync,
        value: config.value ?? config.defaultValue,
        duration: config.duration ?? _kDefaultRouteAnimationDuration,
        reverseDuration: config.reverseDuration,
        debugLabel: config.debugLabel,
        lowerBound: config.lowerBound,
        upperBound: config.upperBound,
        animationBehavior: config.animationBehavior,
      );
      _notifyCreated();
      return _controller!;
    }

    final existing = _config;
    assert(
      existing == null || existing.isCompatible(config),
      'RouteAnimationController already created with different bounds or behavior.',
    );

    if (config.duration != null) {
      _controller!.duration = config.duration;
    }
    if (config.reverseDuration != null) {
      _controller!.reverseDuration = config.reverseDuration;
    }
    if (config.value != null) {
      _controller!.value = config.value!;
    }

    return _controller!;
  }

  void _notifyCreated() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller != null) {
          notifyListeners();
        }
      });
      return;
    }
    notifyListeners();
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

class RouteAnimationScope extends InheritedWidget {
  const RouteAnimationScope({
    super.key,
    required this.handle,
    required this.isActive,
    required super.child,
  });

  final RouteAnimationHandle handle;
  final bool isActive;

  static RouteAnimationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouteAnimationScope>();
  }

  @override
  bool updateShouldNotify(RouteAnimationScope oldWidget) {
    return handle != oldWidget.handle || isActive != oldWidget.isActive;
  }
}
