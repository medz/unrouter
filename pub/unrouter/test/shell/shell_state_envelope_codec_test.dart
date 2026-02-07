import 'package:test/test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  test('encode returns raw user state when shell snapshot is null', () {
    const codec = ShellStateEnvelopeCodec();
    final encoded = codec.encode(
      const ShellStateEnvelope(userState: {'k': 1}, shell: null),
    );

    expect(encoded, {'k': 1});
  });

  test('roundtrip encode/parse with shell snapshot', () {
    const codec = ShellStateEnvelopeCodec();
    final snapshot = ShellRestorationSnapshot(
      activeBranchIndex: 1,
      stacks: <int, ShellBranchStackState>{
        0: ShellBranchStackState(
          entries: <Uri>[
            Uri(path: '/a'),
            Uri(path: '/a/detail'),
          ],
          index: 1,
        ),
      },
    );
    final encoded = codec.encode(
      ShellStateEnvelope(userState: 'payload', shell: snapshot),
    );
    final parsed = codec.tryParse(encoded);

    expect(parsed, isNotNull);
    expect(parsed!.userState, 'payload');
    expect(parsed.shell, isNotNull);
    expect(parsed.shell!.activeBranchIndex, 1);
    expect(parsed.shell!.stacks[0], isNotNull);
    expect(parsed.shell!.stacks[0]!.entries.last.path, '/a/detail');
  });

  test('parse ignores unknown envelope version', () {
    const codec = ShellStateEnvelopeCodec();
    final parsed = codec.tryParse(<String, Object?>{
      ShellStateEnvelopeCodec.metaKey: <String, Object?>{
        ShellStateEnvelopeCodec.versionKey: 2,
      },
      ShellStateEnvelopeCodec.userStateKey: 'x',
    });

    expect(parsed, isNull);
  });
}
