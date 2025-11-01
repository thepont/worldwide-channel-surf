import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/providers/vpn_config_provider.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';

void main() {
  group('VpnConfigNotifier', () {
    test('should start with an empty list', () {
      final container = ProviderContainer();
      final configs = container.read(vpnConfigListProvider);

      expect(configs, isEmpty);
    });

    test('should add a VPN config', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      const newConfig = VpnConfig(
        id: 'config1',
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk1234.nordvpn.com',
      );

      notifier.addConfig(newConfig);
      final configs = container.read(vpnConfigListProvider);

      expect(configs.length, equals(1));
      expect(configs.first, equals(newConfig));
    });

    test('should update an existing VPN config', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      const config1 = VpnConfig(
        id: 'config1',
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      const config2 = VpnConfig(
        id: 'config2',
        name: 'FR VPN',
        regionId: 'FR',
        templateId: 'nordvpn',
      );

      notifier.addConfig(config1);
      notifier.addConfig(config2);

      const updatedConfig = VpnConfig(
        id: 'config1',
        name: 'UK VPN Updated',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk5678.nordvpn.com',
      );

      notifier.updateConfig('config1', updatedConfig);
      final configs = container.read(vpnConfigListProvider);

      expect(configs.length, equals(2));
      expect(configs.firstWhere((c) => c.id == 'config1'), equals(updatedConfig));
    });

    test('should remove a VPN config', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      const config1 = VpnConfig(
        id: 'config1',
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      const config2 = VpnConfig(
        id: 'config2',
        name: 'FR VPN',
        regionId: 'FR',
        templateId: 'nordvpn',
      );

      notifier.addConfig(config1);
      notifier.addConfig(config2);
      notifier.removeConfig('config1');

      final configs = container.read(vpnConfigListProvider);

      expect(configs.length, equals(1));
      expect(configs.first.id, equals('config2'));
    });

    test('should get config by region ID', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      const ukConfig = VpnConfig(
        id: 'uk1',
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      const frConfig = VpnConfig(
        id: 'fr1',
        name: 'FR VPN',
        regionId: 'FR',
        templateId: 'nordvpn',
      );

      notifier.addConfig(ukConfig);
      notifier.addConfig(frConfig);

      final foundConfig = notifier.getConfigByRegionId('UK');

      expect(foundConfig, isNotNull);
      expect(foundConfig!.id, equals('uk1'));
      expect(foundConfig.regionId, equals('UK'));
    });

    test('should return null when no config found for region', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      final foundConfig = notifier.getConfigByRegionId('NONEXISTENT');

      expect(foundConfig, isNull);
    });
  });
}

