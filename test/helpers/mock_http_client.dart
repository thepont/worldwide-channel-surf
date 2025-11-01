import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Mock HTTP client factory for testing
class MockHttpClientFactory {
  /// Creates a mock client that returns successful TMDb responses
  static http.Client createTmdbSuccessClient() {
    return MockClient((request) async {
      if (request.url.path.contains('/trending/tv')) {
        return http.Response(
          '''
          {
            "results": [
              {
                "id": 1396,
                "name": "Breaking Bad",
                "poster_path": "/ggFHVNu6YYI5L9pCfOacjizRGt.jpg",
                "overview": "A high school chemistry teacher...",
                "vote_average": 9.5,
                "media_type": "tv"
              },
              {
                "id": 66732,
                "name": "Stranger Things",
                "poster_path": "/49WJfeN0moxb9IPfGn8AIqNTqTb.jpg",
                "overview": "When a young boy vanishes...",
                "vote_average": 8.7,
                "media_type": "tv"
              }
            ]
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.url.path.contains('/watch/providers')) {
        return http.Response(
          '''
          {
            "results": {
              "GB": {
                "flatrate": [
                  {
                    "provider_name": "BBC iPlayer",
                    "logo_path": "/5vUKe7iAkYcVn0oXKWxYhErkVxN.jpg"
                  }
                ]
              }
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('Not Found', 404);
    });
  }

  /// Creates a mock client that returns API errors
  static http.Client createErrorClient() {
    return MockClient((request) async {
      return http.Response('Unauthorized', 401);
    });
  }

  /// Creates a mock client that simulates network timeout
  static http.Client createTimeoutClient() {
    return MockClient((request) async {
      await Future.delayed(const Duration(seconds: 5));
      return http.Response('Timeout', 408);
    });
  }
}

