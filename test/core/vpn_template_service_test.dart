import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/core/vpn_template_service.dart';
import 'package:worldwide_channel_surf/models/vpn_template.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';

void main() {
  group('vpnTemplateListProvider', () {
    test('should provide list of VPN templates', () {
      final container = ProviderContainer();
      final templates = container.read(vpnTemplateListProvider);

      expect(templates, isA<List<VpnTemplate>>());
      expect(templates.length, equals(2));
    });

    test('should include NordVPN template', () {
      final container = ProviderContainer();
      final templates = container.read(vpnTemplateListProvider);

      final nordvpnTemplate = templates.firstWhere(
        (t) => t.templateId == 'nordvpn',
      );

      expect(nordvpnTemplate.name, equals('NordVPN'));
    });

    test('should include custom .ovpn template', () {
      final container = ProviderContainer();
      final templates = container.read(vpnTemplateListProvider);

      final customTemplate = templates.firstWhere(
        (t) => t.templateId == 'custom_ovpn',
      );

      expect(customTemplate.name, equals('Custom .ovpn File'));
    });
  });

  group('VpnTemplateService', () {
    test('should generate config string for custom .ovpn', () {
      final container = ProviderContainer();
      final service = container.read(vpnTemplateServiceProvider);

      const config = VpnConfig(
        id: 'test1',
        name: 'Test',
        regionId: 'UK',
        templateId: 'custom_ovpn',
        customOvpnContent: 'client\ndev tun\nremote example.com',
      );

      final configString = service.generateConfigString(config);

      expect(configString, equals('client\ndev tun\nremote example.com'));
      expect(configString, isNotEmpty);
    });

    test('should return empty string for custom .ovpn with null content', () {
      final container = ProviderContainer();
      final service = container.read(vpnTemplateServiceProvider);

      const config = VpnConfig(
        id: 'test2',
        name: 'Test',
        regionId: 'UK',
        templateId: 'custom_ovpn',
      );

      final configString = service.generateConfigString(config);

      expect(configString, isEmpty);
    });

    test('should generate NordVPN config string', () {
      final container = ProviderContainer();
      final service = container.read(vpnTemplateServiceProvider);

      const config = VpnConfig(
        id: 'test3',
        name: 'UK NordVPN',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk1234.nordvpn.com',
      );

      final configString = service.generateConfigString(config);

      expect(configString, isNotEmpty);
      expect(configString, contains('uk1234.nordvpn.com'));
      expect(configString, contains('UK'));
      expect(configString, contains('client'));
      expect(configString, contains('dev tun'));
    });

    test('should handle NordVPN config with null serverAddress', () {
      final container = ProviderContainer();
      final service = container.read(vpnTemplateServiceProvider);

      const config = VpnConfig(
        id: 'test4',
        name: 'Test',
        regionId: 'FR',
        templateId: 'nordvpn',
      );

      final configString = service.generateConfigString(config);

      expect(configString, isNotEmpty);
      expect(configString, contains('FR'));
    });

    test('should return empty string for unknown template', () {
      final container = ProviderContainer();
      final service = container.read(vpnTemplateServiceProvider);

      const config = VpnConfig(
        id: 'test5',
        name: 'Test',
        regionId: 'US',
        templateId: 'unknown_template',
      );

      final configString = service.generateConfigString(config);

      expect(configString, isEmpty);
    });
  });
}

