/// Marker runtime contract for machine commands.
abstract interface class MachineCommandRuntime {}

/// Generic command abstraction executed against a machine runtime.
abstract base class MachineCommand<
  T extends Object?,
  R extends MachineCommandRuntime
> {
  const MachineCommand();

  T execute(R runtime);
}

/// Utility dispatcher for command-based machine APIs.
final class MachineCommandDispatcher<R extends MachineCommandRuntime> {
  const MachineCommandDispatcher(this.runtime);

  final R runtime;

  T dispatch<T extends Object?>(MachineCommand<T, R> command) {
    return command.execute(runtime);
  }
}
