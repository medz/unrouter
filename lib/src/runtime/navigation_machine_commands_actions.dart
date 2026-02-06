part of 'machine_kernel.dart';

/// Strongly typed machine command API.
///
/// Commands execute directly against [UnrouterMachineCommandRuntime].
sealed class UnrouterMachineCommand<T> {
  const UnrouterMachineCommand();

  /// Dispatches a route-resolution request.
  static UnrouterMachineCommand<Future<void>> routeRequest(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachineRouteRequestCommand(uri, state: state);
  }

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

final class _UnrouterMachineRouteRequestCommand
    extends UnrouterMachineCommand<Future<void>> {
  const _UnrouterMachineRouteRequestCommand(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.request;

  @override
  Future<void> execute(UnrouterMachineCommandRuntime runtime) {
    return runtime.dispatchRouteRequest(uri, state: state);
  }
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

/// Navigation mode used by `navigate*` actions.
enum UnrouterMachineNavigateMode { go, replace }

/// Declarative machine action API mapped onto typed commands.
sealed class UnrouterMachineAction<T> {
  const UnrouterMachineAction();

  /// Dispatches a route-resolution request.
  static UnrouterMachineAction<Future<void>> routeRequest(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachineRouteRequestAction(uri, state: state);
  }

  /// Alias for [navigateUri].
  static UnrouterMachineAction<void> navigateToUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Navigates to [uri] using [mode].
  static UnrouterMachineAction<void> navigateUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
    UnrouterMachineNavigateMode mode = UnrouterMachineNavigateMode.go,
  }) {
    return _UnrouterMachineNavigateToUriAction(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: mode,
    );
  }

  /// Alias for [navigateRoute].
  static UnrouterMachineAction<void> navigateToRoute<R extends RouteData>(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateRoute(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Navigates to typed [route] using [mode].
  static UnrouterMachineAction<void> navigateRoute<R extends RouteData>(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
    UnrouterMachineNavigateMode mode = UnrouterMachineNavigateMode.go,
  }) {
    return _UnrouterMachineNavigateToRouteAction<R>(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: mode,
    );
  }

  /// Pushes [uri] and resolves typed result on pop.
  static UnrouterMachineAction<Future<T?>> pushUri<T extends Object?>(
    Uri uri, {
    Object? state,
  }) {
    return _UnrouterMachinePushUriAction<T>(uri, state: state);
  }

  /// Pushes typed [route] and resolves typed result on pop.
  static UnrouterMachineAction<Future<T?>>
  pushRoute<R extends RouteData, T extends Object?>(R route, {Object? state}) {
    return _UnrouterMachinePushRouteAction<R, T>(route, state: state);
  }

  /// Replaces current entry with [uri].
  static UnrouterMachineAction<void> replaceUri(
    Uri uri, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateUri(
      uri,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: UnrouterMachineNavigateMode.replace,
    );
  }

  /// Replaces current entry with typed [route].
  static UnrouterMachineAction<void> replaceRoute<R extends RouteData>(
    R route, {
    Object? state,
    bool completePendingResult = false,
    Object? result,
  }) {
    return navigateRoute(
      route,
      state: state,
      completePendingResult: completePendingResult,
      result: result,
      mode: UnrouterMachineNavigateMode.replace,
    );
  }

  /// Pops current entry and optionally passes [result].
  static UnrouterMachineAction<bool> pop([Object? result]) {
    return _UnrouterMachinePopAction(result);
  }

  /// Pops history until [uri] is reached.
  static UnrouterMachineAction<void> popToUri(
    Uri uri, {
    Object? state,
    Object? result,
  }) {
    return _UnrouterMachinePopToUriAction(uri, state: state, result: result);
  }

  /// Goes back one history entry.
  static UnrouterMachineAction<bool> back() {
    return const _UnrouterMachineBackAction();
  }

  /// Goes forward one history entry.
  static UnrouterMachineAction<void> forward() {
    return const _UnrouterMachineForwardAction();
  }

  /// Moves history cursor by [delta].
  static UnrouterMachineAction<void> goDelta(int delta) {
    return _UnrouterMachineGoDeltaAction(delta);
  }

  /// Switches active shell branch.
  static UnrouterMachineAction<bool> switchBranch(
    int index, {
    bool initialLocation = false,
    bool completePendingResult = false,
    Object? result,
  }) {
    return _UnrouterMachineSwitchBranchAction(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }

  /// Pops active shell branch stack.
  static UnrouterMachineAction<bool> popBranch([Object? result]) {
    return _UnrouterMachinePopBranchAction(result);
  }

  /// Event represented by this action.
  UnrouterMachineEvent get event;

  /// Converts declarative action to executable command.
  UnrouterMachineCommand<T> toCommand();
}

final class _UnrouterMachineRouteRequestAction
    extends UnrouterMachineAction<Future<void>> {
  const _UnrouterMachineRouteRequestAction(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.request;

  @override
  UnrouterMachineCommand<Future<void>> toCommand() {
    return UnrouterMachineCommand.routeRequest(uri, state: state);
  }
}

final class _UnrouterMachineNavigateToUriAction
    extends UnrouterMachineAction<void> {
  const _UnrouterMachineNavigateToUriAction(
    this.uri, {
    this.state,
    this.completePendingResult = false,
    this.result,
    this.mode = UnrouterMachineNavigateMode.go,
  });

  final Uri uri;
  final Object? state;
  final bool completePendingResult;
  final Object? result;
  final UnrouterMachineNavigateMode mode;

  @override
  UnrouterMachineEvent get event {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineEvent.goUri,
      UnrouterMachineNavigateMode.replace => UnrouterMachineEvent.replaceUri,
    };
  }

  @override
  UnrouterMachineCommand<void> toCommand() {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineCommand.goUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
      UnrouterMachineNavigateMode.replace => UnrouterMachineCommand.replaceUri(
        uri,
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    };
  }
}

final class _UnrouterMachineNavigateToRouteAction<R extends RouteData>
    extends UnrouterMachineAction<void> {
  const _UnrouterMachineNavigateToRouteAction(
    this.route, {
    this.state,
    this.completePendingResult = false,
    this.result,
    this.mode = UnrouterMachineNavigateMode.go,
  });

  final R route;
  final Object? state;
  final bool completePendingResult;
  final Object? result;
  final UnrouterMachineNavigateMode mode;

  @override
  UnrouterMachineEvent get event {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineEvent.goUri,
      UnrouterMachineNavigateMode.replace => UnrouterMachineEvent.replaceUri,
    };
  }

  @override
  UnrouterMachineCommand<void> toCommand() {
    return switch (mode) {
      UnrouterMachineNavigateMode.go => UnrouterMachineCommand.goUri(
        route.toUri(),
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
      UnrouterMachineNavigateMode.replace => UnrouterMachineCommand.replaceUri(
        route.toUri(),
        state: state,
        completePendingResult: completePendingResult,
        result: result,
      ),
    };
  }
}

final class _UnrouterMachinePushUriAction<T extends Object?>
    extends UnrouterMachineAction<Future<T?>> {
  const _UnrouterMachinePushUriAction(this.uri, {this.state});

  final Uri uri;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;

  @override
  UnrouterMachineCommand<Future<T?>> toCommand() {
    return UnrouterMachineCommand.pushUri<T>(uri, state: state);
  }
}

final class _UnrouterMachinePushRouteAction<
  R extends RouteData,
  T extends Object?
>
    extends UnrouterMachineAction<Future<T?>> {
  const _UnrouterMachinePushRouteAction(this.route, {this.state});

  final R route;
  final Object? state;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pushUri;

  @override
  UnrouterMachineCommand<Future<T?>> toCommand() {
    return UnrouterMachineCommand.pushUri<T>(route.toUri(), state: state);
  }
}

final class _UnrouterMachinePopAction extends UnrouterMachineAction<bool> {
  const _UnrouterMachinePopAction(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.pop;

  @override
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.pop(result);
  }
}

final class _UnrouterMachinePopToUriAction extends UnrouterMachineAction<void> {
  const _UnrouterMachinePopToUriAction(this.uri, {this.state, this.result});

  final Uri uri;
  final Object? state;
  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popToUri;

  @override
  UnrouterMachineCommand<void> toCommand() {
    return UnrouterMachineCommand.popToUri(uri, state: state, result: result);
  }
}

final class _UnrouterMachineBackAction extends UnrouterMachineAction<bool> {
  const _UnrouterMachineBackAction();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.back;

  @override
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.back();
  }
}

final class _UnrouterMachineForwardAction extends UnrouterMachineAction<void> {
  const _UnrouterMachineForwardAction();

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.forward;

  @override
  UnrouterMachineCommand<void> toCommand() {
    return UnrouterMachineCommand.forward();
  }
}

final class _UnrouterMachineGoDeltaAction extends UnrouterMachineAction<void> {
  const _UnrouterMachineGoDeltaAction(this.delta);

  final int delta;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.goDelta;

  @override
  UnrouterMachineCommand<void> toCommand() {
    return UnrouterMachineCommand.goDelta(delta);
  }
}

final class _UnrouterMachineSwitchBranchAction
    extends UnrouterMachineAction<bool> {
  const _UnrouterMachineSwitchBranchAction(
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
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.switchBranch(
      index,
      initialLocation: initialLocation,
      completePendingResult: completePendingResult,
      result: result,
    );
  }
}

final class _UnrouterMachinePopBranchAction
    extends UnrouterMachineAction<bool> {
  const _UnrouterMachinePopBranchAction(this.result);

  final Object? result;

  @override
  UnrouterMachineEvent get event => UnrouterMachineEvent.popBranch;

  @override
  UnrouterMachineCommand<bool> toCommand() {
    return UnrouterMachineCommand.popBranch(result);
  }
}
