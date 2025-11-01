import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:worldwide_channel_surf/models/show_details.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

// Re-export for convenience
export 'package:worldwide_channel_surf/models/show_details.dart' show WatchProviderType;

/// Service for interacting with The Movie Database (TMDb) API
class TmdbService {
  final String apiKey;
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  TmdbService({required this.apiKey}) {
    if (apiKey.isEmpty) {
      throw ArgumentError('TMDb API key cannot be empty');
    }
  }

  /// Get trending TV shows for a specific region
  Future<List<ShowSummary>> getTrendingShows(RegionId region) async {
    try {
      // Map region to country code for TMDb API
      final countryCode = _regionToCountryCode(region);
      
      final uri = Uri.parse(
        '$_baseUrl/trending/tv/week?api_key=$apiKey&language=en-US&region=$countryCode',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
        
        return results
            .map((json) => ShowSummary.fromTmdbJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('TMDb API authentication failed. Please check your API key.');
      } else {
        throw Exception('TMDb API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch trending shows: $e');
    }
  }

  /// Get all watch providers for a specific show across all regions
  /// Returns a list of providers grouped by region
  Future<List<WatchProvider>> getAllWatchProviders(
    int showId,
    String mediaType, // 'tv' or 'movie'
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$mediaType/$showId/watch/providers?api_key=$apiKey',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic>? results = data['results'] as Map<String, dynamic>?;
        
        if (results == null || results.isEmpty) {
          return [];
        }

        final List<WatchProvider> providers = [];

        // Known free providers (common ad-supported or free streaming services)
        // This list can be expanded based on TMDb provider IDs
        final Set<String> knownFreeProviders = {
          'Tubi',
          'Crackle',
          'YouTube',
          'YouTube Premium',
          'Vudu',
          'Freevee',
          'The Roku Channel',
          'Plex',
          'Pluto TV',
        };

        // Iterate through all regions
        for (final entry in results.entries) {
          final countryCode = entry.key;
          final regionData = entry.value as Map<String, dynamic>?;
          
          if (regionData == null) continue;

          // Map country code to RegionId
          final regionId = _countryCodeToRegionId(countryCode);

          // Get free providers (if available)
          final List<dynamic>? free = regionData['free'] as List<dynamic>?;
          if (free != null && free.isNotEmpty) {
            for (final providerJson in free) {
              final provider = providerJson as Map<String, dynamic>;
              providers.add(WatchProvider.fromTmdbJson(
                provider,
                regionId,
                showId,
                mediaType,
                ProviderType.free,
              ));
            }
          }

          // Get flatrate providers (subscription streaming) - preferred
          final List<dynamic>? flatrate = regionData['flatrate'] as List<dynamic>?;
          if (flatrate != null && flatrate.isNotEmpty) {
            for (final providerJson in flatrate) {
              final provider = providerJson as Map<String, dynamic>;
              final providerName = provider['provider_name'] as String? ?? '';
              
              // Check if it's a known free provider (even if in flatrate)
              final isFree = knownFreeProviders.contains(providerName);
              
              providers.add(WatchProvider.fromTmdbJson(
                provider,
                regionId,
                showId,
                mediaType,
                isFree ? ProviderType.free : ProviderType.subscription,
              ));
            }
          }

          // Skip buy providers (filtered out per user request)

          // Get rent providers (optional - can be included but typically not grouped)
          final List<dynamic>? rent = regionData['rent'] as List<dynamic>?;
          if (rent != null && rent.isNotEmpty) {
            for (final providerJson in rent) {
              final provider = providerJson as Map<String, dynamic>;
              providers.add(WatchProvider.fromTmdbJson(
                provider,
                regionId,
                showId,
                mediaType,
                ProviderType.rent,
              ));
            }
          }
        }

        return providers;
      } else if (response.statusCode == 401) {
        throw Exception('TMDb API authentication failed. Please check your API key.');
      } else {
        throw Exception('TMDb API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch watch providers: $e');
    }
  }

  /// Get watch providers for a specific show (legacy method - returns first provider in region)
  /// Returns the first available provider in the region, or null if none found
  Future<WatchProvider?> getShowWatchProvider(
    int showId,
    RegionId region,
    String mediaType, // 'tv' or 'movie'
  ) async {
    try {
      // Known free providers (common ad-supported or free streaming services)
      final Set<String> knownFreeProviders = {
        'Tubi',
        'Crackle',
        'YouTube',
        'YouTube Premium',
        'Vudu',
        'Freevee',
        'The Roku Channel',
        'Plex',
        'Pluto TV',
      };
      
      final countryCode = _regionToCountryCode(region);
      
      final uri = Uri.parse(
        '$_baseUrl/$mediaType/$showId/watch/providers?api_key=$apiKey',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic>? results = data['results'] as Map<String, dynamic>?;
        
        if (results == null || results.isEmpty) {
          return null;
        }

        // Get providers for the specific region
        final regionData = results[countryCode] as Map<String, dynamic>?;
        if (regionData == null) {
          return null;
        }

        // Try to get a "flatrate" provider (subscription streaming)
        final List<dynamic>? flatrate = regionData['flatrate'] as List<dynamic>?;
        if (flatrate != null && flatrate.isNotEmpty) {
          final provider = flatrate.first as Map<String, dynamic>;
          final providerName = provider['provider_name'] as String? ?? '';
          final isFree = knownFreeProviders.contains(providerName);
          return WatchProvider.fromTmdbJson(
            provider,
            region,
            showId,
            mediaType,
            isFree ? ProviderType.free : ProviderType.subscription,
          );
        }

        // Fallback to rent providers (buy is filtered out)
        final List<dynamic>? rent = regionData['rent'] as List<dynamic>?;
        if (rent != null && rent.isNotEmpty) {
          final provider = rent.first as Map<String, dynamic>;
          return WatchProvider.fromTmdbJson(
            provider,
            region,
            showId,
            mediaType,
            ProviderType.rent,
          );
        }

        return null;
      } else if (response.statusCode == 401) {
        throw Exception('TMDb API authentication failed. Please check your API key.');
      } else {
        throw Exception('TMDb API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch watch provider: $e');
    }
  }

  /// Map ISO country code to RegionId
  RegionId _countryCodeToRegionId(String countryCode) {
    final Map<String, String> countryToRegion = {
      'GB': 'UK',
      'US': 'US',
      'AU': 'AU',
      'FR': 'FR',
      'DE': 'DE',
      'CA': 'CA',
      'IT': 'IT',
      'ES': 'ES',
      'NL': 'NL',
      'BE': 'BE',
      'CH': 'CH',
      'AT': 'AT',
      'SE': 'SE',
      'NO': 'NO',
      'DK': 'DK',
      'FI': 'FI',
      'IE': 'IE',
      'PT': 'PT',
      'GR': 'GR',
      'PL': 'PL',
      'CZ': 'CZ',
      'HU': 'HU',
      'RO': 'RO',
      'BG': 'BG',
      'HR': 'HR',
      'SK': 'SK',
      'SI': 'SI',
      'EE': 'EE',
      'LV': 'LV',
      'LT': 'LT',
    };
    return countryToRegion[countryCode.toUpperCase()] ?? countryCode.toUpperCase();
  }

  /// Search for content (movies and TV shows)
  Future<List<ShowSummary>> searchContent(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final uri = Uri.parse(
        '$_baseUrl/search/multi?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
        
        // Filter to only include TV shows and movies, convert to ShowSummary
        final List<ShowSummary> shows = [];
        for (final result in results) {
          final resultMap = result as Map<String, dynamic>;
          final mediaType = resultMap['media_type'] as String?;
          
          // Only include 'tv' and 'movie' types
          if (mediaType == 'tv' || mediaType == 'movie') {
            shows.add(ShowSummary.fromTmdbJson(resultMap));
          }
        }
        
        return shows;
      } else if (response.statusCode == 401) {
        throw Exception('TMDb API authentication failed. Please check your API key.');
      } else {
        throw Exception('TMDb API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search content: $e');
    }
  }

  /// Get full show details (backdrop, description, etc.)
  Future<Map<String, dynamic>> getShowDetails(int showId, String mediaType) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$mediaType/$showId?api_key=$apiKey&language=en-US',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('TMDb API authentication failed. Please check your API key.');
      } else {
        throw Exception('TMDb API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch show details: $e');
    }
  }

  /// Get ALL watch providers for a show across all regions (new comprehensive method)
  /// Uses WatchProviderType enum for detailed categorization
  Future<List<WatchProvider>> getAllWatchProvidersDetailed(
    int showId,
    String mediaType,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$mediaType/$showId/watch/providers?api_key=$apiKey',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic>? results = data['results'] as Map<String, dynamic>?;

        if (results == null || results.isEmpty) {
          return [];
        }

        final List<WatchProvider> allProviders = [];
        final String deepLink = 'https://www.themoviedb.org/$mediaType/$showId/watch';

        // Iterate through all regions
        for (final entry in results.entries) {
          final countryCode = entry.key;
          final regionData = entry.value as Map<String, dynamic>?;

          if (regionData == null) continue;

          // Map country code to RegionId
          final regionId = _countryCodeToRegionId(countryCode);

          // Helper function to parse provider lists
          void parseProviderList(String key, WatchProviderType type) {
            final List<dynamic>? providers = regionData[key] as List<dynamic>?;
            if (providers != null && providers.isNotEmpty) {
              for (final providerJson in providers) {
                final provider = providerJson as Map<String, dynamic>;
                allProviders.add(WatchProvider.fromTmdbJsonWithType(
                  provider,
                  regionId,
                  deepLink,
                  type,
                ));
              }
            }
          }

          // Parse all provider types
          parseProviderList('flatrate', WatchProviderType.flatrate);
          parseProviderList('free', WatchProviderType.free);
          parseProviderList('ads', WatchProviderType.ads);
          parseProviderList('rent', WatchProviderType.rent);
          parseProviderList('buy', WatchProviderType.buy);
        }

        return allProviders;
      } else if (response.statusCode == 401) {
        throw Exception('TMDb API authentication failed. Please check your API key.');
      } else {
        throw Exception('TMDb API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch watch providers: $e');
    }
  }

  /// Map our RegionId to ISO country code for TMDb API
  String _regionToCountryCode(RegionId region) {
    final Map<String, String> regionToCountry = {
      'UK': 'GB',
      'US': 'US',
      'AU': 'AU',
      'FR': 'FR',
      'DE': 'DE',
      'CA': 'CA',
      'IT': 'IT',
      'ES': 'ES',
      'NL': 'NL',
      'BE': 'BE',
      'CH': 'CH',
      'AT': 'AT',
      'SE': 'SE',
      'NO': 'NO',
      'DK': 'DK',
      'FI': 'FI',
      'IE': 'IE',
      'PT': 'PT',
      'GR': 'GR',
      'PL': 'PL',
      'CZ': 'CZ',
      'HU': 'HU',
      'RO': 'RO',
      'BG': 'BG',
      'HR': 'HR',
      'SK': 'SK',
      'SI': 'SI',
      'EE': 'EE',
      'LV': 'LV',
      'LT': 'LT',
    };
    return regionToCountry[region] ?? region;
  }
}

