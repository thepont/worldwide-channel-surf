import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

void main() {
  group('VpnConfig', () {
    test('should create a VpnConfig with template-based config', () {
      const config = VpnConfig(
        id: 'config1',
        name: 'UK NordVPN',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk1234.nordvpn.com',
      );

      expect(config.id, equals('config1'));
      expect(config.name, equals('UK NordVPN'));
      expect(config.regionId, equals('UK'));
      expect(config.templateId, equals('nordvpn'));
      expect(config.serverAddress, equals('uk1234.nordvpn.com'));
      expect(config.customOvpnContent, isNull);
    });

    test('should create a VpnConfig with custom .ovpn content', () {
      const ovpnContent = '''
client
dev tun
proto udp
remote example.com 1194
''';

      const config = VpnConfig(
        id: 'config2',
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
        id: 'config3',
        name: 'Empty Config',
        regionId: 'AU',
        templateId: 'nordvpn',
      );

      expect(config.serverAddress, isNull);
      expect(config.customOvpnContent, isNull);
    });

    test('should use RegionId type', () {
      const config = VpnConfig(
        id: 'test',
        name: 'Test',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      expect(config.regionId, isA<RegionId>());
    });
  });
}

