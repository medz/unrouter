part of 'navigation.dart';

enum UnrouterMachineActionEnvelopeState {
  accepted,
  rejected,
  deferred,
  completed,
}

enum UnrouterMachineActionRejectCode {
  unknown,
  noBackHistory,
  popRejected,
  branchUnavailable,
  branchEmpty,
  deferredError,
}

enum UnrouterMachineActionFailureCategory {
  unknown,
  history,
  shell,
  asynchronous,
}

class UnrouterMachineActionFailure {
  const UnrouterMachineActionFailure({
    required this.code,
    required this.message,
    required this.category,
    this.retryable = false,
    this.metadata = const <String, Object?>{},
  });

  final UnrouterMachineActionRejectCode code;
  final String message;
  final UnrouterMachineActionFailureCategory category;
  final bool retryable;
  final Map<String, Object?> metadata;

  static UnrouterMachineActionFailure? tryParse(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }
    final map = <String, Object?>{};
    for (final entry in value.entries) {
      map['${entry.key}'] = entry.value;
    }
    final code =
        tryParseCode(map['code']?.toString()) ??
        UnrouterMachineActionRejectCode.unknown;
    final message = map['message']?.toString() ?? map['reason']?.toString();
    final category =
        tryParseCategory(map['category']?.toString()) ?? _inferCategory(code);
    final retryable = _toBool(map['retryable']) ?? _inferRetryable(code);
    return UnrouterMachineActionFailure(
      code: code,
      message: message ?? 'Machine command returned false.',
      category: category,
      retryable: retryable,
      metadata: _toMetadataMap(map['metadata']),
    );
  }

  static UnrouterMachineActionRejectCode? tryParseCode(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final code in UnrouterMachineActionRejectCode.values) {
      if (code.name == value) {
        return code;
      }
    }
    return null;
  }

  static UnrouterMachineActionFailureCategory? tryParseCategory(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final category in UnrouterMachineActionFailureCategory.values) {
      if (category.name == value) {
        return category;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code.name,
      'message': message,
      'category': category.name,
      'retryable': retryable,
      'metadata': metadata,
    };
  }

  static UnrouterMachineActionFailureCategory _inferCategory(
    UnrouterMachineActionRejectCode code,
  ) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return UnrouterMachineActionFailureCategory.unknown;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
        return UnrouterMachineActionFailureCategory.history;
      case UnrouterMachineActionRejectCode.branchUnavailable:
      case UnrouterMachineActionRejectCode.branchEmpty:
        return UnrouterMachineActionFailureCategory.shell;
      case UnrouterMachineActionRejectCode.deferredError:
        return UnrouterMachineActionFailureCategory.asynchronous;
    }
  }

  static bool _inferRetryable(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return false;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
      case UnrouterMachineActionRejectCode.branchEmpty:
      case UnrouterMachineActionRejectCode.deferredError:
        return true;
    }
  }

  static bool? _toBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  static Map<String, Object?> _toMetadataMap(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return const <String, Object?>{};
    }
    final metadata = <String, Object?>{};
    for (final entry in value.entries) {
      metadata['${entry.key}'] = entry.value;
    }
    return Map<String, Object?>.unmodifiable(metadata);
  }
}

class UnrouterMachineActionEnvelope<T> {
  static const int schemaVersion = 2;
  static const int minimumCompatibleSchemaVersion = 1;
  static const int eventVersion = 2;
  static const int minimumCompatibleEventVersion = 1;
  static const String producer = 'unrouter.machine';

  static bool isSchemaVersionCompatible(int version) {
    return version >= minimumCompatibleSchemaVersion &&
        version <= schemaVersion;
  }

  static bool isEventVersionCompatible(int version) {
    return version >= minimumCompatibleEventVersion && version <= eventVersion;
  }

  const UnrouterMachineActionEnvelope._({
    required this.state,
    required this.event,
    this.value,
    this.rejectCode,
    this.rejectReason,
    this.failure,
  });

  factory UnrouterMachineActionEnvelope.accepted({
    required UnrouterMachineEvent event,
    T? value,
  }) {
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.accepted,
      event: event,
      value: value,
    );
  }

  factory UnrouterMachineActionEnvelope.rejected({
    required UnrouterMachineEvent event,
    T? value,
    UnrouterMachineActionRejectCode? rejectCode,
    String? rejectReason,
    UnrouterMachineActionFailure? failure,
  }) {
    final resolvedFailure =
        failure ??
        _legacyFailureFromRejectFields(
          rejectCode: rejectCode,
          rejectReason: rejectReason,
        );
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.rejected,
      event: event,
      value: value,
      rejectCode: resolvedFailure?.code ?? rejectCode,
      rejectReason: resolvedFailure?.message ?? rejectReason,
      failure: resolvedFailure,
    );
  }

  factory UnrouterMachineActionEnvelope.deferred({
    required UnrouterMachineEvent event,
    required T value,
  }) {
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.deferred,
      event: event,
      value: value,
    );
  }

  factory UnrouterMachineActionEnvelope.completed({
    required UnrouterMachineEvent event,
    required T value,
  }) {
    return UnrouterMachineActionEnvelope<T>._(
      state: UnrouterMachineActionEnvelopeState.completed,
      event: event,
      value: value,
    );
  }

  final UnrouterMachineActionEnvelopeState state;
  final UnrouterMachineEvent event;
  final T? value;
  final UnrouterMachineActionRejectCode? rejectCode;
  final String? rejectReason;
  final UnrouterMachineActionFailure? failure;

  bool get isAccepted {
    return state == UnrouterMachineActionEnvelopeState.accepted ||
        state == UnrouterMachineActionEnvelopeState.deferred ||
        state == UnrouterMachineActionEnvelopeState.completed;
  }

  bool get isRejected => state == UnrouterMachineActionEnvelopeState.rejected;

  bool get isDeferred => state == UnrouterMachineActionEnvelopeState.deferred;

  bool get isCompleted => state == UnrouterMachineActionEnvelopeState.completed;

  Map<String, Object?> toJson() {
    final value = this.value;
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'eventVersion': eventVersion,
      'producer': producer,
      'state': state.name,
      'event': event.name,
      'isAccepted': isAccepted,
      'isRejected': isRejected,
      'isDeferred': isDeferred,
      'isCompleted': isCompleted,
      'rejectCode': rejectCode?.name,
      'rejectReason': rejectReason,
      'failure': failure?.toJson(),
      'hasValue': value != null,
      'valueType': value?.runtimeType.toString(),
    };
  }

  static UnrouterMachineActionFailure? _legacyFailureFromRejectFields({
    required UnrouterMachineActionRejectCode? rejectCode,
    required String? rejectReason,
  }) {
    if (rejectCode == null && rejectReason == null) {
      return null;
    }
    final code = rejectCode ?? UnrouterMachineActionRejectCode.unknown;
    return UnrouterMachineActionFailure(
      code: code,
      message: rejectReason ?? 'Machine command returned false.',
      category: _defaultFailureCategory(code),
      retryable: _defaultRetryable(code),
    );
  }

  static UnrouterMachineActionFailureCategory _defaultFailureCategory(
    UnrouterMachineActionRejectCode code,
  ) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
        return UnrouterMachineActionFailureCategory.unknown;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
        return UnrouterMachineActionFailureCategory.history;
      case UnrouterMachineActionRejectCode.branchUnavailable:
      case UnrouterMachineActionRejectCode.branchEmpty:
        return UnrouterMachineActionFailureCategory.shell;
      case UnrouterMachineActionRejectCode.deferredError:
        return UnrouterMachineActionFailureCategory.asynchronous;
    }
  }

  static bool _defaultRetryable(UnrouterMachineActionRejectCode code) {
    switch (code) {
      case UnrouterMachineActionRejectCode.unknown:
      case UnrouterMachineActionRejectCode.branchUnavailable:
        return false;
      case UnrouterMachineActionRejectCode.noBackHistory:
      case UnrouterMachineActionRejectCode.popRejected:
      case UnrouterMachineActionRejectCode.branchEmpty:
      case UnrouterMachineActionRejectCode.deferredError:
        return true;
    }
  }
}
