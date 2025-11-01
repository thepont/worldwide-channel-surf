import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/models/show_details.dart';
import 'package:worldwide_channel_surf/core/tmdb_service.dart';
import 'package:worldwide_channel_surf/providers/settings_provider.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';
import 'package:worldwide_channel_surf/providers/vpn_status_provider.dart';

/// Provider to get TmdbService instance
final tmdbServiceProvider = Provider.family<TmdbService, String>((ref, apiKey) {
  return TmdbService(apiKey: apiKey);
});

/// Provider to fetch the raw show details (description, backdrop)
final showDetailsProvider = FutureProvider.family<Map<String, dynamic>, ({int showId, String mediaType})>(
  (ref, params) async {
    final apiKey = ref.watch(tmdbApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDb API key not set');
    }
    final tmdbService = TmdbService(apiKey: apiKey);
    return await tmdbService.getShowDetails(params.showId, params.mediaType);
  },
);

/// Provider to fetch AND SORT the watch options with smart ranking
final watchOptionsProvider = FutureProvider.family<List<WatchProvider>, ({int showId, String mediaType})>(
  (ref, params) async {
    final apiKey = ref.watch(tmdbApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDb API key not set');
    }
    final tmdbService = TmdbService(apiKey: apiKey);
    
    // Get all providers
    final allProviders = await tmdbService.getAllWatchProvidersDetailed(
      params.showId,
      params.mediaType,
    );
    
    // Get data for smart sorting
    final currentRegion = ref.watch(currentRegionProvider);
    final connectedVpn = ref.watch(vpnConnectedRegionProvider);
    final usageAsync = ref.watch(regionUsageProvider);
    final usageMap = usageAsync.asData?.value ?? {};

    // Filter out "buy" providers (per user requirement)
    final filteredProviders = allProviders.where((p) => p.type != WatchProviderType.buy).toList();

    // The Smart Sort Algorithm
    filteredProviders.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      // Priority 1: Matches user's current region (No VPN needed)
      if (currentRegion != null && a.regionId == currentRegion) scoreA += 1000;
      if (currentRegion != null && b.regionId == currentRegion) scoreB += 1000;

      // Priority 2: Matches already-connected VPN
      if (connectedVpn != null && a.regionId == connectedVpn) scoreA += 500;
      if (connectedVpn != null && b.regionId == connectedVpn) scoreB += 500;

      // Priority 3: Free > Subscription > Rent
      if (a.type == WatchProviderType.free || a.type == WatchProviderType.ads) scoreA += 100;
      if (b.type == WatchProviderType.free || b.type == WatchProviderType.ads) scoreB += 100;
      if (a.type == WatchProviderType.flatrate) scoreA += 50;
      if (b.type == WatchProviderType.flatrate) scoreB += 50;

      // Priority 4: Region usage frequency (most used regions rank higher)
      scoreA += usageMap[a.regionId] ?? 0;
      scoreB += usageMap[b.regionId] ?? 0;

      // Sort descending by score
      return scoreB.compareTo(scoreA);
    });

    return filteredProviders;
  },
);

