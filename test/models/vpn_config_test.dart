import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

void main() {
  group('VpnConfig', () {
    test('should create a VpnConfig with template-based config', () {
      const config = VpnConfig(
        id: 1,
        name: 'UK NordVPN',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk1234.nordvpn.com',
      );

      expect(config.id, equals(1));
      expect(config.name, equals('UK NordVPN'));
      expect(config.regionId, equals('UK'));
      expect(config.templateId, equals('nordvpn'));
      expect(config.serverAddress, equals('uk1234.nordvpn.com'));
      expect(config.customOvpnContent, isNull);
    });

    test('should create a VpnConfig without id for new entries', () {
      const config = VpnConfig(
        name: 'New VPN',
        regionId: 'FR',
        templateId: 'nordvpn',
      );

      expect(config.id, isNull);
      expect(config.name, equals('New VPN'));
    });

    test('should create a VpnConfig with custom .ovpn content', () {
      const ovpnContent = '''
client
dev tun
proto udp
remote example.com 1194
''';

      const config = VpnConfig(
        id: 2,
        name: 'Custom VPN',
        regionId: 'FR',
        templateId: 'custom_ovpn',
        customOvpnContent: ovpnContent,
      );

      expect(config.templateId, equals('custom_ovpn'));
      expect(config.customOvpnContent, equals(ovpnContent));
      expect(config.serverAddress, isNull);
    });

    test('should support both serverAddress and customOvpnContent being null', () {
      const config = VpnConfig(
        name: 'Empty Config',
        regionId: 'AU',
        templateId: 'nordvpn',
      );

      expect(config.serverAddress, isNull);
      expect(config.customOvpnContent, isNull);
    });

    test('should use RegionId type', () {
      const config = VpnConfig(
        name: 'Test',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      expect(config.regionId, isA<RegionId>());
    });

    test('should convert to map for database storage', () {
      const config = VpnConfig(
        id: 5,
        name: 'Test VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'test.server.com',
      );

      final map = config.toMap();

      expect(map['id'], equals(5));
      expect(map['name'], equals('Test VPN'));
      expect(map['region_id'], equals('UK'));
      expect(map['template_id'], equals('nordvpn'));
      expect(map['server_address'], equals('test.server.com'));
    });

    test('should create from map (database result)', () {
      final map = {
        'id': 10,
        'name': 'Restored VPN',
        'region_id': 'US',
        'template_id': 'nordvpn',
        'server_address': 'us123.nordvpn.com',
        'custom_ovpn_content': null,
      };

      final config = VpnConfig.fromMap(map);

      expect(config.id, equals(10));
      expect(config.name, equals('Restored VPN'));
      expect(config.regionId, equals('US'));
      expect(config.templateId, equals('nordvpn'));
    });

    test('should copy with updated fields', () {
      const original = VpnConfig(
        id: 1,
        name: 'Original',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      final updated = original.copyWith(name: 'Updated', regionId: 'FR');

      expect(updated.id, equals(1));
      expect(updated.name, equals('Updated'));
      expect(updated.regionId, equals('FR'));
      expect(updated.templateId, equals('nordvpn'));
    });
  });
}

