import 'package:test/test.dart';
import 'package:unrouter/src/runtime/machine_primitives.dart';

void main() {
  group('MachineCommandDispatcher', () {
    test('dispatches commands against runtime', () {
      final runtime = _CounterRuntime();
      final dispatcher = MachineCommandDispatcher<_CounterRuntime>(runtime);

      final first = dispatcher.dispatch(const _IncrementCommand());
      final second = dispatcher.dispatch(const _IncrementCommand());

      expect(first, 1);
      expect(second, 2);
      expect(runtime.count, 2);
    });
  });

  group('MachineTransitionStore', () {
    test('keeps bounded timeline entries', () {
      final store = MachineTransitionStore<int, String, Map<String, Object?>>(
        limit: 2,
      );

      store.append(event: 'a', from: 0, to: 1, payload: const {'v': 1});
      store.append(event: 'b', from: 1, to: 2, payload: const {'v': 2});
      store.append(event: 'c', from: 2, to: 3, payload: const {'v': 3});

      expect(store.entries.length, 2);
      expect(store.entries.first.event, 'b');
      expect(store.entries.last.event, 'c');
      expect(store.entries.first.sequence, 1);
      expect(store.entries.last.sequence, 2);
    });

    test('clear only removes entries and keeps sequence monotonic', () {
      final store = MachineTransitionStore<int, String, int>(limit: 4);

      store.append(event: 'a', from: 0, to: 1, payload: 1);
      store.append(event: 'b', from: 1, to: 2, payload: 2);
      store.clear();
      store.append(event: 'c', from: 2, to: 3, payload: 3);

      expect(store.entries.length, 1);
      expect(store.entries.single.event, 'c');
      expect(store.entries.single.sequence, 2);
    });
  });
}

final class _CounterRuntime implements MachineCommandRuntime {
  int count = 0;
}

final class _IncrementCommand extends MachineCommand<int, _CounterRuntime> {
  const _IncrementCommand();

  @override
  int execute(_CounterRuntime runtime) {
    runtime.count += 1;
    return runtime.count;
  }
}
