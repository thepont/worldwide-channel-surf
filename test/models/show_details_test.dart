import 'package:flutter_test/flutter_test.dart';
import 'package:worldwide_channel_surf/models/show_details.dart';

void main() {
  group('ShowSummary', () {
    test('should create from TMDb JSON (TV show)', () {
      final json = {
        'id': 1396,
        'name': 'Breaking Bad',
        'poster_path': '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
        'overview': 'A high school chemistry teacher turned methamphetamine producer.',
        'vote_average': 9.5,
        'media_type': 'tv',
      };

      final show = ShowSummary.fromTmdbJson(json);

      expect(show.id, equals(1396));
      expect(show.name, equals('Breaking Bad'));
      expect(show.posterUrl, equals('https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg'));
      expect(show.overview, isNotNull);
      expect(show.voteAverage, equals(9.5));
      expect(show.mediaType, equals('tv'));
    });

    test('should create from TMDb JSON (movie)', () {
      final json = {
        'id': 550,
        'title': 'Fight Club',
        'poster_path': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        'overview': 'An insomniac office worker...',
        'vote_average': 8.4,
        'media_type': 'movie',
      };

      final show = ShowSummary.fromTmdbJson(json);

      expect(show.id, equals(550));
      expect(show.name, equals('Fight Club'));
      expect(show.mediaType, equals('movie'));
    });

    test('should handle missing optional fields', () {
      final json = {
        'id': 123,
        'name': 'Test Show',
      };

      final show = ShowSummary.fromTmdbJson(json);

      expect(show.id, equals(123));
      expect(show.name, equals('Test Show'));
      expect(show.posterUrl, isNull);
      expect(show.overview, isNull);
      expect(show.voteAverage, isNull);
    });

    test('should handle null poster_path', () {
      final json = {
        'id': 456,
        'name': 'No Poster Show',
        'poster_path': null,
      };

      final show = ShowSummary.fromTmdbJson(json);

      expect(show.posterUrl, isNull);
    });
  });

  group('WatchProvider', () {
    test('should create from TMDb JSON', () {
      final json = {
        'provider_name': 'BBC iPlayer',
        'logo_path': '/5vUKe7iAkYcVn0oXKWxYhErkVxN.jpg',
      };

      final provider = WatchProvider.fromTmdbJson(
        json,
        'UK',
        1396,
        'tv',
      );

      expect(provider.name, equals('BBC iPlayer'));
      expect(provider.regionId, equals('UK'));
      expect(provider.deepLink, equals('https://www.themoviedb.org/tv/1396/watch'));
      expect(provider.logoUrl, equals('https://image.tmdb.org/t/p/w45/5vUKe7iAkYcVn0oXKWxYhErkVxN.jpg'));
    });

    test('should handle missing logo_path', () {
      final json = {
        'provider_name': 'Unknown Provider',
      };

      final provider = WatchProvider.fromTmdbJson(
        json,
        'US',
        550,
        'movie',
      );

      expect(provider.name, equals('Unknown Provider'));
      expect(provider.logoUrl, isNull);
      expect(provider.deepLink, equals('https://www.themoviedb.org/movie/550/watch'));
    });

    test('should create correct deep link for movies', () {
      final json = {'provider_name': 'Netflix'};
      final provider = WatchProvider.fromTmdbJson(json, 'US', 550, 'movie');
      expect(provider.deepLink, contains('/movie/'));
    });

    test('should create correct deep link for TV shows', () {
      final json = {'provider_name': 'Hulu'};
      final provider = WatchProvider.fromTmdbJson(json, 'US', 1396, 'tv');
      expect(provider.deepLink, contains('/tv/'));
    });
  });
}

