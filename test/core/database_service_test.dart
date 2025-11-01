import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/core/database_service.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';
import 'package:worldwide_channel_surf/test/test_helper.dart';

void main() {
  setUpAll(() {
    setupDatabaseFactory();
  });

  group('DatabaseService', () {
    late DatabaseService service;

    setUp(() {
      service = DatabaseService();
    });

    tearDown(() async {
      // Clean up database instance between tests
      // Note: DatabaseService uses singleton, so we can't easily reset
      // But tests should be independent and use the same instance
    });

    test('should be a singleton', () {
      final service1 = DatabaseService();
      final service2 = DatabaseService();

      expect(service1, equals(service2));
    });

    test('should initialize database', () async {
      final db = await service.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('should save and retrieve VPN configs', () async {
      final config = VpnConfig(
        name: 'Test VPN UK',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk1234.nordvpn.com',
      );

      final id = await service.saveVpnConfig(config);
      expect(id, greaterThan(0));

      final retrieved = await service.getVpnConfigById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test VPN UK'));
      expect(retrieved.regionId, equals('UK'));
    });

    test('should get all VPN configs', () async {
      // Clear existing configs by creating new ones
      final config1 = VpnConfig(
        name: 'VPN UK 1',
        regionId: 'UK',
        templateId: 'nordvpn',
      );
      final config2 = VpnConfig(
        name: 'VPN FR 1',
        regionId: 'FR',
        templateId: 'custom_ovpn',
        customOvpnContent: 'custom config content',
      );

      await service.saveVpnConfig(config1);
      await service.saveVpnConfig(config2);

      final configs = await service.getVpnConfigs();
      expect(configs.length, greaterThanOrEqualTo(2));
    });

    test('should get VPN configs by region', () async {
      final ukConfig = VpnConfig(
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
      );
      final frConfig = VpnConfig(
        name: 'FR VPN',
        regionId: 'FR',
        templateId: 'nordvpn',
      );

      await service.saveVpnConfig(ukConfig);
      await service.saveVpnConfig(frConfig);

      final ukConfigs = await service.getVpnConfigsByRegion('UK');
      expect(ukConfigs.any((c) => c.name == 'UK VPN'), isTrue);
      expect(ukConfigs.every((c) => c.regionId == 'UK'), isTrue);
    });

    test('should update existing VPN config', () async {
      final config = VpnConfig(
        name: 'Original Name',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      final id = await service.saveVpnConfig(config);
      
      final updated = config.copyWith(
        id: id,
        name: 'Updated Name',
      );

      await service.saveVpnConfig(updated);

      final retrieved = await service.getVpnConfigById(id);
      expect(retrieved!.name, equals('Updated Name'));
    });

    test('should delete VPN config', () async {
      final config = VpnConfig(
        name: 'To Delete',
        regionId: 'US',
        templateId: 'nordvpn',
      );

      final id = await service.saveVpnConfig(config);
      
      final deleted = await service.deleteVpnConfig(id);
      expect(deleted, equals(1));

      final retrieved = await service.getVpnConfigById(id);
      expect(retrieved, isNull);
    });

    test('should handle configs with custom OVPN content', () async {
      final config = VpnConfig(
        name: 'Custom OVPN',
        regionId: 'DE',
        templateId: 'custom_ovpn',
        customOvpnContent: '''
client
dev tun
remote example.com 1194
...
''',
      );

      final id = await service.saveVpnConfig(config);
      final retrieved = await service.getVpnConfigById(id);

      expect(retrieved!.customOvpnContent, isNotNull);
      expect(retrieved.customOvpnContent, contains('client'));
    });
  });
}

