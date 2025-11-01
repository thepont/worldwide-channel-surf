import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:worldwide_channel_surf/models/show_details.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';

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

        // Iterate through all regions
        for (final entry in results.entries) {
          final countryCode = entry.key;
          final regionData = entry.value as Map<String, dynamic>?;
          
          if (regionData == null) continue;

          // Map country code to RegionId
          final regionId = _countryCodeToRegionId(countryCode);

          // Get flatrate providers (subscription streaming) - preferred
          final List<dynamic>? flatrate = regionData['flatrate'] as List<dynamic>?;
          if (flatrate != null && flatrate.isNotEmpty) {
            for (final providerJson in flatrate) {
              final provider = providerJson as Map<String, dynamic>;
              providers.add(WatchProvider.fromTmdbJson(
                provider,
                regionId,
                showId,
                mediaType,
              ));
            }
          }

          // Get buy providers
          final List<dynamic>? buy = regionData['buy'] as List<dynamic>?;
          if (buy != null && buy.isNotEmpty) {
            for (final providerJson in buy) {
              final provider = providerJson as Map<String, dynamic>;
              providers.add(WatchProvider.fromTmdbJson(
                provider,
                regionId,
                showId,
                mediaType,
              ));
            }
          }

          // Get rent providers
          final List<dynamic>? rent = regionData['rent'] as List<dynamic>?;
          if (rent != null && rent.isNotEmpty) {
            for (final providerJson in rent) {
              final provider = providerJson as Map<String, dynamic>;
              providers.add(WatchProvider.fromTmdbJson(
                provider,
                regionId,
                showId,
                mediaType,
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
          return WatchProvider.fromTmdbJson(
            provider,
            region,
            showId,
            mediaType,
          );
        }

        // Fallback to "buy" or "rent" providers
        final List<dynamic>? buy = regionData['buy'] as List<dynamic>?;
        if (buy != null && buy.isNotEmpty) {
          final provider = buy.first as Map<String, dynamic>;
          return WatchProvider.fromTmdbJson(
            provider,
            region,
            showId,
            mediaType,
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

