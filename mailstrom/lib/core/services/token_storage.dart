import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Secure token storage using macOS Keychain via flutter_secure_storage.
/// Automatically migrates tokens from the old file-based storage on first use.
class TokenStorage {
  static const _oldFileName = '.mailstrom_tokens';
  static const _migratedKey = '_migrated_to_keychain';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  bool _hasMigrated = false;

  Future<void> _migrateIfNeeded() async {
    if (_hasMigrated) return;
    _hasMigrated = true;

    // Check if already migrated
    final migrated = await _storage.read(key: _migratedKey);
    if (migrated == 'true') return;

    // Check for old file
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_oldFileName');
      if (!await file.exists()) {
        // No old file — mark as migrated
        await _storage.write(key: _migratedKey, value: 'true');
        return;
      }

      // Read old tokens and migrate to Keychain
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      for (final entry in data.entries) {
        await _storage.write(key: entry.key, value: entry.value as String);
      }

      // Mark as migrated and delete old file
      await _storage.write(key: _migratedKey, value: 'true');
      await file.delete();
    } catch (_) {
      // Migration failed — mark as done to avoid retry loops
      await _storage.write(key: _migratedKey, value: 'true');
    }
  }

  Future<String?> read(String key) async {
    await _migrateIfNeeded();
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    await _migrateIfNeeded();
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _migrateIfNeeded();
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Ignore delete errors
    }
  }
}
