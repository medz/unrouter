import 'shell_restoration_snapshot.dart';

/// Parsed shell state envelope.
class ShellStateEnvelope {
  const ShellStateEnvelope({required this.userState, required this.shell});

  /// User payload carried alongside router metadata.
  final Object? userState;

  /// Optional shell restoration snapshot.
  final ShellRestorationSnapshot? shell;
}

/// Codec for shell metadata stored in `history.state`.
class ShellStateEnvelopeCodec {
  const ShellStateEnvelopeCodec();

  static const String metaKey = '__unrouter_meta__';
  static const String userStateKey = '__unrouter_state__';
  static const String versionKey = 'v';
  static const int version = 1;
  static const String shellKey = 'shell';

  Object? encode(ShellStateEnvelope envelope) {
    if (envelope.shell == null) {
      return envelope.userState;
    }

    return <String, Object?>{
      metaKey: <String, Object?>{
        versionKey: version,
        shellKey: envelope.shell!.toJson(),
      },
      userStateKey: envelope.userState,
    };
  }

  ShellStateEnvelope parseOrRaw(Object? state) {
    return tryParse(state) ?? ShellStateEnvelope(userState: state, shell: null);
  }

  ShellStateEnvelope? tryParse(Object? state) {
    if (state is! Map<Object?, Object?>) {
      return null;
    }

    final metaValue = state[metaKey];
    if (metaValue is! Map<Object?, Object?>) {
      return null;
    }

    final rawVersion = metaValue[versionKey];
    if (rawVersion != version) {
      return null;
    }

    final shell = ShellRestorationSnapshot.tryParse(metaValue[shellKey]);
    final userState = state.containsKey(userStateKey)
        ? state[userStateKey]
        : null;
    return ShellStateEnvelope(userState: userState, shell: shell);
  }
}
