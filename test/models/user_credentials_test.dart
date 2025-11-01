import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/models/user_credentials.dart';

void main() {
  group('UserCredentials', () {
    test('should create UserCredentials with username and password', () {
      const credentials = UserCredentials(
        username: 'testuser',
        password: 'testpass123',
      );

      expect(credentials.username, equals('testuser'));
      expect(credentials.password, equals('testpass123'));
    });

    test('should support empty credentials', () {
      const credentials = UserCredentials(
        username: '',
        password: '',
      );

      expect(credentials.username, isEmpty);
      expect(credentials.password, isEmpty);
    });

    test('should support special characters in credentials', () {
      const credentials = UserCredentials(
        username: 'user@example.com',
        password: 'P@ssw0rd!123',
      );

      expect(credentials.username, equals('user@example.com'));
      expect(credentials.password, equals('P@ssw0rd!123'));
    });
  });
}

