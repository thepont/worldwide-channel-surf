import 'package:worldwide_channel_surf/models/typedefs.dart';

/// Model for TV show information from TMDb API
class ShowSummary {
  final int id;
  final String name;
  final String? posterUrl;
  final String? overview;
  final double? voteAverage;
  final String mediaType; // 'tv' or 'movie'

  const ShowSummary({
    required this.id,
    required this.name,
    this.posterUrl,
    this.overview,
    this.voteAverage,
    this.mediaType = 'tv',
  });

  /// Create from TMDb API JSON response
  factory ShowSummary.fromTmdbJson(Map<String, dynamic> json) {
    return ShowSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['title'] as String? ?? 'Unknown',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      mediaType: json['media_type'] as String? ?? 
                 (json['name'] != null ? 'tv' : 'movie'),
    );
  }
}

/// Model for watch providers (streaming services) from TMDb API
class WatchProvider {
  final String name;
  final String? logoUrl;
  final String deepLink; // The TMDb watch link (themoviedb.org/.../watch)
  final RegionId regionId;

  const WatchProvider({
    required this.name,
    this.logoUrl,
    required this.deepLink,
    required this.regionId,
  });

  /// Create from TMDb API JSON response
  factory WatchProvider.fromTmdbJson(
    Map<String, dynamic> json,
    RegionId regionId,
    int showId,
    String showType, // 'tv' or 'movie'
  ) {
    final providerName = json['provider_name'] as String? ?? 'Unknown';
    final logoPath = json['logo_path'] as String?;
    
    // Construct TMDb watch link
    final deepLink = 'https://www.themoviedb.org/$showType/$showId/watch';

    return WatchProvider(
      name: providerName,
      logoUrl: logoPath != null
          ? 'https://image.tmdb.org/t/p/w45$logoPath'
          : null,
      deepLink: deepLink,
      regionId: regionId,
    );
  }
}

