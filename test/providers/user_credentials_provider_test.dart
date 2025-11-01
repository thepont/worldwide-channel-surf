import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/providers/user_credentials_provider.dart';
import 'package:worldwide_channel_surf/models/user_credentials.dart';

void main() {
  group('UserCredentialsNotifier', () {
    test('should start with empty credentials map', () {
      final container = ProviderContainer();
      final credentials = container.read(userCredentialsProvider);

      expect(credentials, isEmpty);
    });

    test('should save credentials for a template', () async {
      final container = ProviderContainer();
      final notifier = container.read(userCredentialsProvider.notifier);

      const credentials = UserCredentials(
        username: 'testuser',
        password: 'testpass',
      );

      await notifier.saveCredentials('nordvpn', credentials);
      final saved = container.read(userCredentialsProvider);

      expect(saved.containsKey('nordvpn'), isTrue);
      expect(saved['nordvpn'], equals(credentials));
      expect(saved['nordvpn']!.username, equals('testuser'));
      expect(saved['nordvpn']!.password, equals('testpass'));
    });

    test('should save credentials for multiple templates', () async {
      final container = ProviderContainer();
      final notifier = container.read(userCredentialsProvider.notifier);

      const nordvpnCreds = UserCredentials(
        username: 'nordvpn_user',
        password: 'nordvpn_pass',
      );

      const customCreds = UserCredentials(
        username: 'custom_user',
        password: 'custom_pass',
      );

      await notifier.saveCredentials('nordvpn', nordvpnCreds);
      await notifier.saveCredentials('custom_ovpn', customCreds);

      final saved = container.read(userCredentialsProvider);

      expect(saved.length, equals(2));
      expect(saved['nordvpn'], equals(nordvpnCreds));
      expect(saved['custom_ovpn'], equals(customCreds));
    });

    test('should remove credentials for a template', () async {
      final container = ProviderContainer();
      final notifier = container.read(userCredentialsProvider.notifier);

      const credentials = UserCredentials(
        username: 'testuser',
        password: 'testpass',
      );

      await notifier.saveCredentials('nordvpn', credentials);
      await notifier.removeCredentials('nordvpn');

      final saved = container.read(userCredentialsProvider);

      expect(saved.containsKey('nordvpn'), isFalse);
      expect(saved, isEmpty);
    });

    test('should update existing credentials', () async {
      final container = ProviderContainer();
      final notifier = container.read(userCredentialsProvider.notifier);

      const initialCreds = UserCredentials(
        username: 'olduser',
        password: 'oldpass',
      );

      const updatedCreds = UserCredentials(
        username: 'newuser',
        password: 'newpass',
      );

      await notifier.saveCredentials('nordvpn', initialCreds);
      await notifier.saveCredentials('nordvpn', updatedCreds);

      final saved = container.read(userCredentialsProvider);

      expect(saved['nordvpn'], equals(updatedCreds));
      expect(saved['nordvpn']!.username, equals('newuser'));
    });
  });
}

