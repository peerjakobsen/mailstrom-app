import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Simple file-based token storage that works in macOS sandbox
/// without code signing (unlike Keychain via flutter_secure_storage).
class TokenStorage {
  static const _fileName = '.mailstrom_tokens';

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<String?> read(String key) async {
    try {
      final file = await _file;
      if (!await file.exists()) return null;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return data[key] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    final file = await _file;
    Map<String, dynamic> data = {};
    if (await file.exists()) {
      try {
        data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        // Corrupted file, start fresh
      }
    }
    data[key] = value;
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> delete(String key) async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      data.remove(key);
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Ignore delete errors
    }
  }
}
