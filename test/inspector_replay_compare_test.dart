import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/devtools.dart';

void main() {
  group('UnrouterInspectorReplayComparator', () {
    test('compares sessions by sequence and reports changes', () {
      final baseline = UnrouterInspectorReplayStore();
      baseline.addAll(<UnrouterInspectorEmission>[
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/a',
          routePath: '/a',
          at: DateTime(2026, 2, 6, 10, 0, 0),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/b',
          routePath: '/b',
          at: DateTime(2026, 2, 6, 10, 0, 1),
        ),
      ]);

      final current = UnrouterInspectorReplayStore();
      current.addAll(<UnrouterInspectorEmission>[
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/a',
          routePath: '/a',
          at: DateTime(2026, 2, 6, 10, 0, 0),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.stateChanged,
          uri: '/b',
          routePath: '/b',
          at: DateTime(2026, 2, 6, 10, 0, 1),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.redirectChanged,
          uri: '/c',
          routePath: '/c',
          at: DateTime(2026, 2, 6, 10, 0, 2),
        ),
      ]);

      final diff = current.compareWith(baseline);

      expect(diff.mode, UnrouterInspectorReplayCompareMode.sequence);
      expect(diff.changedCount, 1);
      expect(diff.missingBaselineCount, 1);
      expect(diff.missingCurrentCount, 0);
      expect(diff.hasDifferences, isTrue);
      expect(diff.entries, hasLength(2));
      expect(diff.entries.first.key, '2');
      expect(diff.entries.first.type, UnrouterInspectorReplayDiffType.changed);
      expect(
        diff.entries.last.type,
        UnrouterInspectorReplayDiffType.missingBaseline,
      );

      baseline.dispose();
      current.dispose();
    });

    test('compares sessions by path', () {
      final baseline = UnrouterInspectorReplayStore();
      baseline.addAll(<UnrouterInspectorEmission>[
        _emission(
          reason: UnrouterInspectorEmissionReason.initial,
          uri: '/home',
          routePath: '/home',
          at: DateTime(2026, 2, 6, 9, 0, 0),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/settings',
          routePath: '/settings',
          at: DateTime(2026, 2, 6, 9, 0, 1),
        ),
      ]);
      final current = UnrouterInspectorReplayStore();
      current.addAll(<UnrouterInspectorEmission>[
        _emission(
          reason: UnrouterInspectorEmissionReason.initial,
          uri: '/home',
          routePath: '/home',
          at: DateTime(2026, 2, 6, 9, 0, 0),
        ),
        _emission(
          reason: UnrouterInspectorEmissionReason.manual,
          uri: '/profile',
          routePath: '/profile',
          at: DateTime(2026, 2, 6, 9, 0, 1),
        ),
      ]);

      final diff = UnrouterInspectorReplayComparator.compare(
        baseline: baseline.value.entries,
        current: current.value.entries,
        mode: UnrouterInspectorReplayCompareMode.path,
      );

      expect(diff.mode, UnrouterInspectorReplayCompareMode.path);
      expect(diff.changedCount, 0);
      expect(diff.missingBaselineCount, 1);
      expect(diff.missingCurrentCount, 1);
      expect(
        diff.entries.any(
          (entry) => entry.key == '/profile' && entry.currentSequence == 2,
        ),
        isTrue,
      );
      expect(
        diff.entries.any(
          (entry) => entry.key == '/settings' && entry.baselineSequence == 2,
        ),
        isTrue,
      );

      baseline.dispose();
      current.dispose();
    });
  });
}

UnrouterInspectorEmission _emission({
  required UnrouterInspectorEmissionReason reason,
  required String uri,
  required String routePath,
  required DateTime at,
}) {
  return UnrouterInspectorEmission(
    reason: reason,
    recordedAt: at,
    report: <String, Object?>{
      'uri': uri,
      'routePath': routePath,
      'resolution': UnrouterResolutionState.matched.name,
    },
  );
}
