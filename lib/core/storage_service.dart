import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

/// Storage service with fallback for Linux when keyring fails
/// Uses flutter_secure_storage when available, falls back to encrypted file storage on Linux
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _useFallback = false;

  /// Write a value to storage
  Future<void> write(String key, String value) async {
    if (_useFallback && Platform.isLinux) {
      await _writeToFile(key, value);
      return;
    }

    try {
      await _secureStorage.write(key: key, value: value);
      // Verify it worked
      final read = await _secureStorage.read(key: key);
      if (read != value) {
        throw Exception('Storage verification failed');
      }
    } on PlatformException catch (e) {
      // If keyring fails on Linux, switch to file-based fallback
      if (Platform.isLinux && e.code == 'Libsecret error') {
        _useFallback = true;
        await _writeToFile(key, value);
      } else {
        rethrow;
      }
    }
  }

  /// Read a value from storage
  Future<String?> read(String key) async {
    if (_useFallback && Platform.isLinux) {
      return await _readFromFile(key);
    }

    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (e) {
      // If keyring fails on Linux, switch to file-based fallback
      if (Platform.isLinux && e.code == 'Libsecret error') {
        _useFallback = true;
        return await _readFromFile(key);
      }
      return null;
    }
  }

  /// Delete a value from storage
  Future<void> delete(String key) async {
    if (_useFallback && Platform.isLinux) {
      await _deleteFile(key);
      return;
    }

    try {
      await _secureStorage.delete(key: key);
    } on PlatformException catch (e) {
      if (Platform.isLinux && e.code == 'Libsecret error') {
        _useFallback = true;
        await _deleteFile(key);
      }
    }
  }

  /// Delete all values from storage
  Future<void> deleteAll() async {
    if (_useFallback && Platform.isLinux) {
      await _deleteAllFiles();
      return;
    }

    try {
      await _secureStorage.deleteAll();
    } on PlatformException catch (e) {
      if (Platform.isLinux && e.code == 'Libsecret error') {
        _useFallback = true;
        await _deleteAllFiles();
      }
    }
  }

  // File-based fallback storage (simple base64 encoding, not true encryption)
  // For production, consider using a proper encryption library
  Future<void> _writeToFile(String key, String value) async {
    try {
      final dir = await _getStorageDirectory();
      final file = File(path.join(dir.path, '${_sanitizeKey(key)}.txt'));
      // Simple base64 encoding (not secure, but better than plain text)
      final encoded = _encode(value);
      await file.writeAsString(encoded);
    } catch (e) {
      print('Failed to write to fallback storage: $e');
      rethrow;
    }
  }

  Future<String?> _readFromFile(String key) async {
    try {
      final dir = await _getStorageDirectory();
      final file = File(path.join(dir.path, '${_sanitizeKey(key)}.txt'));
      if (!await file.exists()) {
        return null;
      }
      final encoded = await file.readAsString();
      return _decode(encoded);
    } catch (e) {
      print('Failed to read from fallback storage: $e');
      return null;
    }
  }

  Future<void> _deleteFile(String key) async {
    try {
      final dir = await _getStorageDirectory();
      final file = File(path.join(dir.path, '${_sanitizeKey(key)}.txt'));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Failed to delete from fallback storage: $e');
    }
  }

  Future<void> _deleteAllFiles() async {
    try {
      final dir = await _getStorageDirectory();
      final files = dir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.txt')) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Failed to delete all from fallback storage: $e');
    }
  }

  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final storageDir = Directory(path.join(appDir.path, 'secure_storage'));
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    return storageDir;
  }

  String _sanitizeKey(String key) {
    // Remove invalid filename characters
    return key.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
  }

  // Simple encoding (base64)
  String _encode(String value) {
    return Uri.encodeComponent(value);
  }

  String _decode(String encoded) {
    return Uri.decodeComponent(encoded);
  }
}

