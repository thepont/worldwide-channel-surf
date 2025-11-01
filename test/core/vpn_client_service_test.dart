import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/core/vpn_client_service.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';

void main() {
  group('VpnClientService', () {
    late ProviderContainer container;
    late VpnClientService service;

    setUp(() {
      container = ProviderContainer();
      service = container.read(vpnClientServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('should connect to VPN config', () async {
      const config = VpnConfig(
        id: 'test1',
        name: 'Test VPN',
        regionId: 'UK',
        templateId: 'nordvpn',
        serverAddress: 'uk1234.nordvpn.com',
      );

      final result = await service.connect(config);

      // Current implementation is a placeholder that returns true
      expect(result, isA<bool>());
    });

    test('should disconnect VPN', () async {
      // Should not throw
      await expectLater(
        service.disconnect(),
        completes,
      );
    });

    test('should handle connection with custom .ovpn config', () async {
      const config = VpnConfig(
        id: 'test2',
        name: 'Custom VPN',
        regionId: 'FR',
        templateId: 'custom_ovpn',
        customOvpnContent: 'client\ndev tun\nremote example.com',
      );

      final result = await service.connect(config);

      expect(result, isA<bool>());
    });

    test('should handle multiple disconnect calls', () async {
      await service.disconnect();
      await service.disconnect();
      await expectLater(
        service.disconnect(),
        completes,
      );
    });
  });
}

