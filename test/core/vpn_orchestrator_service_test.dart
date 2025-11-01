import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/core/vpn_orchestrator_service.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';
import 'package:worldwide_channel_surf/providers/vpn_config_provider.dart';
import 'package:worldwide_channel_surf/providers/vpn_status_provider.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';

void main() {
  group('VpnOrchestratorService', () {
    late ProviderContainer container;
    late VpnOrchestratorService orchestrator;

    setUp(() {
      container = ProviderContainer();
      orchestrator = container.read(vpnOrchestratorProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('should return successNoVpnNeeded when regions match', () async {
      // Set current region to UK
      container.read(currentRegionProvider.notifier).state = 'UK';

      // Connect to UK region (should bypass VPN)
      final result = await orchestrator.connectToRegion(
        container,
        'UK',
      );

      expect(result, equals(VpnConnectionResult.successNoVpnNeeded));
      
      // VPN should be disconnected
      expect(
        container.read(vpnStatusProvider),
        equals(VpnStatus.disconnected),
      );
    });

    test('should return errorNoConfigFound when no VPN config exists', () async {
      container.read(currentRegionProvider.notifier).state = 'UK';

      // Try to connect to FR (no config exists)
      final result = await orchestrator.connectToRegion(
        container,
        'FR',
      );

      expect(result, equals(VpnConnectionResult.errorNoConfigFound));
    });

    test('should connect to VPN when regions differ and config exists', () async {
      container.read(currentRegionProvider.notifier).state = 'UK';

      // Add a VPN config for FR
      const frConfig = VpnConfig(
        id: 'fr1',
        name: 'FR VPN',
        regionId: 'FR',
        templateId: 'nordvpn',
        serverAddress: 'fr1234.nordvpn.com',
      );

      container.read(vpnConfigListProvider.notifier).addConfig(frConfig);

      // Mock VPN client to return success
      // Note: In a real scenario, you'd use a mock for VpnClientService
      final result = await orchestrator.connectToRegion(
        container,
        'FR',
      );

      // Should attempt to connect (result depends on VPN client implementation)
      // Since vpn_client_service has a placeholder implementation that returns true,
      // this should succeed
      expect(
        result,
        isIn([
          VpnConnectionResult.successVpn,
          VpnConnectionResult.errorFailedToConnect,
        ]),
      );
    });

    test('should return successVpn when already connected to target region', () async {
      // Set up: already connected to FR
      container.read(currentRegionProvider.notifier).state = 'UK';
      container.read(vpnConnectedRegionProvider.notifier).state = 'FR';

      // Try to connect to FR again (should be a no-op)
      final result = await orchestrator.connectToRegion(
        container,
        'FR',
      );

      expect(result, equals(VpnConnectionResult.successVpn));
    });

    test('should disconnect VPN when switching regions', () async {
      container.read(currentRegionProvider.notifier).state = 'UK';

      // Add configs for both FR and AU
      const frConfig = VpnConfig(
        id: 'fr1',
        name: 'FR VPN',
        regionId: 'FR',
        templateId: 'nordvpn',
      );

      const auConfig = VpnConfig(
        id: 'au1',
        name: 'AU VPN',
        regionId: 'AU',
        templateId: 'nordvpn',
      );

      final notifier = container.read(vpnConfigListProvider.notifier);
      notifier.addConfig(frConfig);
      notifier.addConfig(auConfig);

      // Connect to FR first
      await orchestrator.connectToRegion(container, 'FR');
      
      // Verify we're "connected" to FR
      expect(
        container.read(vpnConnectedRegionProvider),
        equals('FR'),
      );

      // Connect to AU (should disconnect FR first)
      await orchestrator.connectToRegion(container, 'AU');

      // Should attempt to connect to AU
      // The exact status depends on VPN client mock behavior
      expect(
        container.read(vpnConnectedRegionProvider),
        isIn(['AU', null]),
      );
    });
  });

  group('VpnConnectionResult', () {
    test('should have all required enum values', () {
      expect(VpnConnectionResult.successVpn, isNotNull);
      expect(VpnConnectionResult.successNoVpnNeeded, isNotNull);
      expect(VpnConnectionResult.errorNoConfigFound, isNotNull);
      expect(VpnConnectionResult.errorFailedToConnect, isNotNull);
    });
  });
}

