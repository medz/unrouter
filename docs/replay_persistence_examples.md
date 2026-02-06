# Replay Persistence Examples

This document shows adapter wiring examples for `UnrouterInspectorReplayPersistence`.

## shared_preferences template

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unrouter/unrouter.dart';

Future<UnrouterInspectorReplayPersistence> createReplayPersistence() async {
  final prefs = await SharedPreferences.getInstance();
  final adapter = UnrouterInspectorReplayCallbackStorageAdapter(
    write: (key, payload) async {
      await prefs.setString(key, payload);
    },
    read: (key) async => prefs.getString(key),
    delete: (key) async {
      await prefs.remove(key);
    },
  );
  return UnrouterInspectorReplayPersistence(adapter: adapter);
}
```

## File callback template

```dart
import 'dart:io';

import 'package:unrouter/unrouter.dart';

UnrouterInspectorReplayPersistence createFileReplayPersistence({
  required File file,
}) {
  final adapter = UnrouterInspectorReplayCallbackStorageAdapter(
    write: (key, payload) async {
      await file.writeAsString(payload, flush: true);
    },
    read: (key) async {
      if (!await file.exists()) {
        return null;
      }
      return file.readAsString();
    },
    delete: (key) async {
      if (await file.exists()) {
        await file.delete();
      }
    },
  );
  return UnrouterInspectorReplayPersistence(
    adapter: adapter,
    config: UnrouterInspectorReplayPersistenceConfig(storageKey: file.path),
  );
}
```

The `key` argument is still part of the callback contract for compatibility with key/value stores.
