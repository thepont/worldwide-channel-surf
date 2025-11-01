import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/providers/vpn_config_provider.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';
import 'package:worldwide_channel_surf/test/test_helper.dart';

void main() {
  setUpAll(() {
    setupDatabaseFactory();
  });

  group('VpnConfigNotifier', () {
    test('should start with an empty list', () {
      final container = ProviderContainer();
      final configs = container.read(vpnConfigListProvider);

      expect(configs, isEmpty);
    });

    test('should add a VPN config', () async {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      final newConfig = VpnConfig(
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk1234.nordvpn.com',
      );

      await notifier.addConfig(newConfig);
      final configs = container.read(vpnConfigListProvider);

      expect(configs.length, greaterThanOrEqualTo(1));
      expect(configs.any((c) => c.name == 'UK VPN'), isTrue);
    });

    test('should update an existing VPN config', () async {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      final config1 = VpnConfig(
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      await notifier.addConfig(config1);
      final savedConfig = container.read(vpnConfigListProvider).first;

      final updatedConfig = savedConfig.copyWith(
        name: 'UK VPN Updated',
        serverAddress: 'uk5678.nordvpn.com',
      );

      await notifier.updateConfig(updatedConfig);
      final configs = container.read(vpnConfigListProvider);

      expect(configs.firstWhere((c) => c.id == savedConfig.id).name, equals('UK VPN Updated'));
    });

    test('should remove a VPN config', () async {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      final config1 = VpnConfig(
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      await notifier.addConfig(config1);
      final savedConfig = container.read(vpnConfigListProvider).first;
      final id = savedConfig.id!;

      await notifier.removeConfig(id);
      final configs = container.read(vpnConfigListProvider);

      expect(configs.any((c) => c.id == id), isFalse);
    });

    test('should get config by region ID', () async {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      final ukConfig = VpnConfig(
        name: 'UK VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
      );

      await notifier.addConfig(ukConfig);

      final foundConfig = notifier.getConfigByRegionId('UK');

      expect(foundConfig, isNotNull);
      expect(foundConfig!.regionId, equals('UK'));
    });

    test('should return null when no config found for region', () {
      final container = ProviderContainer();
      final notifier = container.read(vpnConfigListProvider.notifier);

      final foundConfig = notifier.getConfigByRegionId('NONEXISTENT');

      expect(foundConfig, isNull);
    });
  });
}

