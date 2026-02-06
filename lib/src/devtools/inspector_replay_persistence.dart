import 'dart:convert';

import 'inspector_replay_store.dart';

/// Storage abstraction for replay persistence.
abstract interface class UnrouterInspectorReplayStorageAdapter {
  Future<void> write(String key, String payload);

  Future<String?> read(String key);

  Future<void> delete(String key);
}

/// In-memory storage adapter for replay persistence.
class UnrouterInspectorReplayMemoryStorageAdapter
    implements UnrouterInspectorReplayStorageAdapter {
  final Map<String, String> _storage = <String, String>{};

  @override
  Future<void> write(String key, String payload) async {
    _storage[key] = payload;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }
}

/// Callback-based storage adapter for replay persistence.
class UnrouterInspectorReplayCallbackStorageAdapter
    implements UnrouterInspectorReplayStorageAdapter {
  const UnrouterInspectorReplayCallbackStorageAdapter({
    required Future<void> Function(String key, String payload) write,
    required Future<String?> Function(String key) read,
    required Future<void> Function(String key) delete,
  }) : _write = write,
       _read = read,
       _delete = delete;

  final Future<void> Function(String key, String payload) _write;
  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key) _delete;

  @override
  Future<void> write(String key, String payload) {
    return _write(key, payload);
  }

  @override
  Future<String?> read(String key) {
    return _read(key);
  }

  @override
  Future<void> delete(String key) {
    return _delete(key);
  }
}

/// One payload migration step between schema versions.
class UnrouterInspectorReplayMigration {
  const UnrouterInspectorReplayMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.migrate,
  }) : assert(
         toVersion > fromVersion,
         'Unrouter inspector replay migration toVersion must be greater than fromVersion.',
       );

  final int fromVersion;
  final int toVersion;
  final Map<String, Object?> Function(Map<String, Object?> source) migrate;
}

/// Configuration for [UnrouterInspectorReplayPersistence].
class UnrouterInspectorReplayPersistenceConfig {
  const UnrouterInspectorReplayPersistenceConfig({
    this.storageKey = 'unrouter.inspector.replay',
    this.targetVersion = UnrouterInspectorReplayStore.schemaVersion,
    this.pretty = false,
    this.migrations = const <UnrouterInspectorReplayMigration>[],
  }) : assert(
         targetVersion > 0,
         'Unrouter inspector replay persistence targetVersion must be greater than zero.',
       );

  final String storageKey;
  final int targetVersion;
  final bool pretty;
  final List<UnrouterInspectorReplayMigration> migrations;
}

/// Save/restore utility for replay store snapshots.
class UnrouterInspectorReplayPersistence {
  const UnrouterInspectorReplayPersistence({
    required this.adapter,
    this.config = const UnrouterInspectorReplayPersistenceConfig(),
  });

  final UnrouterInspectorReplayStorageAdapter adapter;
  final UnrouterInspectorReplayPersistenceConfig config;

  /// Saves replay store snapshot using configured adapter.
  Future<void> save(UnrouterInspectorReplayStore store, {int? tail}) async {
    final payload = store.exportJson(tail: tail, pretty: config.pretty);
    await adapter.write(config.storageKey, payload);
  }

  /// Restores replay store snapshot from configured adapter.
  Future<bool> restore(
    UnrouterInspectorReplayStore store, {
    bool clearExisting = true,
  }) async {
    final payload = await adapter.read(config.storageKey);
    if (payload == null || payload.trim().isEmpty) {
      return false;
    }
    final migrated = migratePayload(payload);
    store.importJson(jsonEncode(migrated), clearExisting: clearExisting);
    return true;
  }

  /// Clears persisted replay payload.
  Future<void> clear() {
    return adapter.delete(config.storageKey);
  }

  /// Applies built-in and custom migrations to persisted payload.
  Map<String, Object?> migratePayload(String payload) {
    final decoded = jsonDecode(payload);
    final normalized = _normalizePayload(decoded);
    return _applyMigrations(normalized);
  }

  Map<String, Object?> _normalizePayload(Object? value) {
    if (value is List<Object?>) {
      return <String, Object?>{'version': 0, 'entries': value};
    }
    if (value is! Map<Object?, Object?>) {
      throw const FormatException(
        'Unrouter inspector replay persistence payload must be a map or list.',
      );
    }
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      normalized['${entry.key}'] = entry.value;
    }
    if (normalized['version'] == null) {
      normalized['version'] = 0;
    }
    return normalized;
  }

  Map<String, Object?> _applyMigrations(Map<String, Object?> payload) {
    final migrations = <UnrouterInspectorReplayMigration>[
      ..._defaultMigrations(),
      ...config.migrations,
    ];
    final byFrom = <int, UnrouterInspectorReplayMigration>{};
    for (final migration in migrations) {
      byFrom[migration.fromVersion] = migration;
    }

    var current = payload;
    var version = _toInt(current['version']) ?? 0;
    if (version > config.targetVersion) {
      throw StateError(
        'Unrouter inspector replay payload version $version is newer than target ${config.targetVersion}.',
      );
    }

    while (version < config.targetVersion) {
      final migration = byFrom[version];
      if (migration == null) {
        throw StateError(
          'Missing replay migration from version $version to ${config.targetVersion}.',
        );
      }
      current = migration.migrate(current);
      version = migration.toVersion;
      current['version'] = version;
    }
    return current;
  }

  List<UnrouterInspectorReplayMigration> _defaultMigrations() {
    return <UnrouterInspectorReplayMigration>[
      UnrouterInspectorReplayMigration(
        fromVersion: 0,
        toVersion: 1,
        migrate: (source) {
          final entries = source['entries'] ?? source['emissions'];
          return <String, Object?>{
            ...source,
            'version': 1,
            'entries': entries is List<Object?> ? entries : const <Object?>[],
          };
        },
      ),
    ];
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
