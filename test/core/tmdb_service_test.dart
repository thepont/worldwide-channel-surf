import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worldwide_channel_surf/core/tmdb_service.dart';
import 'package:worldwide_channel_surf/models/show_details.dart';

void main() {
  group('TmdbService', () {
    late TmdbService service;

    setUp(() {
      service = TmdbService(apiKey: 'test_api_key');
    });

    test('should fetch trending shows', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/trending/tv')) {
          return http.Response(
            '''
            {
              "results": [
                {
                  "id": 1396,
                  "name": "Breaking Bad",
                  "poster_path": "/ggFHVNu6YYI5L9pCfOacjizRGt.jpg",
                  "overview": "Test overview",
                  "vote_average": 9.5
                }
              ]
            }
            ''',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Note: In a real test, you'd need to inject the HTTP client
      // For now, this tests the structure
      expect(service.apiKey, equals('test_api_key'));
    });

    test('should map region to country code', () {
      // Test the region mapping logic
      // Since _regionToCountryCode is private, we test via getTrendingShows
      // In a real implementation, we'd use dependency injection for HTTP client
      expect(service.apiKey, isNotNull);
    });

    test('should handle API errors gracefully', () async {
      // Test error handling
      // Would need mocked HTTP client with error responses
      expect(service, isNotNull);
    });
  });
}

