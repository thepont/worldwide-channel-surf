import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';

class VpnConfigNotifier extends StateNotifier<List<VpnConfig>> {
  VpnConfigNotifier() : super([]);

  void addConfig(VpnConfig config) {
    state = [...state, config];
    // TODO: Save to persistent storage
  }

  void updateConfig(String id, VpnConfig updatedConfig) {
    state = state.map((config) => config.id == id ? updatedConfig : config).toList();
    // TODO: Save to persistent storage
  }

  void removeConfig(String id) {
    state = state.where((config) => config.id != id).toList();
    // TODO: Save to persistent storage
  }

  VpnConfig? getConfigByRegionId(String regionId) {
    try {
      return state.firstWhere((config) => config.regionId == regionId);
    } catch (e) {
      return null;
    }
  }
}

final vpnConfigListProvider = StateNotifierProvider<VpnConfigNotifier, List<VpnConfig>>((ref) {
  return VpnConfigNotifier();
});

