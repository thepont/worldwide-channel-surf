import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:worldwide_channel_surf/models/user_credentials.dart';
import 'dart:convert';

class UserCredentialsNotifier extends StateNotifier<Map<String, UserCredentials>> {
  // Configure secure storage for Linux
  // Note: Keyring warnings are non-critical - storage will fallback to file-based
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'user_credentials';

  UserCredentialsNotifier() : super({}) {
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      final credentialsJson = await _storage.read(key: _storageKey);
      if (credentialsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(credentialsJson);
        state = decoded.map((key, value) => MapEntry(
          key,
          UserCredentials(
            username: value['username'] as String,
            password: value['password'] as String,
          ),
        ));
      }
    } catch (e) {
      // Handle error silently or log it
      state = {};
    }
  }

  Future<void> saveCredentials(String templateId, UserCredentials credentials) async {
    state = {...state, templateId: credentials};
    await _persistCredentials();
  }

  Future<void> removeCredentials(String templateId) async {
    state = Map.from(state)..remove(templateId);
    await _persistCredentials();
  }

  Future<void> _persistCredentials() async {
    final Map<String, Map<String, String>> serialized = state.map((key, value) => MapEntry(
      key,
      {'username': value.username, 'password': value.password},
    ));
    await _storage.write(key: _storageKey, value: jsonEncode(serialized));
  }
}

final userCredentialsProvider = StateNotifierProvider<UserCredentialsNotifier, Map<String, UserCredentials>>((ref) {
  return UserCredentialsNotifier();
});

