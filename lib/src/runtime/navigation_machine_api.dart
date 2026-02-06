part of 'machine_kernel.dart';

/// Public machine facade for typed command dispatch and timeline access.
class UnrouterMachine<R extends RouteData> {
  const UnrouterMachine.host(this._host);

  final UnrouterMachineHost<R> _host;

  /// Current machine state snapshot.
  UnrouterMachineState get state => _host.machineState;

  /// Raw machine transition timeline.
  List<UnrouterMachineTransitionEntry> get timeline {
    return _host.machineTimeline;
  }

  /// Typed machine transition timeline.
  List<UnrouterMachineTypedTransition> get typedTimeline {
    return _host.machineTimeline
        .map((entry) => entry.typed)
        .toList(growable: false);
  }

  /// Dispatches a typed command.
  T dispatchTyped<T>(UnrouterMachineCommand<T> command) {
    return _host.dispatchMachineCommand<T>(command);
  }

  /// Dispatches an untyped command.
  Object? dispatch(UnrouterMachineCommand<dynamic> command) {
    return _host.dispatchMachineCommand(command);
  }
}
