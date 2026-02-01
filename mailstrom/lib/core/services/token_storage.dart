import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File-based token storage using Application Support directory.
/// Stores tokens as JSON in a hidden file within the app's support directory.
class TokenStorage {
  static const _fileName = '.mailstrom_tokens';

  File? _file;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/$_fileName');
    return _file!;
  }

  Future<Map<String, String>> _readAll() async {
    final file = await _getFile();
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> _writeAll(Map<String, String> data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data));
  }

  Future<String?> read(String key) async {
    final data = await _readAll();
    return data[key];
  }

  Future<void> write(String key, String value) async {
    final data = await _readAll();
    data[key] = value;
    await _writeAll(data);
  }

  Future<void> delete(String key) async {
    final data = await _readAll();
    data.remove(key);
    await _writeAll(data);
  }
}
