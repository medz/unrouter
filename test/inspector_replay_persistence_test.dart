import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/devtools.dart';

void main() {
  group('UnrouterInspectorReplayPersistence', () {
    test('saves and restores replay store payload', () async {
      final adapter = UnrouterInspectorReplayMemoryStorageAdapter();
      final persistence = UnrouterInspectorReplayPersistence(adapter: adapter);

      final source = UnrouterInspectorReplayStore();
      source.addAll(<UnrouterInspectorEmission>[
        _emission('/'),
        _emission('/users/1'),
      ]);
      await persistence.save(source);

      final restored = UnrouterInspectorReplayStore();
      final ok = await persistence.restore(restored);
      expect(ok, isTrue);
      expect(restored.value.entries, hasLength(2));
      expect(restored.value.entries.last.sequence, 2);

      await persistence.clear();
      final missing = await persistence.restore(restored);
      expect(missing, isFalse);

      source.dispose();
      restored.dispose();
    });

    test('migrates legacy list payload to current schema', () async {
      final adapter = UnrouterInspectorReplayMemoryStorageAdapter();
      final key = 'legacy';
      final persistence = UnrouterInspectorReplayPersistence(
        adapter: adapter,
        config: UnrouterInspectorReplayPersistenceConfig(storageKey: key),
      );
      await adapter.write(
        key,
        jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'reason': UnrouterInspectorEmissionReason.initial.name,
            'recordedAt': DateTime(2026, 2, 6, 9, 0, 0).toIso8601String(),
            'report': <String, Object?>{'uri': '/legacy'},
          },
        ]),
      );

      final restored = UnrouterInspectorReplayStore();
      final ok = await persistence.restore(restored);
      expect(ok, isTrue);
      expect(restored.value.entries, hasLength(1));
      expect(restored.value.entries.single.sequence, 1);
      expect(
        restored.value.entries.single.emission.reason,
        UnrouterInspectorEmissionReason.initial,
      );

      restored.dispose();
    });

    test('supports custom migration chain', () {
      final adapter = UnrouterInspectorReplayMemoryStorageAdapter();
      final persistence = UnrouterInspectorReplayPersistence(
        adapter: adapter,
        config: UnrouterInspectorReplayPersistenceConfig(
          targetVersion: 2,
          migrations: <UnrouterInspectorReplayMigration>[
            UnrouterInspectorReplayMigration(
              fromVersion: 1,
              toVersion: 2,
              migrate: (source) {
                return <String, Object?>{
                  ...source,
                  'meta': <String, Object?>{'migrated': true},
                };
              },
            ),
          ],
        ),
      );

      final migrated = persistence.migratePayload(
        jsonEncode(<String, Object?>{'version': 1, 'entries': <Object?>[]}),
      );
      expect(migrated['version'], 2);
      final meta = migrated['meta'] as Map<String, Object?>;
      expect(meta['migrated'], isTrue);
    });
  });
}

UnrouterInspectorEmission _emission(String uri) {
  return UnrouterInspectorEmission(
    reason: UnrouterInspectorEmissionReason.manual,
    recordedAt: DateTime(2026, 2, 6),
    report: <String, Object?>{
      'uri': uri,
      'routePath': uri,
      'resolution': UnrouterResolutionState.matched.name,
    },
  );
}
