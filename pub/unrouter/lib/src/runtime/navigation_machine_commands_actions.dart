part of 'machine_kernel.dart';

/// Strongly typed machine command API.
///
/// Commands execute directly against [UnrouterMachineCommandRuntime].
sealed class UnrouterMachineCommand<T extends Object?>
    extends MachineCommand<T, UnrouterMachineCommandRuntime> {
  const UnrouterMachineCommand();

  /// Navigates to [uri] using push-like semantics.
  static UnrouterMachineCommand<void> goUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineGoUriCommand(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Replaces current entry with [uri].
  static UnrouterMachineCommand<void> replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineReplaceUriCommand(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Pushes [uri] and resolves typed result on pop.
  static UnrouterMachineCommand<Future<T?>> pushUri<T extends Object?>(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachinePushUriCommand<T>(uri, state: state);
  }

  /// Pops current entry and optionally passes [result].
  static UnrouterMachineCommand<bool> pop([Object? result]) {
    return _UnrouterMachinePopCommand(result);
  }

  /// Pops history until [uri] is reached.
  static UnrouterMachineCommand<void> popToUri(
    Uri uri, {
    Object? state,
    Object? result,
  }) {
    return _UnrouterMachinePopToUriCommand(uri, state: state, result: result);
  }

  /// Goes back one history entry.
  static UnrouterMachineCommand<bool> back() {
    return const _UnrouterMachineBackCommand();
  }

  /// Goes forward one history entry.
  static UnrouterMachineCommand<void> forward() {
    return const _UnrouterMachineForwardCommand();
  }

  /// Moves history cursor by [delta].
  static UnrouterMachineCommand<void> goDelta(int delta) {
    return _UnrouterMachineGoDeltaCommand(delta);
  }

  /// Switches active shell branch.
  static UnrouterMachineCommand<bool> switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineSwitchBranchCommand(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Pops active shell branch stack.
  static UnrouterMachineCommand<bool> popBranch([Object? result]) {
    return _UnrouterMachinePopBranchCommand(result);
  }

  /// Event represented by this command.
  UnrouterMachineEvent get event;

  /// Executes command against runtime.
  T execute(UnrouterMachineCommandRuntime runtime);
}

final class _UnrouterMachineGoUriCommand extends UnrouterMachineCommand<void> {
  const _UnrouterMachineGoUriCommand(
    this.uri, {
    this.state,
    this.completePendingResult = false,
    this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goUri;

  @override
  void execute(UnrouterMachineCommandRuntime runtime) {
    runtime.goUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachineReplaceUriCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachineReplaceUriCommand(
    this.uri, {
    this.state,
    this.completePendingResult = false,
    this.result,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.replaceUri;

  @override
  void execute(UnrouterMachineCommandRuntime runtime) {
    runtime.replaceUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachinePushUriCommand<T extends Object?>
    extends UnrouterMachineCommand<Future<T?>> {
  const _UnrouterMachinePushUriCommand(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;

  @override
  Future<T?> execute(UnrouterMachineCommandRuntime runtime) {
    return runtime.pushUri<T>(uri, state: state);
  }
}

final class _UnrouterMachinePopCommand extends UnrouterMachineCommand<bool> {
  const _UnrouterMachinePopCommand([this.result]);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pop;

  @override
  bool execute(UnrouterMachineCommandRuntime runtime) {
    return runtime.pop(result);
  }
}

final class _UnrouterMachinePopToUriCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachinePopToUriCommand(this.uri, {this.state, this.result});

  final Uri uri;
  final Object? state;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popToUri;

  @override
  void execute(UnrouterMachineCommandRuntime runtime) {
    runtime.popToUri(uri, state: state, result: result);
  }
}

final class _UnrouterMachineBackCommand extends UnrouterMachineCommand<bool> {
  const _UnrouterMachineBackCommand();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.back;

  @override
  bool execute(UnrouterMachineCommandRuntime runtime) {
    return runtime.back();
  }
}

final class _UnrouterMachineForwardCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachineForwardCommand();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.forward;

  @override
  void execute(UnrouterMachineCommandRuntime runtime) {
    runtime.forward();
  }
}

final class _UnrouterMachineGoDeltaCommand
    extends UnrouterMachineCommand<void> {
  const _UnrouterMachineGoDeltaCommand(this.delta);

  final int delta;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goDelta;

  @override
  void execute(UnrouterMachineCommandRuntime runtime) {
    runtime.goDelta(delta);
  }
}

final class _UnrouterMachineSwitchBranchCommand
    extends UnrouterMachineCommand<bool> {
  const _UnrouterMachineSwitchBranchCommand(
    this.index, {
    this.initialLocation = false,
    this.completePendingResult = false,
    this.result,
  });

  final int index;
  final bool initialLocation;
  final bool completePendingResult;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.switchBranch;

  @override
  bool execute(UnrouterMachineCommandRuntime runtime) {
    return runtime.switchBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachinePopBranchCommand
    extends UnrouterMachineCommand<bool> {
  const _UnrouterMachinePopBranchCommand([this.result]);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popBranch;

  @override
  bool execute(UnrouterMachineCommandRuntime runtime) {
    return runtime.popBranch(result);
  }
}
