import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/devtools.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('UnrouterInspectorReplayController', () {
    test('supports pause and resume during playback', () async {
      final store = UnrouterInspectorReplayStore();
      store.addAll(<UnrouterInspectorEmission>[
        _emission(1, DateTime(2026, 2, 6, 10, 0, 0)),
        _emission(2, DateTime(2026, 2, 6, 10, 0, 1)),
        _emission(3, DateTime(2026, 2, 6, 10, 0, 2)),
      ]);
      final controller = UnrouterInspectorReplayController(
        store: store,
        config: const UnrouterInspectorReplayControllerConfig(
          step: Duration(milliseconds: 40),
        ),
      );

      final stepped = <int>[];
      final future = controller.play(
        onStep: (entry) {
          stepped.add(entry.sequence);
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.pause(), isTrue);
      expect(controller.value.isPaused, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(stepped, isNotEmpty);

      expect(controller.resume(), isTrue);
      final delivered = await future;
      expect(delivered, 3);
      expect(stepped, <int>[1, 2, 3]);
      expect(controller.value.isIdle, isTrue);

      controller.dispose();
      store.dispose();
    });

    test('supports scrub, range, speed cycle and bookmarks', () async {
      final store = UnrouterInspectorReplayStore();
      store.addAll(<UnrouterInspectorEmission>[
        _emission(1, DateTime(2026, 2, 6, 11, 0, 0)),
        _emission(2, DateTime(2026, 2, 6, 11, 0, 1)),
        _emission(3, DateTime(2026, 2, 6, 11, 0, 2)),
        _emission(4, DateTime(2026, 2, 6, 11, 0, 3)),
      ]);
      final controller = UnrouterInspectorReplayController(store: store);

      expect(controller.scrubTo(3), isTrue);
      expect(controller.value.cursorSequence, 3);

      controller.setRange(fromSequence: 2, toSequence: 3);
      expect(controller.scrubTo(1), isTrue);
      expect(controller.value.cursorSequence, 2);

      final bookmark = controller.addBookmark(label: 'focus');
      expect(bookmark.sequence, 2);
      expect(bookmark.group, 'default');
      expect(controller.value.bookmarks, hasLength(1));
      expect(controller.jumpToBookmark(bookmark.id), isTrue);

      final grouped = controller.addBookmark(group: 'auth');
      expect(grouped.group, 'auth');
      expect(controller.value.bookmarksByGroup.keys, contains('auth'));

      final speedBefore = controller.value.speed;
      final speedAfter = controller.cycleSpeedPreset();
      expect(speedAfter, isNot(speedBefore));

      expect(controller.removeBookmark(bookmark.id), isTrue);
      expect(controller.value.bookmarks, hasLength(1));
      controller.clearBookmarks();
      expect(controller.value.bookmarks, isEmpty);

      final stepped = <int>[];
      final delivered = await controller.play(
        restart: true,
        onStep: (entry) {
          stepped.add(entry.sequence);
        },
      );
      expect(delivered, 2);
      expect(stepped, <int>[2, 3]);

      controller.dispose();
      store.dispose();
    });
  });
}

UnrouterInspectorEmission _emission(int sequence, DateTime at) {
  return UnrouterInspectorEmission(
    reason: UnrouterInspectorEmissionReason.manual,
    recordedAt: at,
    report: <String, Object?>{
      'uri': '/$sequence',
      'routePath': '/$sequence',
      'resolution': UnrouterResolutionState.matched.name,
    },
  );
}
