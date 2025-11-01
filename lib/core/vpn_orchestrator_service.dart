import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';
import 'package:worldwide_channel_surf/providers/vpn_config_provider.dart';
import 'package:worldwide_channel_surf/providers/vpn_status_provider.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';
import 'package:worldwide_channel_surf/core/vpn_client_service.dart';

enum VpnConnectionResult {
  successVpn,
  successNoVpnNeeded,
  errorNoConfigFound,
  errorFailedToConnect,
}

class VpnOrchestratorService {
  Future<VpnConnectionResult> connectToRegion(
    WidgetRef ref,
    RegionId targetRegionId,
  ) async {
    // Get the current active region
    final currentRegion = ref.read(currentRegionProvider);
    
    // CHECK 1: If targetRegion matches currentRegion, bypass VPN entirely
    if (currentRegion == targetRegionId) {
      // Disconnect any active VPN
      await ref.read(vpnClientServiceProvider).disconnect();
      ref.read(vpnStatusProvider.notifier).state = VpnStatus.disconnected;
      ref.read(vpnConnectedRegionProvider.notifier).state = null;
      
      return VpnConnectionResult.successNoVpnNeeded;
    }
    
    // CHECK 2: Check if we're already connected to the target region
    final connectedRegion = ref.read(vpnConnectedRegionProvider);
    if (connectedRegion == targetRegionId) {
      // Already connected to the right region, no action needed
      return VpnConnectionResult.successVpn;
    }
    
    // CHECK 3: Find a VPN config for the target region
    final vpnConfigs = ref.read(vpnConfigListProvider);
    VpnConfig? matchingConfig;
    try {
      matchingConfig = vpnConfigs
          .firstWhere((config) => config.regionId == targetRegionId);
    } catch (e) {
      matchingConfig = null;
    }
    
    if (matchingConfig == null) {
      return VpnConnectionResult.errorNoConfigFound;
    }
    
    // Disconnect any existing VPN connection
    await ref.read(vpnClientServiceProvider).disconnect();
    ref.read(vpnStatusProvider.notifier).state = VpnStatus.disconnected;
    ref.read(vpnConnectedRegionProvider.notifier).state = null;
    
    // Connect to the new VPN
    ref.read(vpnStatusProvider.notifier).state = VpnStatus.connecting;
    
    try {
      final success = await ref.read(vpnClientServiceProvider).connect(matchingConfig);
      
      if (success) {
        ref.read(vpnStatusProvider.notifier).state = VpnStatus.connected;
        ref.read(vpnConnectedRegionProvider.notifier).state = targetRegionId;
        return VpnConnectionResult.successVpn;
      } else {
        ref.read(vpnStatusProvider.notifier).state = VpnStatus.error;
        return VpnConnectionResult.errorFailedToConnect;
      }
    } catch (e) {
      ref.read(vpnStatusProvider.notifier).state = VpnStatus.error;
      return VpnConnectionResult.errorFailedToConnect;
    }
  }
}

final vpnOrchestratorProvider = Provider<VpnOrchestratorService>((ref) => VpnOrchestratorService());

