import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/core/storage_service.dart';

/// Provider for managing TMDb API key in secure storage
class TmdbApiKeyNotifier extends StateNotifier<String?> {
  final StorageService _storage = StorageService();
  static const String _storageKey = 'tmdb_api_key';

  TmdbApiKeyNotifier() : super(null) {
    _loadKey();
  }

  Future<void> _loadKey() async {
    try {
      final key = await _storage.read(_storageKey);
      // Only set state if key is not null and not empty
      state = (key != null && key.isNotEmpty) ? key : null;
    } catch (e) {
      state = null;
    }
  }

  Future<void> saveKey(String key) async {
    // Validate key is not empty
    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
    
    try {
      await _storage.write(_storageKey, trimmedKey);
      print('API key written to storage');
      
      // Verify by reading it back
      final verification = await _storage.read(_storageKey);
      if (verification != trimmedKey) {
        throw Exception('Storage verification failed: wrote "$trimmedKey" but read "$verification"');
      }
      
      state = trimmedKey;
      print('API key saved and verified successfully');
    } catch (e, stackTrace) {
      print('Failed to save API key: $e');
      print('Stack trace: $stackTrace');
      // Re-throw so the UI can display the error
      rethrow;
    }
  }

  Future<void> deleteKey() async {
    await _storage.delete(_storageKey);
    state = null;
  }
}

final tmdbApiKeyProvider = StateNotifierProvider<TmdbApiKeyNotifier, String?>((ref) {
  return TmdbApiKeyNotifier();
});

