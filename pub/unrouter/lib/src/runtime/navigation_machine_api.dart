part of 'machine_kernel.dart';

/// Public machine facade for command dispatch and timeline access.
class UnrouterMachine<R extends RouteData> {
  const UnrouterMachine.host(this._host);

  final UnrouterMachineHost<R> _host;

  /// Current machine state snapshot.
  UnrouterMachineState get state => _host.machineState;

  /// Raw machine transition timeline.
  List<UnrouterMachineTransitionEntry> get timeline {
    return _host.machineTimeline;
  }

  /// Dispatches a command.
  T dispatch<T extends Object?>(UnrouterMachineCommand<T> command) {
    return command.execute(_host);
  }
}
