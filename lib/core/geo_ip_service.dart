import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:worldwide_channel_surf/models/typedefs.dart';

class GeoIpService {
  Future<RegionId?> getRegionFromIp() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? countryCode = data['countryCode'] as String?;
        
        if (countryCode != null) {
          return _mapCountryCodeToRegionId(countryCode);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  RegionId? _mapCountryCodeToRegionId(String countryCode) {
    // Map ISO country codes to RegionId format
    final Map<String, String> codeToRegion = {
      'GB': 'UK',
      'FR': 'FR',
      'AU': 'AU',
      'US': 'US',
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
      // Add more mappings as needed
    };
    return codeToRegion[countryCode.toUpperCase()] ?? countryCode.toUpperCase();
  }
}

final geoIpServiceProvider = Provider<GeoIpService>((ref) => GeoIpService());

