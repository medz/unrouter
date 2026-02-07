/// Advanced machine API for command dispatch and typed machine timeline
/// inspection.
///
/// Import together with `package:flutter_unrouter/flutter_unrouter.dart` when you need low-level
/// routing control or machine diagnostics.
library;

export 'src/runtime/machine_kernel.dart'
    show
        UnrouterMachineSource,
        UnrouterMachineEventGroup,
        UnrouterMachineEvent,
        UnrouterMachineEventGrouping,
        UnrouterMachineState,
        UnrouterMachineTransitionEntry,
        UnrouterMachineTypedPayloadKind,
        UnrouterMachineTypedPayload,
        UnrouterMachineGenericTypedPayload,
        UnrouterMachineNavigationTypedPayload,
        UnrouterMachineRouteTypedPayload,
        UnrouterMachineControllerTypedPayload,
        UnrouterMachineTypedTransition,
        UnrouterMachineCommand,
        UnrouterMachine;
export 'src/runtime/navigation.dart' show UnrouterMachineBuildContextExtension;
