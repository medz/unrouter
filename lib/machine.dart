/// Advanced machine API for command/action dispatch and typed machine timeline
/// inspection.
///
/// Import together with `package:unrouter/unrouter.dart` when you need low-level
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
        UnrouterMachineActionEnvelopeTypedPayload,
        UnrouterMachineNavigationTypedPayload,
        UnrouterMachineRouteTypedPayload,
        UnrouterMachineControllerTypedPayload,
        UnrouterMachineTypedTransition,
        UnrouterMachineCommand,
        UnrouterMachineNavigateMode,
        UnrouterMachineAction,
        UnrouterMachineActionEnvelopeState,
        UnrouterMachineActionRejectCode,
        UnrouterMachineActionFailureCategory,
        UnrouterMachineActionFailure,
        UnrouterMachineActionEnvelope,
        UnrouterMachine;
export 'src/runtime/navigation.dart' show UnrouterMachineBuildContextExtension;
