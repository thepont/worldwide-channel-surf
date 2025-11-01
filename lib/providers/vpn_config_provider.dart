import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/models/vpn_config.dart';
import 'package:worldwide_channel_surf/core/database_service.dart';

/// Provider for managing VPN configurations with database persistence
class VpnConfigNotifier extends StateNotifier<List<VpnConfig>> {
  final DatabaseService _dbService = DatabaseService();

  VpnConfigNotifier() : super([]) {
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    try {
      final configs = await _dbService.getVpnConfigs();
      state = configs;
    } catch (e) {
      state = [];
    }
  }

  Future<void> addConfig(VpnConfig config) async {
    try {
      await _dbService.saveVpnConfig(config);
      await _loadConfigs();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateConfig(VpnConfig updatedConfig) async {
    try {
      if (updatedConfig.id == null) {
        throw Exception('Cannot update config without ID');
      }
      await _dbService.saveVpnConfig(updatedConfig);
      await _loadConfigs();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeConfig(int id) async {
    try {
      await _dbService.deleteVpnConfig(id);
      await _loadConfigs();
    } catch (e) {
      rethrow;
    }
  }

  VpnConfig? getConfigByRegionId(String regionId) {
    try {
      return state.firstWhere((config) => config.regionId == regionId);
    } catch (e) {
      return null;
    }
  }

  /// Refresh configs from database
  Future<void> refresh() async {
    await _loadConfigs();
  }
}

final vpnConfigListProvider = StateNotifierProvider<VpnConfigNotifier, List<VpnConfig>>((ref) {
  return VpnConfigNotifier();
});

